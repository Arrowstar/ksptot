function f = nonlinearconstrdemo(x)
% Nonlinear constraints demo with Rosenbrock's function. Select this
% function by running PSODEMO and choosing it as the demo function.
%
% This demonstration shows an example of the pso working over Rosenbrock's
% banana function, with an additional nonlinear constraint confining the
% swarm to search within a four leaf clover-shaped area (quadrifolium)
% superimposed on top of the two-dimensional design space. The true global
% optimum is marked by the red flag, and lies right on the border of the
% feasible design space.

if strcmp(x,'init')
%     f.Aineq = [1 -1;-1 0] ;
%     f.bineq = [0;0] ;
    f.Aineq = [] ;
    f.bineq = [] ;
    f.Aeq = [] ;
    f.beq = [] ;
    f.LB = [] ; f.UB = [] ;
    f.nonlcon = 'quadrifolium' ; % Could also use 'heart' or 'unitdisk'
    f.options.PopInitRange = [-2, -2; 2, 2] ;
    f.options.KnownMin = [1,1] ;
    f.options.PopulationSize = 100 ;
    f.options.ConstrBoundary = 'penalize' ;
    f.options.UseParallel = 'always' ;
else
    x = reshape(x,1,[]) ;
    if size(x,2) >= 2
%         x1 = x(1:end-1) ; x2 = x(end) ;
        f = 0 ;
        for i = 1:size(x,2)-1
            f = f + (1-x(i))^2 + 100*(x(i+1) - x(i)^2)^2 ;
        end
    else
        error('Rosenbrock''s function requires at least two inputs')
    end
end