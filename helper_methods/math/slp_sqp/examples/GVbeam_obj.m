function [f,gradf] = GVbeam_obj( x )
%GVbeam_f Objective function of the Cantilever beam with N design variables
%        from Vanderplaats (1984) Example 5-1, pp. 147-150.
x=x(:);
ndv  = length(x);
nelm = ndv/2;
bi=1:nelm;
hi=nelm+1:ndv;
L=500;     % Length in centimeters
b = x(bi); % base width of each element in meters from cm
h = x(hi); % height of each element in meters from cm
ll = (L/nelm)*ones(nelm,1);
f = sum( b.*h.*ll );               % Volume of beam in cm^3

% Objective (volume) gradient
if nargout>1
   gradf = zeros(ndv,1);
   gradf(bi) = h.*ll;
   gradf(hi) = b.*ll;
end
end