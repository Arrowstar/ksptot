function [g, J] = parallel_parallelFiniteDiff(objFun, conFun, x, f0, c0, h, type, pattern, lb, ub)
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
%     g - n-by-1 objective gradient, or [] when objFun is empty.
%     J - m-by-n constraint Jacobian, or [] when conFun/c0 is empty.
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
    taskCols = {};  taskStep = [];  taskCen = [];
    for c = 1:nC
        cols = find(groups == c);  cols = cols(:)';
        hg = h * max(1, max(abs(x(cols))));
        [hs, sgn, twoSided] = adamnlopt.fdBoundedStep(x(cols), hg, subsetBound(lb, cols), subsetBound(ub, cols));
        full_ = (hs == hg);
        batches = { cols(full_ & sgn > 0 &  twoSided & central), +hg, true;  ...
                    cols(full_ & sgn > 0 & ~(twoSided & central)), +hg, false; ...
                    cols(full_ & sgn < 0),                         -hg, false };
        for k = 1:size(batches, 1)
            if isempty(batches{k,1}), continue; end
            taskCols{end+1} = batches{k,1};   %#ok<AGROW>
            taskStep(end+1) = batches{k,2};   %#ok<AGROW>
            taskCen(end+1)  = batches{k,3};   %#ok<AGROW>
        end
        % Columns with no room for the full group step get their own shrunk task
        % rather than dragging the whole group's step down with them.
        for t = find(~full_ & hs > 0)'
            taskCols{end+1} = cols(t);                          %#ok<AGROW>
            taskStep(end+1) = sgn(t) * hs(t);                   %#ok<AGROW>
            taskCen(end+1)  = central && twoSided(t);           %#ok<AGROW>
        end
        % hs == 0 columns are fixed variables (lb == ub) and keep a zero column.
    end

    nT   = numel(taskCols);
    dpos = zeros(m, nT);
    dneg = zeros(m, nT);
    if useParfor
        parfor t = 1:nT
            cols = taskCols{t};  d = taskStep(t);
            xp = x;  xp(cols) = xp(cols) + d;
            dpos(:, t) = conFun(xp);
            if taskCen(t)
                xm = x;  xm(cols) = xm(cols) - d;
                dneg(:, t) = conFun(xm);
            end
        end
    else
        for t = 1:nT
            cols = taskCols{t};  d = taskStep(t);
            xp = x;  xp(cols) = xp(cols) + d;
            dpos(:, t) = conFun(xp);
            if taskCen(t)
                xm = x;  xm(cols) = xm(cols) - d;
                dneg(:, t) = conFun(xm);
            end
        end
    end
    for t = 1:nT
        d = taskStep(t);
        if taskCen(t)
            dh = (dpos(:, t) - dneg(:, t)) / (2 * d);
        else
            dh = (dpos(:, t) - c0v) / d;
        end
        for j = taskCols{t}(:)'
            rows = pat(:, j);
            J(rows, j) = dh(rows);
        end
    end
    g = [];
    return;
end

% Per-coordinate signed steps for the dense paths.
[hs, sgn, twoSided] = adamnlopt.fdBoundedStep(x, h * max(1, abs(x)), lb, ub);
d2 = sgn .* hs;                 % signed step; 0 for a fixed variable
cen = central & twoSided;       % per-coordinate central availability

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
%PARALLEL_AVAILABLE  Test whether the Parallel Computing Toolbox is installed.
%   v = parallel_available() returns true when ver('parallel') is non-empty,
%   used to decide between the parfor path and the sequential fallback.
%
%   Inputs:
%     (none)
%
%   Outputs:
%     v - logical; true if the Parallel Computing Toolbox is available.
v = ~isempty(ver('parallel'));
end
