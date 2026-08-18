function Hv = hessianVecProduct(H, v)
%HESSIANVECPRODUCT  Hessian-vector product for dense or quasi-Newton models.
%   Hv = adamnlopt.hessianVecProduct(H, v) returns H*v where H is either a dense
%   symmetric matrix or an adamnlopt.HessianModel operator (LBFGSHessian or
%   BFGSHessian). Centralizing the product lets the trust-region CG solver and
%   (Stage 7) Krylov methods run matrix-free against the same Hessian
%   abstraction.
%
%   Inputs:
%     H - n-by-n dense symmetric Hessian matrix, or an adamnlopt.HessianModel
%         operator whose apply method supplies the product.
%     v - n-by-1 vector to multiply by H (reshaped to a column internally).
%
%   Outputs:
%     Hv - n-by-1 product H*v.
%
%   See also LAGRANGIANHESSIAN, HESSIANMODEL, LBFGSHESSIAN, BFGSHESSIAN.

if isa(H, 'adamnlopt.HessianModel')
    Hv = H.apply(v);
else
    Hv = H * v(:);
end
end
