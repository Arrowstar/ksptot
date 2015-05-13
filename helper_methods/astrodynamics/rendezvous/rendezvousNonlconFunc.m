function [c, ceq] = rendezvousNonlconFunc(x, iniOrbit, finOrbit, gmuXfr, minPe, maxAp)
%rendezvousNonlconFunc Summary of this function goes here
%   Detailed explanation goes here
    [~, ~, ~, ~, ~, ~, xfrOrbit, ~, ~] = rendezvousObjFunc(x, iniOrbit, finOrbit, gmuXfr, [1,1]);
    
	[rAp, rPe] = computeApogeePerigee(xfrOrbit(1), xfrOrbit(2));
    c(1) = rAp - maxAp;
    c(2) = minPe - rPe;
    ceq = [];
end

