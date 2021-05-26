function output = ppint(pp,a,b)
%PPINT Integrate piecewise polynomial.
%   QQ = PPINT(PP,A) returns the indefinite integral from A to X of a
%   piecewise polynomial PP. PP must be on the form evaluated by PPVAL.
%   QQ is a piecewise polynomial on the same form. Default value for A is
%   the leftmost break of PP.
%
%   I = PPINT(PP,A,B) returns the definite integral from A to B.
%
%   Example:
%       x = linspace(-pi,pi,7);
%       y = sin(x);
%       pp = spline(x,y);
%       I = ppint(pp,0,pi)
%
%       qq = ppint(pp,pi/2);
%       xx = linspace(-pi,pi,201);
%       plot(xx,-cos(xx),xx,ppval(qq,xx),'r')
%
%   See also PPVAL, SPLINE, SPLINEFIT, PPDIFF

%   Author: Jonas Lundgren <splinefit@gmail.com> 2009

if nargin < 1, help ppint, return, end
if nargin < 2, a = pp.breaks(1); end

% Get coefficients and breaks
coefs = pp.coefs;
[m n] = size(coefs);
xb = pp.breaks;
pdim = prod(pp.dim);

% Interval lengths
hb = diff(xb);
hb = repmat(hb,pdim,1);
hb = hb(:);

% Integration
coefs(:,1) = coefs(:,1)/n;
y = coefs(:,1).*hb;
for k = 2:n
    coefs(:,k) = coefs(:,k)/(n-k+1);
    y = (y + coefs(:,k)).*hb;
end
y = reshape(y,pdim,[]);
I = cumsum(y,2);
I = I(:);
coefs(:,n+1) = [zeros(pdim,1); I(1:m-pdim)];

% Set preliminary indefinite integral
qq = pp;
qq.coefs = coefs;
qq.order = n+1;

% Set output
if nargin < 3
    % Indefinite integral from a to x
    if a ~= xb(1)
        I0 = ppval(qq,a);
        I0 = I0(:);
        I0 = repmat(I0,m/pdim,1);
        qq.coefs(:,n+1) = qq.coefs(:,n+1) - I0;
    end
    output = qq;
else
    % Definite integral from a to b
    output = ppval(qq,b) - ppval(qq,a);
end

