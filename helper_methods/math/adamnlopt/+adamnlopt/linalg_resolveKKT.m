function d = linalg_resolveKKT(factors, rhs)
%LINALG_RESOLVEKKT  Re-solve a factored KKT system with a new right-hand side.
%   d = adamnlopt.linalg_resolveKKT(factors, rhs) uses the LDL' factorization
%   that LINALG_SOLVEKKTDIRECT returned in info.factors (fields L, D, p, A) to
%   solve A*d = rhs without re-factoring.  Used by the second-order correction, whose re-solves change
%   only the right-hand side (AdamNlOpt_Review_Report A9 / D17.1).
%
%   Inputs:
%     factors - struct with L, D (block-diagonal) and p (permutation vector).
%     rhs     - right-hand side, numel(p)-by-1.
%
%   Outputs:
%     d - solution, same size as rhs.
%
%   See also LINALG_SOLVEKKTDIRECT, KKT_INERTIACORRECTION.
L = factors.L;  D = factors.D;  p = factors.p;
ws1 = warning('off', 'MATLAB:nearlySingularMatrix');
ws2 = warning('off', 'MATLAB:singularMatrix');
cleanup = onCleanup(@() warning([ws1, ws2])); %#ok<NASGU>
d = zeros(size(rhs));
d(p) = L.' \ (D \ (L \ rhs(p)));
end
