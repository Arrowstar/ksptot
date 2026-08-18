function tf = globalize_meritAccept(phi0, phiT, dphi, alpha, c)
%GLOBALIZE_MERITACCEPT  Armijo sufficient-decrease test for the l1 merit.
%   tf = adamnlopt.globalize_meritAccept(phi0, phiT, dphi, alpha, c) returns
%   true when the trial merit phiT satisfies
%       phiT <= phi0 + c * alpha * dphi,
%   where dphi <= 0 is the directional derivative of the merit along the step
%   and c in (0,1) the Armijo constant (default 1e-4).
%
%   Inputs:
%     phi0  - scalar merit value at step length a = 0.
%     phiT  - scalar trial merit value at step length alpha.
%     dphi  - scalar directional derivative of the merit along the step (<= 0).
%     alpha - scalar step length.
%     c     - (optional) Armijo constant in (0,1); defaults to 1e-4.
%
%   Outputs:
%     tf - logical; true if the Armijo sufficient-decrease condition holds.
%
%   See also GLOBALIZE_MERITFUNCTION, GLOBALIZE_FILTERLINESEARCH.

if nargin < 5 || isempty(c), c = 1e-4; end
tf = phiT <= phi0 + c * alpha * dphi;
end
