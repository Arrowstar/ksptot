function f = testfcn1(x)

if strcmpi(x,'init')
    f.options.PopInitRange = [0, 0; 4, 4] ;
    f.options.Vectorized = 'on' ;
    f.options.HybridFcn = {} ;
    f.options.Generations = 500 ;
    f.options.ConstrBoundary = 'penalize' ;
    f.LB = [0,0] ; f.UB = [] ;
    f.Aeq = [] ; f.beq = [] ;
    f.Aineq = [-1 0] ; f.bineq = [-0.01] ;
%     f.Aineq = [] ; f.bineq = [] ;
    f.nonlcon = [] ;
else
    a = 1 ; b = 0.01 ;
    f = (x(:,1).^b + x(:,2).^(1-b)).^a ;
end