function [gradf,gradg]=gRosenSuzuki(x)
% Objective and constraint gradients for Rosen-Suzuki four-variable problem.
x=x(:);
gradf = [-5, -5, -21, 7]' + [1, 1, 2, 1]'.*x*2;
gradg = [ [1, -1, 1, -1] + [1, 1, 1, 1].*x'*2
          [-1, 0, 0, -1] + [1, 2, 1, 2].*x'*2
          [2, -1, 0, -1] + [2, 1, 1, 0].*x'*2]';
end