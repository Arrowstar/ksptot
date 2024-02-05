function [f,gradf]=objRosenSuzuki(x)
% Objective function and gradient for Rosen-Suzuki four-variable problem.
x=x(:);
f = 50 + [-5, -5, -21, 7]*x + [1, 1, 2, 1]*x.^2;
gradf  = [-5, -5, -21, 7]' + [1, 1, 2, 1]'.*x*2;
end