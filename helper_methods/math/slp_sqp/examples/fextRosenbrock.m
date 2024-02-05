function [f,g] = fextRosenbrock( x )
% Function evaluation for scalable, extended Rosenbrock function
%
% Goldberg, D. E. (1989) Genetic algorithms in search, optimization and
% machine learning. Reading, Massachusetts: Addison-Wesley
%
% Kok, Schalk, and Carl Sandrock (2009) "Locating and Characterizing the
% Stationary Points of the Extended Rosenbrock Function," Evolutionary
% Computation, No. 17 (3):437-453, doi: 10.1162/evco.2009.17.3.437

f = sum( 100*(x(1:end-1).^2 - x(2:end)).^2 + (x(1:end-1) - 1).^2 );
g = []; % unconstrained

end