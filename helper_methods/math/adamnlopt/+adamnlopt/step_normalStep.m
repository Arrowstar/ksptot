function v = step_normalStep(JE, cE, Delta)
%STEP_NORMALSTEP  Byrd-Omojokun normal (feasibility) step.
%   v = adamnlopt.step_normalStep(JE, cE, Delta) approximately minimizes the
%   linearized constraint violation
%       0.5 * || JE*v + cE ||^2   s.t.  ||v|| <= Delta
%   by a dogleg between the Cauchy point (steepest descent of that model) and
%   the Gauss-Newton minimum-norm solution of JE*v = -cE. The returned v lies
%   in range(JE') (it is the minimum-norm feasibility move), hence orthogonal
%   to null(JE) -- which lets step_tangentialStep size its trust region as
%   sqrt(Delta^2 - ||v||^2).
%
%   Inputs:
%     JE    - mE-by-n Jacobian of the equality constraints. Pass empty when
%             there are no equality constraints (v is then zero).
%     cE    - mE-by-1 equality-constraint values (violation) at the current
%             point. Pass empty when there are no equality constraints.
%     Delta - scalar trust-region radius bounding ||v||.
%
%   Outputs:
%     v - n-by-1 normal (feasibility) step lying in range(JE') with
%         ||v|| <= Delta.
%
%   See also STEP_TANGENTIALSTEP, STEP_TRUSTREGIONSUBPROBLEM.

n = size(JE, 2);
if isempty(JE) || isempty(cE)
    v = zeros(n, 1);  return;
end

% Gauss-Newton minimum-norm solution of JE*v = -cE.
vGN = lsqminnorm(JE, -cE);
if norm(vGN) <= Delta
    v = vGN;  return;
end

% Cauchy point: minimizer of the model along the steepest-descent direction.
gc  = JE.' * cE;                 % gradient of the model at v = 0
Jgc = JE * gc;
denom = Jgc.' * Jgc;
if denom <= 0
    v = zeros(n, 1);  return;
end
tC = (gc.' * gc) / denom;
vC = -tC * gc;

if norm(vC) >= Delta
    v = -(Delta / norm(gc)) * gc;   % truncated steepest-descent step
    return;
end

% Dogleg: intersect the segment vC -> vGN with the trust-region boundary.
d = vGN - vC;
a = d.' * d;
b = 2 * (vC.' * d);
c = (vC.' * vC) - Delta^2;
t = (-b + sqrt(max(b^2 - 4*a*c, 0))) / (2*a);
v = vC + t * d;
end
