function y = rastriginsfcn(x)
% Takes row inputs. If not row, will attempt to correct it.
% Syntax:
% y = rastriginsfcn(x)
% options = rastringinsfcn('init')

if strcmp(x,'init')
    y.Aineq = [] ; y.bineq = [] ;
    y.Aeq = [] ; y.beq = [] ;
    y.LB = [-4,-4] ; y.UB = [4,4] ;
    y.nonlcon = [] ;
    y.options.PopInitRange = [-4, -4; 4, 4] ;
    y.options.KnownMin = [0,0] ;
    y.options.PopulationSize = 100 ;
    y.options.Vectorized = 'on' ;
    y.options.ConstrBoundary = 'absorb' ;
%     y.options.InitialPopulation = rand(100,2) ;
%     y.options.InitialVelocities = repmat([-1,0],100,1) ;
else
%     x = reshape(x,1,[]) ;
%     y = 10*size(x,2) + x*x' - 10*sum(cos(2*pi*x),2) ;
    
    y = 10*size(x,2) + sum(x.^2,2) - 10.*sum(cos(2*pi*x),2) ;
end