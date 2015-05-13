function f = binarytestfcn(x)
% The minimum value of f should be obtained when x = [0,1,0,1,0,1, etc].

if strcmp(x,'init')
    f.PopulationType = 'bitstring' ;
else
    if length(x) < 2, x(2) = 0 ; end
    f = sum(x(1:2:end)) - sum(x(2:2:end)) ;
end