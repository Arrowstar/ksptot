function [c, ceq] = findEarliestArrivalNonlconFun(arrivalUT, departUT, dvFunc, maxDV)
    dv = dvFunc(arrivalUT, departUT);
    c(1) = dv - maxDV;
%     c(2) = -(arrivalUT-departUT);
    
    ceq = [];
end