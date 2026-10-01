function groups = sparsityColoring(pattern)
%SPARSITYCOLORING  Greedy column coloring of a Jacobian sparsity pattern.
%   groups = adamnlopt.sparsityColoring(pattern) assigns each column of the
%   m-by-n logical PATTERN a color (positive integer) so that columns sharing a
%   color have disjoint row supports. Structurally independent columns can
%   then be differenced simultaneously. Column conflicts are detected from the
%   overlap matrix pattern'*pattern (nonzero (i,j) means columns i and j share a
%   nonzero row); each column is greedily assigned the lowest color not used by
%   an already-colored conflicting column, allocating a new color when needed.
%
%   Inputs:
%     pattern - m-by-n logical (or numeric) sparsity pattern of the Jacobian.
%
%   Outputs:
%     groups - 1-by-n vector of positive-integer color labels, one per column.
%
%   See also FINITEDIFFJACOBIAN.

pattern = logical(pattern);
n = size(pattern, 2);

% The coloring is a PURE function of the pattern, and the pattern is fixed for
% the whole solve -- yet this was recomputed from scratch on every Jacobian
% evaluation, i.e. once per iteration, for an answer that never changed.  One
% content-keyed slot is enough: callers alternate between at most a couple of
% patterns (objective Hessian, constraint Jacobian) and the isequal probe is
% O(m*n) against the O(n^2)+ coloring it skips.
persistent lastPattern lastGroups
if ~isempty(lastPattern) && isequal(lastPattern, pattern)
    groups = lastGroups;
    return;
end

groups = zeros(1, n);
% Column conflict: two columns conflict if they share any nonzero row.
% overlap(i,j) nonzero => columns i and j cannot share a color.
%
% Built in SPARSE arithmetic: double(pattern')*double(pattern) densifies to a
% full n-by-n product, which on the problems this path exists for (large n, few
% nonzeros per column) is both the dominant cost here and a quadratic memory
% spike.  A pattern dense enough for the sparse product to lose is one where
% the coloring degenerates to n colors and the whole path buys nothing anyway.
sp = sparse(double(pattern));
overlap = sp.' * sp;   % n-by-n, sparse
for j = 1:n
    used = false(1, n);
    conflicts = find(overlap(j, :) > 0);
    for k = conflicts
        if k ~= j && groups(k) > 0
            used(groups(k)) = true;
        end
    end
    c = find(~used, 1);
    if isempty(c), c = max(groups) + 1; end
    groups(j) = c;
end

lastPattern = pattern;
lastGroups  = groups;
end
