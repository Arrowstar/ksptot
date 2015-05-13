function initrange = psocheckpopulationinitrange(initrange,LB,UB)
% Automatically adjust PopInitRange according to provided LB and UB.

lowerRange = initrange(1,:) ;
upperRange = initrange(2,:) ;

lowerInf = isinf(LB) ;
index = false(size(lowerRange,2),1) ;
index(~lowerInf) = LB(~lowerInf) ~= lowerRange(~lowerInf) ;
lowerRange(index) = LB(index) ;

upperInf = isinf(UB) ;
index = false(size(upperRange,2),1) ;
index(~upperInf) = LB(~upperInf) ~= upperRange(~upperInf) ;
upperRange(index) = UB(index) ;

initrange = [lowerRange; upperRange] ;