function [dx, info] = degeneracy_elasticVariables(cE, JE, cI, JI, rho, prox)
%DEGENERACY_ELASTICVARIABLES Elastic-mode (l1-penalty) feasibility step.
%   [dx, info] = adamnlopt.degeneracy_elasticVariables(cE, JE, cI, JI, rho, prox)
%   computes a bounded step for constraints that may be infeasible or mutually
%   conflicting, by relaxing every constraint with nonnegative elastic
%   variables penalized in the objective (SNOPT elastic mode):
%
%     min_{dx,vE,wE,sI}  0.5*prox*||dx||^2 + rho*(1'vE + 1'wE + 1'sI)
%     s.t.  JE*dx - vE + wE = -cE          (cE + JE*dx = vE - wE)
%           JI*dx - sI      <= -cI          (cI + JI*dx <= sI)
%           vE, wE, sI >= 0
%
%   The elastic variables make the subproblem always feasible, and the proximal
%   term 0.5*prox*||dx||^2 keeps dx bounded even when the constraints conflict
%   (so no direction can satisfy them). rho is the penalty weight; a larger rho
%   pushes the step toward true feasibility. INFO reports the elastic variables,
%   the l1 penalty 1'(vE+wE+sI), and .feasible (true if the penalty is ~0, i.e.
%   the linearized constraints are consistent).
%
%   SOLVED WITHOUT THE OPTIMIZATION TOOLBOX.  The elastic variables have a
%   closed form once dx is fixed -- vE - wE = cE + JE*dx with both nonnegative
%   and both penalized means vE + wE = |cE + JE*dx|, and sI >= max(cI+JI*dx, 0)
%   is tight -- so the QP above is exactly
%
%     min_dx  0.5*prox*||dx||^2 + rho*( ||cE + JE*dx||_1
%                                       + sum max(cI + JI*dx, 0) )
%
%   with no constraints at all. Its Lagrangian dual, with y = [u; w] the
%   multipliers of the two penalty terms, is the concave quadratic
%
%     max_y  c'y - (1/(2*prox))*||A'y||^2   over  -rho <= u <= rho,  0 <= w <= rho
%
%   where A = [JE; JI] and c = [cE; cI], and the primal is recovered exactly as
%   dx = -(1/prox)*A'*y. The constraints are now a plain BOX, which cyclic
%   coordinate ascent solves with an exact closed-form step per coordinate and
%   no step-size tuning; strong duality holds (convex QP, strictly feasible),
%   so the primal-dual gap below is a real optimality certificate rather than a
%   heuristic stopping rule. This replaces a quadprog call, the package's only
%   Optimization Toolbox dependency, which made every elastic-mode recovery
%   fail outright on an installation without that license.
%
%   Inputs:
%     cE   - mE-by-1 equality constraint values at the current point.
%     JE   - mE-by-n equality constraint Jacobian.
%     cI   - mI-by-1 inequality constraint values at the current point.
%     JI   - mI-by-n inequality constraint Jacobian.
%     rho  - (optional) elastic penalty weight on the l1 relaxation; defaults
%            to 1e3. Larger rho pushes the step toward true feasibility.
%     prox - (optional) proximal weight on 0.5*prox*||dx||^2 that keeps dx
%            bounded; defaults to 1.0.
%
%   Outputs:
%     dx   - n-by-1 elastic-mode step in the primal variables.
%     info - struct reporting the elastic variables vE, wE, sI (mE/mE/mI-by-1),
%            the l1 penalty 1'(vE+wE+sI) in .penalty, .feasible (true when the
%            penalty is ~0, i.e. the linearized constraints are consistent),
%            .gap (the relative primal-dual gap attained), .sweeps (coordinate
%            sweeps used) and .converged (gap within tolerance).
%            On a degenerate/non-finite solve dx is zero and .penalty is inf.
%
%   See also DEGENERACY_RESTORATIONPHASE, DEGENERACY_REGULARIZEDRECOVERY.

if nargin < 5 || isempty(rho),  rho = 1e3;      end
if nargin < 6 || isempty(prox), prox = 1.0;     end

cE = cE(:);  cI = cI(:);
mE = numel(cE);
mI = numel(cI);
if mE > 0, n = size(JE, 2); else, n = size(JI, 2); end

failInfo = struct('vE', zeros(mE,1), 'wE', zeros(mE,1), 'sI', zeros(mI,1), ...
                  'penalty', inf, 'feasible', false, 'gap', inf, ...
                  'sweeps', 0, 'converged', false);
if ~(prox > 0) || ~isfinite(prox) || ~(rho > 0)
    dx = zeros(n, 1);  info = failInfo;  return;
end

m = mE + mI;
if m == 0
    % Nothing to relax: the proximal term alone is minimized at dx = 0.
    dx = zeros(n, 1);
    info = struct('vE', zeros(0,1), 'wE', zeros(0,1), 'sI', zeros(0,1), ...
                  'penalty', 0, 'feasible', true, 'gap', 0, ...
                  'sweeps', 0, 'converged', true);
    return;
end

A = full([JE; JI]);                % m-by-n (dense: rows are read one per sweep)
c = [cE; cI];
if ~all(isfinite(A(:))) || ~all(isfinite(c))
    dx = zeros(n, 1);  info = failInfo;  return;
end

% Dual box: u in [-rho, rho] (equalities, from |.|), w in [0, rho] (violated
% inequalities, from max(.,0)).
ylo = [-rho * ones(mE, 1); zeros(mI, 1)];
yhi =   rho * ones(m, 1);

% Row norms set the per-coordinate curvature of the dual quadratic.
rowSq = sum(A .^ 2, 2);            % ||A(i,:)||^2
Qii   = rowSq / prox;

maxSweeps = 500;
tol       = 1e-9;                  % relative primal-dual gap

y = zeros(m, 1);
v = zeros(n, 1);                   % maintained invariant: v == A'*y
gap = inf;  sweeps = 0;  converged = false;

for sweep = 1:maxSweeps
    sweeps = sweep;
    for i = 1:m
        ai = A(i, :).';
        % d/dy_i of  c'y - ||A'y||^2/(2*prox)  is  c_i - (A(i,:)*v)/prox.
        gi = c(i) - (ai.' * v) / prox;
        if Qii(i) > 0
            yn = y(i) + gi / Qii(i);        % exact unconstrained maximizer
        elseif gi > 0
            yn = yhi(i);                    % zero row: dual is linear in y_i
        elseif gi < 0
            yn = ylo(i);
        else
            yn = y(i);
        end
        yn = min(max(yn, ylo(i)), yhi(i));
        d  = yn - y(i);
        if d ~= 0
            y(i) = yn;
            v    = v + d * ai;
        end
    end

    % Primal-dual gap: a real certificate, since strong duality holds here.
    dxk = -v / prox;
    r   = c + A * dxk;
    pObj = 0.5 * prox * (dxk.' * dxk) ...
           + rho * (sum(abs(r(1:mE))) + sum(max(r(mE+1:end), 0)));
    dObj = c.' * y - (v.' * v) / (2 * prox);
    gap  = (pObj - dObj) / max(1, abs(pObj));
    if ~isfinite(gap)
        dx = zeros(n, 1);  info = failInfo;  info.sweeps = sweeps;  return;
    end
    if gap <= tol
        converged = true;
        break;
    end
end

dx = -v / prox;
if ~all(isfinite(dx))
    dx = zeros(n, 1);  info = failInfo;  info.sweeps = sweeps;  return;
end

% Elastic variables at their closed-form optimum for this dx.
r  = c + A * dx;
rE = r(1:mE);
rI = r(mE+1:end);
vE = max(rE, 0);
wE = max(-rE, 0);
sI = max(rI, 0);
penalty = sum(vE) + sum(wE) + sum(sI);
info = struct('vE', vE, 'wE', wE, 'sI', sI, ...
              'penalty', penalty, 'feasible', penalty <= 1e-8 * max(1, n), ...
              'gap', gap, 'sweeps', sweeps, 'converged', converged);
end
