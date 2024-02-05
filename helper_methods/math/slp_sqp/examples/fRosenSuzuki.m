function [f,g]=fRosenSuzuki(x)
% Objective and constraints for Rosen-Suzuki four-variable problem.
x=x(:);
f = 50 + [-5, -5, -21, 7]*x + [1, 1, 2, 1]*x.^2;
g = [ [1, -1, 1, -1]*x + [1, 1, 1, 1]*x.^2 - 8
      [-1, 0, 0, -1]*x + [1, 2, 1, 2]*x.^2 - 10
      [2, -1, 0, -1]*x + [2, 1, 1, 0]*x.^2 - 5];
end