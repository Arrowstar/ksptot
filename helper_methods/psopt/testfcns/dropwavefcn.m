function f = dropwavefcn(x)

if strcmpi(x,'init')
    f.PopInitRange = [-2;2] ;
    f.KnownMin = [0 0] ; % For plotting purposes only
else
    if size(x,2) > 2
        warning('psopt:demos:toomanydims',...
            'Only using first two dimensions of search space')
    elseif size(x,2) < 2
        error('Drop Wave Function requires two dimensions')
    end
    x = reshape(x,1,[]) ;
    f = -(1 + cos(12*norm(x(1:2))))/(0.5*x(1:2)*x(1:2)'+2) ;
end