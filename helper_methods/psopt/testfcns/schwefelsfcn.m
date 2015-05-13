function f = schwefelsfcn(x)
% Schwefel's function.

if strcmp(x,'init')
    f.Aineq = [] ;
    f.bineq = [] ;
    f.Aeq = [] ;
    f.beq = [] ;
    f.LB = -500*ones(1,2) ; f.UB = 500*ones(1,2) ;
    f.nonlcon = [] ;
    f.options.PopulationSize = 500 ;
    f.options.PopInitRange = [-500; 500] ;
    f.options.ConstrBoundary = 'absorb' ;
    f.options.KnownMin = 420.9687*ones(1,2) ;
else
    x = reshape(x,1,[]) ;
    f = sum(-x.*sin(sqrt(abs(x))),2) ;
end