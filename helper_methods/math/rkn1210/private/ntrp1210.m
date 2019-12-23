function [yinterp,ypinterp] = ntrp1210(tinterp,t,y,tnew,ynew,klast,phi,psi,idxNonNegative)
%NTRP1210  Interpolation helper function for RKN1210.
%
%   YINTERP = NTRP1210(TINTERP,T,Y,TNEW,YNEW,KLAST,PHI,PSI,IDX) uses data
%   computed in RKN1210 to approximate the solution at time TINTERP. TINTERP
%   may be a scalar or a row vector.
%
%   [YINTERP,YPINTERP] = NTRP1210(TINTERP,T,Y,TNEW,YNEW,KLAST,PHI,PSI,IDX)
%   returns also the derivative of the polynomial approximating the solution.
%
%   IDX has indices of solution components that must be non-negative. Negative
%   YINTERP(IDX) are replaced with zeros and the derivative YPINTERP(IDX) is
%   set to zero.
%
%   See also RKN1210, DEVAL.


% References;
% [1] "Interpolating Runge-Kutta-Nyström Methods of High Order", C.
%     Tsitouras, G. Papageorgiou, Intern. J. Computer Math., vol 47,
%     pp. 209-217 (1993).


% Please report bugs and inquiries to:
%
% Name       : Rody P.S. Oldenhuis
% E-mail     : oldenhuis@gmail.com
% Licence    : 2-clause BSD (See Licence.txt)

% If you find this work useful, please consider a donation:
% https://www.paypal.me/RodyO/3.5


% TODO: make magic happen here


end
