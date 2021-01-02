function f = ackleysfcn(x)
% Ackley's Function.

if strcmp(x,'init')
    f.PopInitRange = [-32.768; 32.768] ;
    f.KnownMin = [0,0] ; % For plotting only
else
    x = reshape(x,1,[]) ;
    a = 20 ;
    b = 0.2 ;
    n = size(x,2) ;
    c = 2*pi ;
    f = -a*exp(-b*sqrt(1/n*(x*x'))) - exp(1/n*(cos(c*x)*cos(c*x'))) + ...
        a + exp(1) ;
end