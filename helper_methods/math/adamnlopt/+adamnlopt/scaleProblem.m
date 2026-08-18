function pS = scaleProblem(problem, sc)
%SCALEPROBLEM  Transform a problem into the scaled space defined by a scaling.
%   pS = adamnlopt.scaleProblem(problem, sc) returns a problem struct equivalent
%   to PROBLEM but expressed in the scaled variables  xs = x ./ sc.Dx  so the
%   solver runs on O(1) data. The objective and nonlinear-constraint handles are
%   wrapped (values and, when supplied, analytic derivatives are transformed);
%   the linear constraint rows, initial point, and bounds are scaled directly.
%   UNSCALERESULT maps the solver outputs back to physical units.
%
%   Transforms (Dx>0, so bound directions and infinities are preserved):
%     x   = Dx .* xs
%     fs  = wf * f(x),                 grad_xs fs  = wf * (Dx .* grad_x f)
%     cEs = Dc .* cE(x),              JEs = Dc .* JE * diag(Dx)
%     cIs = Di .* cI(x),              JIs = Di .* JI * diag(Dx)
%     x0s = x0 ./ Dx, lb_s = lb ./ Dx, ub_s = ub ./ Dx
%   with Dc/Di split into linear rows first (mElin/mIlin) then nonlinear rows.
%
%   Inputs:
%     problem - validated problem struct (see VALIDATEPROBLEM).
%     sc      - scaling struct from COMPUTESCALING (must have sc.applied=true).
%
%   Outputs:
%     pS - problem struct in scaled space, with wrapped objFun/nlcon, scaled
%          Aineq/bineq, Aeqlin/beqlin, x0, lb, ub; all other fields unchanged.
%
%   See also COMPUTESCALING, UNSCALERESULT, VALIDATEPROBLEM, SOLVE.

Dx = sc.Dx;
wf = sc.wf;

% Split constraint-row scales into linear (first) and nonlinear blocks.
DcLin = sc.Dc(1:sc.mElin);        DcNl = sc.Dc(sc.mElin+1:end);
DiLin = sc.Di(1:sc.mIlin);        DiNl = sc.Di(sc.mIlin+1:end);

pS = problem;

% --- Objective handle ---
f0 = problem.objFun;
if problem.hasObjGrad
    pS.objFun = @(xs) scaledObjWithGrad(f0, xs, Dx, wf);
else
    pS.objFun = @(xs) wf * f0(Dx .* xs);
end

% --- Nonlinear constraint handle ---
if ~isempty(problem.nlcon)
    c0 = problem.nlcon;
    if problem.hasConGrad
        pS.nlcon = @(xs) scaledConWithGrad(c0, xs, Dx, DiNl, DcNl);
    else
        pS.nlcon = @(xs) scaledCon(c0, xs, Dx, DiNl, DcNl);
    end
end

% --- Linear constraint rows:  row-scale, then column-scale by Dx ---
if ~isempty(problem.Aineq)
    pS.Aineq = (DiLin .* problem.Aineq) .* Dx.';
    pS.bineq = DiLin .* problem.bineq;
end
if ~isempty(problem.Aeqlin)
    pS.Aeqlin = (DcLin .* problem.Aeqlin) .* Dx.';
    pS.beqlin = DcLin .* problem.beqlin;
end

% --- Initial point and bounds ---
pS.x0 = problem.x0 ./ Dx;
pS.lb = problem.lb ./ Dx;
pS.ub = problem.ub ./ Dx;
end

% ------------------------------------------------------------------------
function [fs, gs] = scaledObjWithGrad(f0, xs, Dx, wf)
%SCALEDOBJWITHGRAD  Scaled objective value and gradient in scaled variables.
[f, g] = f0(Dx .* xs);
fs = wf * f;
gs = wf * (Dx .* g(:));
end

function [cs, ceqs] = scaledCon(c0, xs, Dx, DiNl, DcNl)
%SCALEDCON  Scaled nonlinear constraint values in scaled variables.
[c, ceq] = c0(Dx .* xs);
cs   = DiNl .* c(:);
ceqs = DcNl .* ceq(:);
end

function [cs, ceqs, gcs, gceqs] = scaledConWithGrad(c0, xs, Dx, DiNl, DcNl)
%SCALEDCONWITHGRAD  Scaled nonlinear constraint values and Jacobians.
%   User gradients follow the fmincon convention (n-by-m, columns are
%   constraints). Column j of the scaled gradient is  Di_j * (Dx .* col_j).
[c, ceq, gc, gceq] = c0(Dx .* xs);
cs   = DiNl .* c(:);
ceqs = DcNl .* ceq(:);
if isempty(gc),   gcs   = gc;   else, gcs   = (Dx .* gc)   .* DiNl.'; end
if isempty(gceq), gceqs = gceq; else, gceqs = (Dx .* gceq) .* DcNl.'; end
end
