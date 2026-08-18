classdef LBFGSHessian < adamnlopt.HessianModel
%LBFGSHESSIAN  Limited-memory BFGS approximation of the Lagrangian Hessian.
%   Maintains up to M recent secant pairs (s_k, y_k) and reconstructs a dense
%   SPD matrix B via the Byrd-Nocedal-Schnabel compact representation, so the
%   direct KKT solver can use it in place of an (expensive) finite-difference
%   Hessian. The constrained secant pair
%       s = x_{k+1} - x_k,   y = gradL(x_{k+1}, lam) - gradL(x_k, lam)
%   is supplied by the caller. Pairs with insufficient curvature (s'y <= 0) are
%   skipped (a robust, standard limited-memory safeguard).
%
%   B0 = gamma*I with gamma = (y'y)/(s'y) refreshed from the newest pair.
%
%   Properties:
%     m     - memory: maximum number of stored secant pairs.
%     gamma - scaling of the initial Hessian B0 = gamma*I.
%     n     - problem dimension (length of s and y).
%     S     - (private) n-by-k matrix of s vectors, oldest first.
%     Y     - (private) n-by-k matrix of y vectors, oldest first.
%
%   Methods:
%     LBFGSHessian - construct an approximation for an n-dimensional problem.
%     reset        - discard all stored pairs and reset gamma.
%     update       - add a curvature pair (s, y), skipping low-curvature pairs.
%     getMatrix    - form the dense SPD matrix B.
%     apply        - compute the Hessian-vector product B*v without forming B.
%     diagonal     - [] (the compact form has no cheap diagonal).
%
%   For a full-memory alternative that accumulates curvature in every sampled
%   direction at a fixed O(n^2) cost, see BFGSHessian.
%
%   See also BFGSHESSIAN, HESSIANMODEL, LAGRANGIANHESSIAN, HESSIANVECPRODUCT.

    properties
        m         = 10       % memory (number of stored pairs)
        gamma     = 1        % scaling of the initial Hessian B0 = gamma*I
        n         = 0
        gammaMin  = 1e-8     % floor on the B0 scaling gamma
        gammaMax  = 1e8      % ceiling on the B0 scaling gamma (absolute backstop)
        gammaCurvCap = 1e4   % ceiling on gamma relative to directional curvature
        powellEta = 0.2      % Powell-damping threshold (fraction of s'Bs)
    end
    properties (Access = private)
        S = []           % n-by-k matrix of s vectors (oldest first)
        Y = []           % n-by-k matrix of y vectors
    end

    methods
        function obj = LBFGSHessian(n, memory)
        %LBFGSHESSIAN  Construct a limited-memory BFGS Hessian model.
        %   obj = LBFGSHessian(n) creates an empty model for an n-dimensional
        %   problem with the default memory. obj = LBFGSHessian(n, memory) sets
        %   the number of secant pairs retained.
        %
        %   Inputs:
        %     n      - problem dimension (length of the s and y vectors).
        %     memory - (optional) maximum number of stored pairs; defaults to m.
        %
        %   Outputs:
        %     obj - the constructed LBFGSHessian handle object.
            obj.n = n;
            if nargin > 1 && ~isempty(memory), obj.m = max(1, round(memory)); end
            obj.S = zeros(n, 0);
            obj.Y = zeros(n, 0);
        end

        function reset(obj)
        %RESET  Discard all stored secant pairs and reset the scaling.
        %   reset(obj) empties the (s, y) history and restores gamma = 1. Used
        %   after a large discontinuous jump (e.g. a restoration phase) that
        %   invalidates the accumulated secant information.
        %
        %   Inputs:
        %     obj - the LBFGSHessian handle object.
        %
        %   Outputs:
        %     (none) obj is modified in place.
            obj.S = zeros(obj.n, 0);
            obj.Y = zeros(obj.n, 0);
            obj.gamma = 1;
        end

        function accepted = update(obj, s, y)
        %UPDATE  Add a curvature pair (s, y) to the limited-memory history.
        %   accepted = update(obj, s, y) applies Powell damping to y, appends the
        %   (possibly damped) secant pair, and refreshes the initial-Hessian
        %   scaling gamma = (y'y)/(s'y) clamped to [gammaMin, gammaMax]. When the
        %   history exceeds m pairs, the oldest is dropped.
        %
        %   Powell damping (Nocedal & Wright, Procedure 18.2) replaces y with
        %       ybar = phi*y + (1-phi)*B*s,   phi = 1                  if s'y >= eta*s'Bs
        %                                     phi = (1-eta)*s'Bs/(s'Bs - s'y)  else
        %   which guarantees s'ybar >= eta*s'Bs > 0, so the update stays positive
        %   definite WITHOUT discarding the step's information.  This replaces the
        %   old hard skip (s'y > 1e-8*s's), which near a degenerate active bound
        %   let through pairs with tiny-but-positive s'y: those produced a huge
        %   gamma = (y'y)/(s'y) = a blown-up B0 = gamma*I that poisoned the
        %   condensed Newton step and stalled the endgame (opt oscillating while a
        %   fresh restart -- i.e. reset() to B0=I -- always recovered).  Damping +
        %   the gamma clamp keep B0 conditioned so no restart is needed.
        %
        %   Inputs:
        %     obj - the LBFGSHessian handle object.
        %     s   - n-by-1 step x_{k+1} - x_k.
        %     y   - n-by-1 Lagrangian-gradient change gradL(x_{k+1}) - gradL(x_k).
        %
        %   Outputs:
        %     accepted - logical; true if a (damped) pair was stored, false only
        %                when the step s is numerically zero (nothing to learn).
            s = s(:);  y = y(:);
            ss = s.' * s;
            accepted = ss > 0 && all(isfinite(s)) && all(isfinite(y));
            if ~accepted
                return;   % degenerate/invalid step: nothing to learn
            end
            % Powell damping toward the current model B (B*s via the compact form).
            Bs  = obj.apply(s);
            sBs = s.' * Bs;
            sy  = s.' * y;
            if sBs > 0 && sy < obj.powellEta * sBs
                phi = (1 - obj.powellEta) * sBs / (sBs - sy);
                phi = min(max(phi, 0), 1);          % numerical safety
                y   = phi * y + (1 - phi) * Bs;      % damped y-bar
                sy  = s.' * y;                       % now >= eta*sBs > 0
            end
            if sy <= 0
                return;   % damping could not restore curvature (e.g. sBs<=0); skip
            end
            accepted = true;
            obj.S = [obj.S, s];
            obj.Y = [obj.Y, y];
            if size(obj.S, 2) > obj.m
                obj.S(:, 1) = [];
                obj.Y(:, 1) = [];
            end
            % Initial-Hessian scaling.  The textbook estimate g = (y'y)/(s'y)
            % is the LARGEST directional curvature the pair carries.  On a
            % stiff, large-multiplier problem, y picks up an enormous component
            % in constraint-curvature directions nearly orthogonal to s, so
            % ||y||^2 explodes while s'y stays moderate and g pins at the
            % absolute ceiling gammaMax=1e8.  That inflated B0=g*I ill-
            % conditions the compact matrix B = g*I - Phi*M^{-1}*Phi', driving
            % its smallest eigenvalue negative (indefinite W) and its condition
            % number to ~1e13 -- the observed source of the corrupted Newton
            % step and limit cycle.
            %
            % The directional curvature actually sampled along the step is
            % gCurv = (s'y)/(s's) (Rayleigh quotient of the true Hessian in the
            % s direction).  Capping g at gammaCurvCap*gCurv keeps B0 within a
            % bounded factor of real curvature: on a well-scaled problem the two
            % agree (g ~ gCurv) and the cap is inert; only the stiff runaway is
            % reined in.  The absolute [gammaMin, gammaMax] clamp remains as a
            % final backstop.
            g = (y.' * y) / sy;
            gCurv = sy / ss;                       % directional curvature > 0 (sy>0, ss>0)
            if isfinite(gCurv) && gCurv > 0
                g = min(g, obj.gammaCurvCap * gCurv);
            end
            obj.gamma = min(max(g, obj.gammaMin), obj.gammaMax);
        end

        function B = getMatrix(obj)
        %GETMATRIX  Form the dense SPD Hessian approximation B.
        %   B = getMatrix(obj) reconstructs the n-by-n matrix B from the stored
        %   pairs using the Byrd-Nocedal-Schnabel compact representation
        %   B = gamma*I - Phi*(M\Phi'), symmetrized for numerical safety. With
        %   no stored pairs it returns gamma*I.
        %
        %   Inputs:
        %     obj - the LBFGSHessian handle object.
        %
        %   Outputs:
        %     B - n-by-n symmetric positive-definite Hessian approximation.
            n_ = obj.n;
            g  = obj.gamma;
            k  = size(obj.S, 2);
            if k == 0
                B = g * eye(n_);
                return;
            end
            Sm = obj.S;  Ym = obj.Y;
            SY  = Sm.' * Ym;                 % k-by-k
            D   = diag(diag(SY));
            L   = tril(SY, -1);
            SBS = g * (Sm.' * Sm);           % S'*B0*S
            M   = [SBS, L; L.', -D];         % 2k-by-2k
            Phi = [g * Sm, Ym];              % n-by-2k
            ws = warning('off', 'MATLAB:nearlySingularMatrix');
            cleanup = onCleanup(@() warning(ws));
            B   = g * eye(n_) - Phi * (M \ Phi.');
            B   = (B + B.') / 2;
        end

        function Bv = apply(obj, v)
        %APPLY  Hessian-vector product B*v without forming B.
        %   Bv = apply(obj, v) evaluates B*v directly from the compact
        %   representation, avoiding the O(n^2) cost of assembling B. With no
        %   stored pairs it returns gamma*v.
        %
        %   Inputs:
        %     obj - the LBFGSHessian handle object.
        %     v   - n-by-1 vector to multiply by B.
        %
        %   Outputs:
        %     Bv - n-by-1 product B*v.
            % Hessian-vector product B*v without forming B (compact recursion).
            v = v(:);
            g = obj.gamma;
            k = size(obj.S, 2);
            if k == 0
                Bv = g * v;  return;
            end
            Sm = obj.S;  Ym = obj.Y;
            SY  = Sm.' * Ym;
            D   = diag(diag(SY));
            L   = tril(SY, -1);
            SBS = g * (Sm.' * Sm);
            M   = [SBS, L; L.', -D];
            Phi = [g * Sm, Ym];
            ws = warning('off', 'MATLAB:nearlySingularMatrix');
            cleanup = onCleanup(@() warning(ws));
            Bv  = g * v - Phi * (M \ (Phi.' * v));
        end

        function d = diagonal(~)
        %DIAGONAL  No cheap diagonal is available from the compact form.
        %   d = diagonal(obj) returns []. The diagonal of
        %   B = gamma*I - Phi*(M\Phi') would cost O(n*k^2) to extract, which is
        %   the same order as the Krylov iteration the Jacobi preconditioner is
        %   meant to accelerate, so the empty return tells kkt_KKTOperator to
        %   leave op.diag empty and linalg_preconditioner to use the identity.
        %   (BFGSHessian, which stores B explicitly, does supply one.)
        %
        %   Outputs:
        %     d - [] (empty).
            d = [];
        end
    end
end
