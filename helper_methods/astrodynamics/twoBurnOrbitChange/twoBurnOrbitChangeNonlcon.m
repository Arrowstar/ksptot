function [c, ceq] = twoBurnOrbitChangeNonlcon(x, r1, r2, objFunc, gmuXfr)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    [~, ~, ~, ~, ~, xfrOrbit] = objFunc(x);
    [rVect1,~]=getStatefromKepler(xfrOrbit(1), xfrOrbit(2), xfrOrbit(3), xfrOrbit(4), xfrOrbit(5), xfrOrbit(6), gmuXfr);
    [rVect2,~]=getStatefromKepler(xfrOrbit(1), xfrOrbit(2), xfrOrbit(3), xfrOrbit(4), xfrOrbit(5), xfrOrbit(7), gmuXfr);
    
    c = [];
    
    ceq = [];
    if(not(isempty(r1)))
        ceq(end+1) = r1(1) - rVect1(1);
        ceq(end+1) = r1(2) - rVect1(2);
        ceq(end+1) = r1(3) - rVect1(3);
    end
    if(not(isempty(r2)))
        ceq(end+1) = r2(1) - rVect2(1);
        ceq(end+1) = r2(2) - rVect2(2);
        ceq(end+1) = r2(3) - rVect2(3);
    end    
end

