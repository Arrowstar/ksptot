function f = langermannsfcn(x)

if strcmpi(x,'init')
    f.PopInitRange = [0;10] ;
    f.PopulationSize = 200 ;
elseif size(x,2) == 2
    x = reshape(x,1,[]) ;
    a = [3,5,2,1,7; 5,2,1,4,9] ;
    c = [1,2,5,2,3] ;
%     xa = (repmat(x,size(a,2),1)'-a)'*(repmat(x,size(a,2),1)'-a) ;
%     % xa is now 5x2
%     f = exp(-1/pi*xa)*cos(pi*xa);
%     f = 0 ;
    f = sum(c.*exp(-sum((repmat(x',1,size(a,2)) - a).^2,1)/pi).*...
        cos(pi*sum((repmat(x',1,size(a,2)) - a).^2,1)),2) ;
else
    error('Two dimensional input required for Langermann''s Function')
end