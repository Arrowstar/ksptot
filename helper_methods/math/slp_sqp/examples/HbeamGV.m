function [Hf,Hg] = HbeamGV( x, LM )
%HBEAMGV Hessians for Gary Vanderplaats Cantilever beam with N design variables 
%        from Vanderplaats (1984) Example 5-1, pp. 147-150.
% max(LM)
% min(LM)
if isstruct(LM)
   lambda = LM.ineqnonlin;
else
   lambda = LM;
end
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
suml = [1:nelm]'*L/nelm;

% Objective (volume) Hessian
Hf = sparse(1:ndv,[hi bi],[ll ll]);
% hcond = condest(Hf);
%         fprintf('Objective Hessian Condition Number = %12.4f\n',hcond);
% Stress and aspect ratio constraint Hessians
M = P * (L  - suml+ ll);
for j=1:nelm
    row = [bi(j) hi(j) bi(j) hi(j)];
    col = [bi(j) hi(j) hi(j) bi(j)];
    val = M(j)*[12/(b(j)^3*h(j)^2), 36/(b(j)*h(j)^4), 12/(b(j)^2*h(j)^3)*[1 1]];
    Hg{j} = sparse( row, col, val, ndv, ndv, length(val) ) / Sigma_max;
    Hg{j+nelm+1} =  sparse([],[],[],ndv,ndv,0);
      
end

% Tip displacement constraint Hessian
dyp = [nelm-1:-1:0]'    .* (L - suml +   ll/2);
dyN = P/E*ll.^2./Inertia.*((L - suml + 2*ll/3)/2 + dyp);
row = [1:ndv bi hi];
col = [1:ndv hi bi];
val = [dyN*2./b.^2; dyN*12./h.^2; dyN*3./(b.*h); dyN*3./(b.*h)] / tip_max;
Hg{nelm+1} = sparse(row,col,val, ndv,ndv,2*ndv);

% Lagrangian Hessian if Lagrange Multipliers (LM) supplied
if nargout==1 && nargin>1
%     LM(1:nelm+1)'
%     find(LM(1:2*nelm+1)')
Hff = zeros(size(Hg{1}));
   for n=find(lambda(1:2*nelm+1)')
%        gcond = condest(Hg{n});
      Hff = Hff + lambda(n)*Hg{n};
   end
%       gcond = condest(Hff);
%         fprintf('Hbeam Lagrangian Constraint Hessian Condition Number = %12.4f\n',gcond);
%         fprintf('Hbeam objective Hessian Condition Number = %12.4f\n',condest(Hf));
   Hf = Hf+Hff;
%    lcond = condest(Hf);
%         fprintf('H beam Lagrangian Hessian Condition Number = %12.4f\n',lcond);
end
