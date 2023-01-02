function f = dejongsfcn(x)

if strcmpi(x,'init')
    f.Vectorized = 'on' ;
    f.PopInitRange = [-5; 5] ;
    f.KnownMin = [0 0] ; % For plotting only
else
    f = sum(x.*x,2) ;
end