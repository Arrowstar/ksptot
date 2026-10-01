function J = finiteDiffJacobian(h, x, base, hstep, type, pattern, lb, ub)
%FINITEDIFFJACOBIAN  Finite-difference Jacobian of a vector function.
%   J = adamnlopt.finiteDiffJacobian(h, x, base, hstep, type, pattern)
%   approximates the m-by-n Jacobian of h: R^n -> R^m at x. base = h(x) (for
%   forward diff). type is 'forward' or 'central'. Steps are scaled by
%   max(1,|x_j|). If a sparsity pattern (m-by-n) is given, graph coloring
%   (via SPARSITYCOLORING) groups structurally independent columns so several
%   variables are perturbed per evaluation, cutting the number of h evaluations
%   from n to the number of colors; only the rows in each column's support are
%   read back from each grouped difference.
%
%   J = adamnlopt.finiteDiffJacobian(h, x, base, hstep, type, pattern, lb, ub)
%   additionally keeps every probe point inside [lb, ub] via FDBOUNDEDSTEP.
%
%   In the colored path a group whose columns need different directions is SPLIT
%   BY DIRECTION into a forward batch and a backward batch, each still one
%   evaluation. That is deliberate: shrinking the group step to whatever its
%   tightest member allows would degrade every column in the group (up to 16 of
%   them on the orbit problem) for the sake of the one column near a bound.
%   Splitting keeps every column at full step, and it stays exact because the
%   columns of a color group have disjoint row supports, so any subset of them
%   does too. A column with room on neither side is differenced on its own with
%   a shrunk step, and a fixed variable (lb == ub) yields a zero column.
%   Omitting lb/ub (or passing empty) restores the unbounded behaviour exactly,
%   which is how opts.HonorBounds = false works.
%
%   Inputs:
%     h       - function handle @(x) returning an m-by-1 vector.
%     x       - n-by-1 point at which the Jacobian is approximated.
%     base    - m-by-1 value h(x); base value for forward differences
%               (and for any column that degrades to one-sided).
%     hstep   - base finite-difference step size (scaled per coordinate/group).
%     type    - 'forward' or 'central' difference scheme.
%     pattern - (optional) m-by-n logical sparsity pattern of the Jacobian.
%               Empty or omitted means dense column-by-column differencing.
%     lb, ub  - (optional) n-by-1 bounds; empty or omitted for none.
%
%   Outputs:
%     J - m-by-n finite-difference approximation of the Jacobian of h at x.
%
%   See also FINITEDIFFGRADIENT, FDBOUNDEDSTEP, SPARSITYCOLORING, EVALUATOR.

import adamnlopt.*
if nargin < 6, pattern = []; end
if nargin < 7, lb = []; end
if nargin < 8, ub = []; end

n = numel(x);
m = numel(base);
central = strcmp(type, 'central');
J = zeros(m, n);

if isempty(pattern)
    hWant = hstep * max(1, abs(x(:)));
    [hs, sgn, twoSided] = fdBoundedStep(x, hWant, lb, ub);
    for j = 1:n
        if hs(j) == 0, continue; end     % fixed variable: zero column
        d = sgn(j) * hs(j);
        xp = x;  xp(j) = xp(j) + d;
        if central && twoSided(j)
            xm = x;  xm(j) = xm(j) - d;
            J(:, j) = (h(xp) - h(xm)) / (2*d);
        else
            J(:, j) = (h(xp) - base) / d;
        end
    end
    return;
end

% Sparse, colored differencing.
pattern = logical(pattern);
groups = sparsityColoring(pattern);
nColors = max(groups);
for c = 1:nColors
    cols = find(groups == c);
    cols = cols(:)';
    % PER-COLUMN step, not one magnitude for the whole color.  The step used to
    % be hstep*max(1, max|x| over the group) -- the largest variable in the
    % color set the step for all of them -- so a variable of size 1e-6 sharing a
    % color with one of size 1e6 was perturbed by 1e12 times its own scale and
    % its column of the Jacobian was meaningless.  Which variables share a color
    % is decided by the SPARSITY PATTERN, so turning on JacobPattern, a purely
    % computational option, silently destroyed accuracy that the dense path got
    % right.  The columns in a color have disjoint row supports by construction,
    % so each can carry its own step and be divided by its own step in the same
    % evaluation: identical cost, correct relative step everywhere.
    hcol = hstep * max(1, abs(x(cols(:))));
    [hs, sgn, twoSided] = fdBoundedStep(x(cols), hcol, lb2(lb, cols), lb2(ub, cols));

    full_ = (hs(:) == hcol(:));          % columns that keep their full step
    sel = { full_ & sgn(:) > 0 &  twoSided(:) & central, ...
            full_ & sgn(:) > 0 & ~(twoSided(:) & central), ...
            full_ & sgn(:) < 0 };
    batchSgn  = [ +1, +1, -1 ];
    batchCen  = [ true, false, false ];  % backward columns are never two-sided
    for k = 1:3
        idx = sel{k};
        if ~any(idx), continue; end
        J = applyBatch(J, h, x, base, pattern, cols(idx), ...
                       batchSgn(k) * hcol(idx), batchCen(k));
    end

    % Columns that had to shrink (no room for their step on either side) are
    % differenced individually: their bound-limited step is no longer the one
    % the rest of the batch was perturbed by.
    odd = find(~full_ & hs(:) > 0);
    for t = odd(:)'
        j = cols(t);
        J = applyBatch(J, h, x, base, pattern, j, sgn(t)*hs(t), central && twoSided(t));
    end
    % hs == 0 columns are fixed variables and keep their zero column.
end
end

% ------------------------------------------------------------------------
function J = applyBatch(J, h, x, base, pattern, cols, d, central)
%APPLYBATCH  Difference one batch of structurally independent columns.
%   Perturbs every column in COLS by its own signed step D(k) at once and
%   scatters the result into the rows each column actually touches. COLS must
%   have pairwise disjoint row supports (guaranteed by the coloring) for this to
%   be exact. D is scalar or one entry per column; because the supports are
%   disjoint, each column's rows are divided by that column's own step, which is
%   what lets one evaluation carry a different step per variable.
cols = cols(:)';
d    = d(:);
if isscalar(d), d = repmat(d, numel(cols), 1); end
dShaped = reshape(d, size(x(cols)));     % x may be a row or a column
xp = x;  xp(cols) = xp(cols) + dShaped;
if central
    xm = x;  xm(cols) = xm(cols) - dShaped;
    dnum = h(xp) - h(xm);
    den  = 2 * d;
else
    dnum = h(xp) - base;
    den  = d;
end
for k = 1:numel(cols)
    j = cols(k);
    rows = pattern(:, j);
    J(rows, j) = dnum(rows) / den(k);
end
end

% ------------------------------------------------------------------------
function v = lb2(v, cols)
%LB2  Subset a bound vector by column indices, tolerating an empty bound.
if ~isempty(v), v = v(cols); end
end
