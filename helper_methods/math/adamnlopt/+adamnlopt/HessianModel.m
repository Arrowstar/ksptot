classdef (Abstract) HessianModel < handle
%HESSIANMODEL  Interface for secant Hessian models consumed by adamnlopt.solve.
%   A Hessian model accumulates curvature from constrained secant pairs
%       s = x_{k+1} - x_k,   y = gradL(x_{k+1}, lam) - gradL(x_k, lam)
%   and exposes the resulting approximation B both as a dense matrix (for the
%   direct KKT factorization) and as a matrix-vector product (for the Krylov
%   and trust-region-CG paths).
%
%   Implementations:
%     LBFGSHessian - limited memory; stores m recent pairs and rebuilds B from
%                    the Byrd-Nocedal-Schnabel compact representation on demand.
%     BFGSHessian  - full memory; maintains a dense B by the rank-2 BFGS update.
%
%   Declaring the interface abstractly, rather than duck-typing with ismethod,
%   gives the solver a single positive test -- isa(H, 'adamnlopt.HessianModel')
%   -- at the two places that must distinguish a model from a plain matrix
%   (hessianVecProduct and kkt_KKTOperator). Those sites previously keyed on the
%   concrete class name or on isnumeric, so a newly added model silently took
%   the wrong branch; the base class closes that hole for future models too.
%
%   Methods (abstract):
%     reset     - discard all accumulated curvature.
%     update    - add a secant pair (s, y); returns whether it was stored.
%     getMatrix - dense n-by-n symmetric positive-definite approximation.
%     apply     - product B*v.
%     diagonal  - diag(B), or [] when no cheap diagonal is available.
%
%   See also LBFGSHESSIAN, BFGSHESSIAN, HESSIANVECPRODUCT, KKT_KKTOPERATOR.

    methods (Abstract)
        %RESET  Discard accumulated curvature and return to the initial model.
        reset(obj)

        %UPDATE  Add a curvature pair (s, y).
        %   accepted = update(obj, s, y) returns true when the (possibly
        %   damped) pair was incorporated, false when it was rejected as
        %   degenerate or of insufficient curvature.
        accepted = update(obj, s, y)

        %GETMATRIX  Dense n-by-n symmetric positive-definite approximation B.
        B = getMatrix(obj)

        %APPLY  Hessian-vector product B*v.
        Bv = apply(obj, v)

        %DIAGONAL  diag(B) when cheaply available, otherwise [].
        %   An empty return tells kkt_KKTOperator that no Jacobi diagonal can be
        %   supplied, and linalg_preconditioner then falls back to the identity.
        d = diagonal(obj)
    end
end
