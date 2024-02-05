function [g,ceq,gradg,ceqgrad] = GVbeam_nlcon( x )
%GVbeam_c Nonlinear constraints for Cantilever beam with N design variables
%        from Vanderplaats (1984) Example 5-1, pp. 147-150.
ceq = [];
ceqgrad = [];
x=x(:);
ndv  = length(x);
nelm = ndv/2;
bi=1:nelm;
hi=nelm+1:ndv;
b = x(bi); % base width of each element in meters from cm
h = x(hi); % height of each element in meters from cm
P=50e3;    % Newtons
E=200e5;   % Newtons / cm^2 (Pascal x10^-4)
L=500;     % Length in centimeters
Sigma_max = 14e3; % N/cm^2
tip_max   = 2.5;  %0.03457; % centimeters
Inertia = b.*h.^3/12;
ll = (L/nelm)*ones(nelm,1);
suml = (1:nelm)'*L/nelm;
% fid = fopen('conscount.txt','a');
% fprintf(fid,'%1.0f, ',1);fclose(fid);
y1 = P*ll.^2 ./(2*E*Inertia) .* ( L - suml + 2/3*ll );
yp = P*ll    ./  (E*Inertia) .* ( L - suml +     ll/2 );
for i = 2:nelm
    yp(i) = yp(i) + yp(i-1);
end
yN  = sum( y1 ) + sum( yp(1:end-1).*ll(2:end ) );
M   = P * ( L - suml + ll );
sigma = M.*(h/2)./Inertia;

g = zeros(nelm+1, 1 );
g(nelm+1) = yN    / tip_max - 1;   % tip deflection constraint
g(1:nelm) = sigma / Sigma_max - 1; % stresses

% Calculate gradients of lateral slopes, deflections and stresses
if nargout>2
   gradg = zeros(ndv,nelm+1);
%  suml = (1:nelm)'*L/nelm;
   
   % Stress constraint gradients
%  M = P * (L - suml + ll);
   gradg(bi,1:nelm) = diag(  -6*M./(b.^2.*h.^2) / Sigma_max );
   gradg(hi,1:nelm) = diag( -12*M./(b   .*h.^3) / Sigma_max );
   
   % Tip displacement constraint
   % for i = 2:nelm-1
   % 	 dyp(i) = dyp1(i) + dyp(i-1);
   % end
   %dyp =                       (L - suml +   ll/2);    dyp(end)=0;
   dyp = ( L - suml +     ll/2 ) .* [nelm-1:-1:0]';
   dyN = -P/E*ll.^2./Inertia.*((L - suml + 2*ll/3)/2 + dyp);
   gradg(bi,nelm+1) = dyN./b   / tip_max;
   gradg(hi,nelm+1) = dyN./h*3 / tip_max;
end
end