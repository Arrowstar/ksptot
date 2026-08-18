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
groups = zeros(1, n);
% Column conflict: two columns conflict if they share any nonzero row.
% overlap(i,j) nonzero => columns i and j cannot share a color.
overlap = double(pattern') * double(pattern);   % n-by-n
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
end
