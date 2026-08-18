classdef eval_BroydenJacobian < handle
%EVAL_BROYDENJACOBIAN  Rank-1 secant (Broyden) update for constraint Jacobians.
%   B = adamnlopt.eval_BroydenJacobian(J0) initialises from the exact Jacobian
%   J0 (mxn). Call B.update(s, y, cNew) after each step where s=dx, y=dc, and
%   cNew=c(x+) to advance the secant approximation:
%
%       J_new = J_old + (y - J_old*s) * s' / (s'*s)
%
%   The approximation is refreshed (staleness=0) when the Broyden residual
%   relative to ||cNew|| exceeds opts.broydenTol, or when staleness exceeds
%   opts.broydenMaxStale. Call B.needsRefresh() to query, then reset with
%   B.setExact(J) after recomputing the exact Jacobian.
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

        function update(obj, s, y, cNew)
        %UPDATE  Apply a rank-1 secant (Broyden) update to the Jacobian.
        %   update(obj, s, y, cNew) advances the approximation by
        %   J = J + (y - J*s)*s'/(s'*s) and increments the staleness counter.
        %   A near-zero step s is skipped (staleness still increments). If the
        %   relative residual ||y - J*s|| / max(1,||cNew||) exceeds tol_, no
        %   update is applied and staleness is forced to maxStale_ to trigger a
        %   refresh on the next needsRefresh query.
        %
        %   Inputs:
        %     obj  - the eval_BroydenJacobian handle object.
        %     s    - n-by-1 step dx = x+ - x.
        %     y    - m-by-1 constraint change dc = c(x+) - c(x).
        %     cNew - m-by-1 constraint value c(x+), used to scale the residual.
        %
        %   Outputs:
        %     (none) obj is modified in place.
            % s: n-vector (dx), y: m-vector (dc = c(x+)-c(x)), cNew: m-vector.
            ss = s(:);  yy = y(:);
            ss2 = ss.' * ss;
            if ss2 < eps * norm(ss)^2 + eps
                obj.stale_ = obj.stale_ + 1;
                return;
            end
            res = yy - obj.J_ * ss;
            resRel = norm(res) / max(1, norm(cNew(:)));
            if resRel > obj.tol_
                % Residual too large: flag for refresh instead of updating.
                obj.stale_ = obj.maxStale_;   % forces needsRefresh=true
                return;
            end
            obj.J_ = obj.J_ + (res * ss.') / ss2;
            obj.stale_ = obj.stale_ + 1;
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
