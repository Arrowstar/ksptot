function [gradf,gradg] = gextRosenbrock( x )
% Gradient evaluation for scalable, extended Rosenbrock function
%
% Goldberg, D. E. (1989) Genetic algorithms in search, optimization and
% machine learning. Reading, Massachusetts: Addison-Wesley
%
% Kok, Schalk, and Carl Sandrock (2009) "Locating and Characterizing the
% Stationary Points of the Extended Rosenbrock Function," Evolutionary
% Computation, No. 17 (3):437-453, doi: 10.1162/evco.2009.17.3.437

N = numel(x);
gradf = zeros( N, 1 );
gradf(1) = 400*x(1)*( x(1).^2 - x(2) ) + 2*( x(1) - 1 );
gradf(N) = -200*( x(N-1).^2  - x(N) );
gradf(2:N-1) = -200*( x(1:N-2).^2 - x(2:N-1) ) + 2*( x(2:N-1) - 1 ) ...
             +  400*x(2:N-1).*( x(2:N-1).^2 - x(3:N) );
gradg = [];

end