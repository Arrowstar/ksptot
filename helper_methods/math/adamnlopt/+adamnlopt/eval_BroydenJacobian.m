classdef eval_BroydenJacobian < handle
%EVAL_BROYDENJACOBIAN  Rank-1 secant (Broyden) update for constraint Jacobians.
%   B = adamnlopt.eval_BroydenJacobian(J0) initialises from the exact Jacobian
%   J0 (mxn). Call B.update(s, y, xRef) after each step where s=dx, y=dc and
%   xRef is the point s was taken from, to advance the secant approximation:
%
%       J_new = J_old + (y - J_old*s) * s' / (s'*s)
%
%   The approximation is refreshed (staleness=0) when the Broyden residual
%   relative to the secant pair's own scale exceeds opts.broydenTol, or when
%   staleness exceeds opts.broydenMaxStale. Call B.needsRefresh() to query,
%   then reset with B.setExact(J) after recomputing the exact Jacobian.
%
%   B.apply(v) returns J*v (forward product). B.applyT(v) returns J'*v.
%
%   Properties:
%     J_        - (private) current dense m-by-n Jacobian approximation.
%     stale_    - (private) steps since the last exact refresh.
%     maxStale_ - (private) staleness at which a refresh is forced.
%     tol_      - (private) relative Broyden-residual threshold for refresh.
%     m         - (read-only) number of rows (constraints).
%     n         - (read-only) number of columns (variables).
%
%   Methods:
%     eval_BroydenJacobian - construct from an exact Jacobian and options.
%     update               - apply a rank-1 secant update (or flag refresh).
%     apply                - forward product J*s.
%     applyT               - transposed product J'*u.
%     full                 - return the current dense Jacobian.
%     needsRefresh         - test whether an exact refresh is due.
%     setExact             - replace with an exact Jacobian and clear staleness.
%
%   See also EVALUATOR, EVAL_COSTMODEL.

    properties (Access = private)
        J_          % current Jacobian approximation (dense m x n)
        stale_      = 0
        maxStale_   = 20
        tol_        = 0.1
    end

    properties (SetAccess = private)
        m = 0
        n = 0
    end

    methods
        function obj = eval_BroydenJacobian(J0, maxStale, tol)
        %EVAL_BROYDENJACOBIAN  Construct a Broyden Jacobian approximation.
        %   obj = eval_BroydenJacobian(J0) initialises from the exact Jacobian
        %   J0. obj = eval_BroydenJacobian(J0, maxStale, tol) also sets the
        %   staleness limit and residual tolerance.
        %
        %   Inputs:
        %     obj      - (constructor output).
        %     J0       - m-by-n exact Jacobian (dense or sparse; stored dense).
        %     maxStale - (optional) steps before a refresh is forced; default 20.
        %     tol      - (optional) relative residual refresh threshold; default 0.1.
        %
        %   Outputs:
        %     obj - the constructed eval_BroydenJacobian handle object.
            obj.J_ = full(J0);
            [obj.m, obj.n] = size(J0);
            if nargin >= 2 && ~isempty(maxStale), obj.maxStale_ = maxStale; end
            if nargin >= 3 && ~isempty(tol),      obj.tol_      = tol;      end
        end

        function accepted = update(obj, s, y, xRef)
        %UPDATE  Apply a rank-1 secant (Broyden) update to the Jacobian.
        %   accepted = update(obj, s, y) advances the approximation by
        %   J = J + (y - J*s)*s'/(s'*s) and increments the staleness counter.
        %   A negligible step s is skipped (staleness still increments). If the
        %   relative residual ||y - J*s|| against the pair's own scale
        %   max(||y||, ||J*s||) exceeds tol_, no update is applied and
        %   staleness is forced to maxStale_ to trigger a refresh on the next
        %   needsRefresh query.  Scaling by the constraint VALUE (as before)
        %   pinned the denominator at 1 near feasibility, so the test went
        %   absolute on a vanishing ||y - Js|| and a 100%-wrong model passed;
        %   on O(1e6) constraints it admitted 1e5 absolute errors.
        %
        %   accepted reports whether the Jacobian actually changed, so the
        %   caller knows whether its secant anchor advanced.
        %
        %   update(obj, s, y, xRef) supplies the point the step was taken
        %   from, which sets the scale the "negligible step" test is relative
        %   to.  That test used to read
        %
        %       ss2 < eps*norm(ss)^2 + eps
        %
        %   which is tautological -- norm(ss)^2 IS ss2 -- so the intended
        %   relative guard collapsed to the absolute threshold ||s|| < ~1.5e-8.
        %   On a problem whose variables are O(1e6) that accepted steps eleven
        %   orders of magnitude below the variable scale, dividing by an
        %   effectively zero ss2; on one whose variables are O(1e-6) it rejected
        %   every legitimate step. The test is now ||s|| <= eps^(1/2)*max(1,||xRef||),
        %   the same relative convention the finite-difference steps use.
        %
        %   Inputs:
        %     obj  - the eval_BroydenJacobian handle object.
        %     s    - n-by-1 step dx = x+ - x.
        %     y    - m-by-1 constraint change dc = c(x+) - c(x).
        %     xRef - (optional) n-by-1 point s was taken from; sets the scale of
        %            the negligible-step test. Defaults to 0 (absolute test).
        %
        %   Outputs:
        %     accepted - logical; true when the Jacobian was updated, false when
        %                the step was negligible or the residual forced a refresh.
            % s: n-vector (dx), y: m-vector (dc = c(x+)-c(x)).
            if nargin < 4, xRef = 0; end
            ss = s(:);  yy = y(:);
            ss2 = ss.' * ss;
            sMin = sqrt(eps) * max(1, norm(xRef(:), inf));
            if ~(ss2 > sMin^2)
                obj.stale_ = obj.stale_ + 1;
                accepted = false;
                return;
            end
            res = yy - obj.J_ * ss;
            resRel = norm(res) / max([norm(yy), norm(obj.J_ * ss), realmin]);
            if resRel > obj.tol_
                % Residual too large: flag for refresh instead of updating.
                obj.stale_ = obj.maxStale_;   % forces needsRefresh=true
                accepted = false;
                return;
            end
            obj.J_ = obj.J_ + (res * ss.') / ss2;
            obj.stale_ = obj.stale_ + 1;
            accepted = true;
        end

        function v = apply(obj, s)
        %APPLY  Forward Jacobian-vector product J*s.
        %   v = apply(obj, s) returns the product of the current Jacobian
        %   approximation with the column vector s.
        %
        %   Inputs:
        %     obj - the eval_BroydenJacobian handle object.
        %     s   - n-by-1 vector (reshaped to a column).
        %
        %   Outputs:
        %     v - m-by-1 product J*s.
            v = obj.J_ * s(:);
        end

        function v = applyT(obj, u)
        %APPLYT  Transposed Jacobian-vector product J'*u.
        %   v = applyT(obj, u) returns the product of the transposed Jacobian
        %   approximation with the column vector u.
        %
        %   Inputs:
        %     obj - the eval_BroydenJacobian handle object.
        %     u   - m-by-1 vector (reshaped to a column).
        %
        %   Outputs:
        %     v - n-by-1 product J'*u.
            v = obj.J_.' * u(:);
        end

        function J = full(obj)
        %FULL  Return the current dense Jacobian approximation.
        %   J = full(obj) returns the stored m-by-n Jacobian matrix.
        %
        %   Inputs:
        %     obj - the eval_BroydenJacobian handle object.
        %
        %   Outputs:
        %     J - m-by-n current Jacobian approximation.
            J = obj.J_;
        end

        function v = needsRefresh(obj)
        %NEEDSREFRESH  Test whether an exact Jacobian refresh is due.
        %   v = needsRefresh(obj) returns true when the staleness counter has
        %   reached the maxStale_ limit (also set when a large residual forces a
        %   refresh in update).
        %
        %   Inputs:
        %     obj - the eval_BroydenJacobian handle object.
        %
        %   Outputs:
        %     v - logical; true if a refresh via setExact is required.
            v = obj.stale_ >= obj.maxStale_;
        end

        function setExact(obj, J)
        %SETEXACT  Replace the approximation with an exact Jacobian.
        %   setExact(obj, J) stores the freshly computed exact Jacobian and
        %   resets the staleness counter to zero.
        %
        %   Inputs:
        %     obj - the eval_BroydenJacobian handle object.
        %     J   - m-by-n exact Jacobian (dense or sparse; stored dense).
        %
        %   Outputs:
        %     (none) obj is modified in place.
            obj.J_    = full(J);
            obj.stale_ = 0;
        end
    end
end
