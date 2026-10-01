function [g, J, info] = parallel_parallelFiniteDiff(objFun, conFun, x, f0, c0, h, type, pattern, lb, ub)
%PARALLEL_PARALLELFINITEDIFF Parallel finite-difference gradient and Jacobian.
%   [g, J] = adamnlopt.parallel_parallelFiniteDiff(objFun, conFun, x, f0, c0,
%   h, type) computes the gradient g = grad(objFun) and Jacobian J =
%   d(conFun)/dx at x using parfor when the Parallel Computing Toolbox is
%   available, and falls back to a sequential loop otherwise.
%
%   [g, J] = adamnlopt.parallel_parallelFiniteDiff(..., type, pattern) takes an
%   optional m-by-n logical sparsity PATTERN of the Jacobian. When supplied for
%   a Jacobian-only call (objFun == []), structurally independent columns are
%   graph-colored (see SPARSITYCOLORING) and each color group is perturbed as a
%   single parfor task, cutting the number of conFun evaluations from n to the
%   number of colors while remaining EXACT.  This is the same compression the
%   serial FINITEDIFFJACOBIAN does, now on the parallel path.  The pattern is
%   ignored for gradient (objFun) work, which has no exploitable sparsity.
%
%   [g, J] = adamnlopt.parallel_parallelFiniteDiff(..., pattern, lb, ub) keeps
%   every probe point inside [lb, ub] via FDBOUNDEDSTEP, exactly as the serial
%   FINITEDIFFGRADIENT / FINITEDIFFJACOBIAN do: a coordinate whose forward step
%   would leave the box flips to a backward difference, a color group needing
%   both directions splits into a forward batch and a backward batch (each still
%   one evaluation, still exact because a group's columns have disjoint row
%   supports), and only a coordinate with room on neither side has its step
%   shrunk.  Omitting lb/ub (or passing empty) restores the unbounded behaviour
%   exactly, which is how opts.HonorBounds = false works.
%
%   objFun is @(x) scalar (or [] to skip gradient).
%   conFun is @(x) m-vector (or [] to skip Jacobian).
%   f0 = objFun(x), c0 = conFun(x) (pre-evaluated base values).
%   h is the FD step size (scalar). type is 'forward' or 'central'.
%
%   The output g is n-by-1; J is m-by-n. Pass [] for objFun or conFun to
%   skip that output (returns []). Each coordinate uses a relative step
%   hh = h*max(1, abs(x(i))); 'forward' differences reuse the base values f0/c0
%   while 'central' differences evaluate both x+hh*ei and x-hh*ei.
%
%   Inputs:
%     objFun  - @(x) scalar objective, or [] to skip the gradient.
%     conFun  - @(x) m-vector constraint function, or [] to skip the Jacobian.
%     x       - n-by-1 point at which derivatives are computed.
%     f0      - objFun(x), the pre-evaluated base objective value.
%     c0      - conFun(x), the pre-evaluated base constraint vector.
%     h       - scalar finite-difference step size (scaled per coordinate).
%     type    - 'forward' or 'central' difference scheme.
%     pattern - (optional) m-by-n logical Jacobian sparsity pattern.
%     lb, ub  - (optional) n-by-1 bounds; empty or omitted for none.
%
%   Outputs:
%     g    - n-by-1 objective gradient, or [] when objFun is empty.
%     J    - m-by-n constraint Jacobian, or [] when conFun/c0 is empty.
%     info - struct counting the user-function calls actually made:
%              nObjEvals - objFun calls (0 when objFun is empty),
%              nConEvals - conFun calls (0 when the Jacobian is skipped),
%              remote    - true when they ran on parfor WORKERS.
%            The counts are exact, not n or 2n: bound handling fixes, shrinks
%            and one-sides individual coordinates, and the colored path
%            compresses n columns into a handful of groups. remote matters
%            because a counter living on a handle object passed into the parfor
%            body is incremented on a WORKER COPY and never comes back, so a
%            self-counting function handle loses every probe on that path; the
%            caller must add nConEvals/nObjEvals itself exactly when remote is
%            true, and must NOT when it is false or it will double-count.
%
%   See also FDBOUNDEDSTEP, PARALLEL_BATCHEVALUATE, PARALLEL_ASYNCEVALUATOR.

if nargin < 8, pattern = []; end
if nargin < 9,  lb = []; end
if nargin < 10, ub = []; end
n = numel(x);
x = x(:);
central = strcmp(type, 'central');

if ~isempty(objFun)
    g = zeros(n, 1);
else
    g = [];
end
if ~isempty(conFun) && ~isempty(c0)
    m = numel(c0);
    J = zeros(m, n);
else
    J = [];
end

useParfor = parallel_available();
info = struct('nObjEvals', 0, 'nConEvals', 0, 'remote', useParfor);

% --- Colored (sparse) Jacobian path ------------------------------------------
% Only for a Jacobian-only call: the gradient has no exploitable sparsity, so a
% mixed objFun+pattern call falls through to the dense path below.
if ~isempty(J) && ~isempty(pattern) && isempty(objFun)
    pat    = logical(pattern);
    groups = adamnlopt.sparsityColoring(pat);
    nC     = max(groups);
    c0v    = c0(:);

    % Build the evaluation tasks up front so the parfor stays flat: one task is
    % one perturbation direction over a set of columns.  Without bounds this is
    % one task per color, as before; with bounds a color that needs both
    % directions becomes two tasks and a cornered column becomes its own.
    % taskStep holds one step PER COLUMN, not one per task.  It used to be the
    % scalar h*max(1, max|x| over the color): the largest variable in a color
    % set the perturbation for every variable sharing it, so a 1e-6 variable
    % colored with a 1e6 one was moved by 1e12 times its own scale.  Which
    % variables share a color is decided by the sparsity pattern, so enabling
    % JacobPattern -- a performance option -- silently wrecked those columns.
    % The columns in a color have disjoint row supports, so one evaluation can
    % carry a different step for each and each column is divided by its own.
    taskCols = {};  taskStep = {};  taskCen = [];
    for c = 1:nC
        cols = find(groups == c);  cols = cols(:)';
        hcol = h * max(1, abs(x(cols(:))));
        [hs, sgn, twoSided] = adamnlopt.fdBoundedStep(x(cols), hcol, subsetBound(lb, cols), subsetBound(ub, cols));
        full_ = (hs(:) == hcol(:));
        batches = { full_ & sgn(:) > 0 &  twoSided(:) & central, +1, true;  ...
                    full_ & sgn(:) > 0 & ~(twoSided(:) & central), +1, false; ...
                    full_ & sgn(:) < 0,                           -1, false };
        for k = 1:size(batches, 1)
            idx = batches{k,1};
            if ~any(idx), continue; end
            taskCols{end+1} = cols(idx);                        %#ok<AGROW>
            taskStep{end+1} = batches{k,2} * hcol(idx);         %#ok<AGROW>
            taskCen(end+1)  = batches{k,3};                     %#ok<AGROW>
        end
        % Columns with no room for their full step get their own shrunk task
        % rather than dragging the rest of the batch down with them.
        for t = find(~full_ & hs(:) > 0)'
            taskCols{end+1} = cols(t);                          %#ok<AGROW>
            taskStep{end+1} = sgn(t) * hs(t);                   %#ok<AGROW>
            taskCen(end+1)  = central && twoSided(t);           %#ok<AGROW>
        end
        % hs == 0 columns are fixed variables (lb == ub) and keep a zero column.
    end

    nT   = numel(taskCols);
    info.nConEvals = nT + nnz(taskCen);   % one call per task, two if central
    dpos = zeros(m, nT);
    dneg = zeros(m, nT);
    if useParfor
        parfor t = 1:nT
            cols = taskCols{t};  d = reshape(taskStep{t}, size(x(cols)));
            xp = x;  xp(cols) = xp(cols) + d;
            dpos(:, t) = conFun(xp);
            if taskCen(t)
                xm = x;  xm(cols) = xm(cols) - d;
                dneg(:, t) = conFun(xm);
            end
        end
    else
        for t = 1:nT
            cols = taskCols{t};  d = reshape(taskStep{t}, size(x(cols)));
            xp = x;  xp(cols) = xp(cols) + d;
            dpos(:, t) = conFun(xp);
            if taskCen(t)
                xm = x;  xm(cols) = xm(cols) - d;
                dneg(:, t) = conFun(xm);
            end
        end
    end
    for t = 1:nT
        d = taskStep{t}(:);
        colsT = taskCols{t}(:)';
        if taskCen(t)
            dnum = dpos(:, t) - dneg(:, t);  den = 2 * d;
        else
            dnum = dpos(:, t) - c0v;         den = d;
        end
        % Each column divides by its OWN step; the disjoint row supports are
        % what make that exact within a single shared evaluation.
        for k = 1:numel(colsT)
            j = colsT(k);
            rows = pat(:, j);
            J(rows, j) = dnum(rows) / den(k);
        end
    end
    g = [];
    return;
end

% Per-coordinate signed steps for the dense paths.
[hs, sgn, twoSided] = adamnlopt.fdBoundedStep(x, h * max(1, abs(x)), lb, ub);
d2 = sgn .* hs;                 % signed step; 0 for a fixed variable
cen = central & twoSided;       % per-coordinate central availability

% Exact per-function call count for the dense paths: one call per moving
% coordinate, plus a second for every coordinate that gets a central difference.
% Fixed variables (d2 == 0) are skipped by every branch below and cost nothing.
nCalls = nnz(d2 ~= 0) + nnz(cen & (d2 ~= 0));
if ~isempty(objFun),            info.nObjEvals = nCalls; end
if ~isempty(conFun) && ~isempty(c0), info.nConEvals = nCalls; end

if useParfor
    % Perturbed function values: one column per direction.
    fp  = zeros(1, n);    % f(x+d_i*ei)
    fm  = zeros(1, n);    % f(x-d_i*ei)  (central only)
    cp  = zeros(max(1, numel(c0)), n);
    cm  = zeros(max(1, numel(c0)), n);

    parfor i = 1:n
        di = d2(i);
        if di == 0, continue; end        % fixed variable: leave the zeros
        xp = x;  xp(i) = xp(i) + di;
        if ~isempty(objFun), fp(i) = objFun(xp); end
        if ~isempty(conFun) && ~isempty(c0), cp(:,i) = conFun(xp); end
        if cen(i)
            xm = x;  xm(i) = xm(i) - di;
            if ~isempty(objFun), fm(i) = objFun(xm); end
            if ~isempty(conFun) && ~isempty(c0), cm(:,i) = conFun(xm); end
        end
    end

    for i = 1:n
        di = d2(i);
        if di == 0, continue; end
        if cen(i)
            if ~isempty(g), g(i) = (fp(i) - fm(i)) / (2 * di); end
            if ~isempty(J), J(:,i) = (cp(:,i) - cm(:,i)) / (2 * di); end
        else
            if ~isempty(g), g(i) = (fp(i) - f0) / di; end
            if ~isempty(J), J(:,i) = (cp(:,i) - c0(:)) / di; end
        end
    end
else
    % Sequential fallback.  Each function is called only if its output is
    % wanted: the forward branch used to call objFun unconditionally, so a
    % Jacobian-only call with no pattern died on [](xp) before reaching conFun.
    for i = 1:n
        di = d2(i);
        if di == 0, continue; end
        xp = x;  xp(i) = xp(i) + di;
        if cen(i)
            xm = x;  xm(i) = xm(i) - di;
            if ~isempty(g), g(i) = (objFun(xp) - objFun(xm)) / (2*di); end
            if ~isempty(J), J(:,i) = (conFun(xp) - conFun(xm)) / (2*di); end
        else
            if ~isempty(g), g(i) = (objFun(xp) - f0) / di; end
            if ~isempty(J), J(:,i) = (conFun(xp) - c0(:)) / di; end
        end
    end
end
end

function v = subsetBound(v, cols)
%SUBSETBOUND  Subset a bound vector by column indices, tolerating an empty bound.
if ~isempty(v), v = v(cols); end
end

function v = parallel_available()
%PARALLEL_AVAILABLE  Test whether the Parallel Computing Toolbox is usable.
%   v = parallel_available() decides between the parfor path and the
%   sequential fallback. The answer is cached for the session.
%
%   ver('parallel') scans the toolbox path, and this was called once per
%   Jacobian -- i.e. once per solver iteration -- for an answer that cannot
%   change inside a MATLAB session. It also answers the wrong question:
%   ver reports INSTALLED, and on a shared license server the toolbox sits on
%   disk while parfor degrades to serial with a license error. license('test')
%   is the question the caller is actually asking. Both are now asked once.
%
%   The cache means a license checked out after the first call in a session is
%   not picked up; clear the function to re-probe.
%
%   Inputs:
%     (none)
%
%   Outputs:
%     v - logical; true if the Parallel Computing Toolbox is available.
persistent avail
if isempty(avail)
    avail = ~isempty(ver('parallel')) && ...
            license('test', 'Distrib_Computing_Toolbox') == 1;
end
v = avail;
end
