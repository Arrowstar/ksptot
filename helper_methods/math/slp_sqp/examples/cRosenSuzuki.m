function [c,ceq,GC,GCeq]=cRosenSuzuki(x)
% Constraint functions and gradients for Rosen-Suzuki four-variable problem. 
x=x(:);
c = [ [1, -1, 1, -1]*x + [1, 1, 1, 1]*x.^2 - 8
      [-1, 0, 0, -1]*x + [1, 2, 1, 2]*x.^2 - 10
      [2, -1, 0, -1]*x + [2, 1, 1, 0]*x.^2 - 5];
ceq = [];
GC  = [ [1, -1, 1, -1] + [1, 1, 1, 1].*x'*2
        [-1, 0, 0, -1] + [1, 2, 1, 2].*x'*2
        [2, -1, 0, -1] + [2, 1, 1, 0].*x'*2]';
GCeq = [];
end