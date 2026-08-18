function keep = degeneracy_dropConstraints(A, tol)
%DEGENERACY_DROPCONSTRAINTS Select a maximal linearly independent row subset.
%   keep = adamnlopt.degeneracy_dropConstraints(A) returns the row indices of a
%   maximal linearly independent subset of the rows of A, so a rank-deficient
%   working set (redundant constraints that violate LICQ) can be reduced to a
%   full-rank one before a stabilized step is taken. Rows are selected greedily
%   by QR with column pivoting on A' (equivalently pivoting on the rows of A),
%   which keeps the best-conditioned representatives. TOL (optional) sets the
%   relative rank threshold on the R diagonal.
%
%   For A with rows [r1; r2] where r2 = 2*r1, keep = [1] (one representative).
%
%   Inputs:
%     A   - m-by-n matrix whose rows are the candidate constraints.
%     tol - (optional) relative rank threshold on the R diagonal; defaults to
%           1e-10.
%
%   Outputs:
%     keep - r-by-1 sorted indices of the retained (linearly independent) rows,
%            where r is the numerical rank of A. Empty when A is empty.
%
%   See also DEGENERACY_DETECTDEGENERACY, DEGENERACY_REGULARIZEDRECOVERY.

if nargin < 2 || isempty(tol)
    tol = 1e-10;
end

if isempty(A)
    keep = zeros(0,1);
    return;
end

% Column-pivoted QR of A' ranks the columns of A' (= rows of A) by importance.
[~, R, e] = qr(A.', 'vector');
dR = abs(diag(R));
if isempty(dR)
    keep = zeros(0,1);
    return;
end
r = sum(dR > tol * max(dR));
keep = sort(e(1:r));
keep = keep(:);
end
