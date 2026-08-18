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
%   Solved as a convex QP with quadprog.
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
%            the l1 penalty 1'(vE+wE+sI) in .penalty, and .feasible (true when
%            the penalty is ~0, i.e. the linearized constraints are consistent).
%            On a failed/empty QP solve dx is zero and .penalty is inf.
%
%   See also DEGENERACY_RESTORATIONPHASE, DEGENERACY_REGULARIZEDRECOVERY.

if nargin < 5 || isempty(rho),  rho = 1e3;      end
if nargin < 6 || isempty(prox), prox = 1.0;     end

cE = cE(:);  cI = cI(:);
mE = numel(cE);
mI = numel(cI);
if mE > 0, n = size(JE, 2); else, n = size(JI, 2); end

% Variable layout: z = [dx(n); vE(mE); wE(mE); sI(mI)].
nv = n + 2*mE + mI;
ix   = 1:n;
ivE  = n + (1:mE);
iwE  = n + mE + (1:mE);
isI  = n + 2*mE + (1:mI);

H = sparse(1:n, 1:n, prox, nv, nv);
f = zeros(nv, 1);
f(ivE) = rho;  f(iwE) = rho;  f(isI) = rho;

% Equality rows: JE*dx - vE + wE = -cE.
if mE > 0
    Aeq = [JE, -speye(mE), speye(mE), sparse(mE, mI)];
    beq = -cE;
else
    Aeq = zeros(0, nv);  beq = zeros(0, 1);
end

% Inequality rows: JI*dx - sI <= -cI.
if mI > 0
    Ain = [JI, sparse(mI, 2*mE), -speye(mI)];
    bin = -cI;
else
    Ain = zeros(0, nv);  bin = zeros(0, 1);
end

% Bounds: dx free, elastic variables >= 0.
lb = -inf(nv, 1);
lb([ivE, iwE, isI]) = 0;
ub = inf(nv, 1);

qopts = optimoptions('quadprog', 'Display', 'off');
z = quadprog((H + H.')/2, f, Ain, bin, Aeq, beq, lb, ub, [], qopts);

if isempty(z)
    dx = zeros(n, 1);
    info = struct('vE', zeros(mE,1), 'wE', zeros(mE,1), 'sI', zeros(mI,1), ...
                  'penalty', inf, 'feasible', false);
    return;
end

dx = z(ix);
vE = z(ivE);  wE = z(iwE);  sI = z(isI);
penalty = sum(vE) + sum(wE) + sum(sI);
info = struct('vE', vE, 'wE', wE, 'sI', sI, ...
              'penalty', penalty, 'feasible', penalty <= 1e-8 * max(1, n));
end
