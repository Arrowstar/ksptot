function [x, fval, grad, hessian, lambda] = unscaleResult(xs, fval, grad, hessian, lambda, sc)
%UNSCALERESULT  Map scaled-space solver outputs back to physical units.
%   [x,fval,grad,hessian,lambda] = adamnlopt.unscaleResult(xs,fval,grad,hessian,
%   lambda,sc) inverts the transform applied by SCALEPROBLEM using the scaling
%   struct SC from COMPUTESCALING, so the values returned to the user are in the
%   original problem units.
%
%   Inverse transforms (see SCALEPROBLEM for the forward map; Dx>0):
%     x       = Dx .* xs
%     fval    = fval_s / wf
%     grad    = grad_s ./ (wf * Dx)
%     hessian = hess_s ./ (wf * (Dx*Dx.'))
%     lambda.eqlin/eqnonlin       = (Dc .* lambda_s) / wf   (linear/nonlinear)
%     lambda.ineqlin/ineqnonlin   = (Di .* lambda_s) / wf
%     lambda.lower/upper          = lambda_s ./ (Dx * wf)
%
%   Inputs:
%     xs      - n-by-1 solution in scaled variables.
%     fval    - scalar scaled objective value.
%     grad    - n-by-1 scaled objective gradient (or []).
%     hessian - n-by-n scaled Lagrangian Hessian model (or []).
%     lambda  - fmincon-style multiplier struct from the scaled solve (fields
%               lower, upper, eqlin, eqnonlin, ineqlin, ineqnonlin), or [].
%     sc      - scaling struct from COMPUTESCALING.
%
%   Outputs:
%     x, fval, grad, hessian, lambda - the same quantities in physical units.
%
%   See also COMPUTESCALING, SCALEPROBLEM, SOLVE.

if ~sc.applied
    x = xs;
    return;   % identity scaling: pass everything through unchanged
end

Dx = sc.Dx;
wf = sc.wf;

x = Dx .* xs;

if ~isempty(fval)
    fval = fval / wf;
end
if ~isempty(grad)
    grad = grad(:) ./ (wf * Dx);
end
if ~isempty(hessian)
    hessian = hessian ./ (wf * (Dx * Dx.'));
end

if ~isempty(lambda) && isstruct(lambda)
    DcLin = sc.Dc(1:sc.mElin);   DcNl = sc.Dc(sc.mElin+1:end);
    DiLin = sc.Di(1:sc.mIlin);   DiNl = sc.Di(sc.mIlin+1:end);
    lambda.eqlin      = safeScale(lambda.eqlin,      DcLin / wf);
    lambda.eqnonlin   = safeScale(lambda.eqnonlin,   DcNl  / wf);
    lambda.ineqlin    = safeScale(lambda.ineqlin,    DiLin / wf);
    lambda.ineqnonlin = safeScale(lambda.ineqnonlin, DiNl  / wf);
    lambda.lower      = safeScale(lambda.lower,      1 ./ (Dx * wf));
    lambda.upper      = safeScale(lambda.upper,      1 ./ (Dx * wf));
end
end

% ------------------------------------------------------------------------
function v = safeScale(v, s)
%SAFESCALE  Elementwise v.*s, tolerant of empty/size-mismatched multipliers.
if isempty(v)
    return;
end
v = v(:);
if numel(s) == numel(v)
    v = v .* s(:);
elseif isscalar(s)
    v = v .* s;
end
end
