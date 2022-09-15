function [c,ceq] = launchAscentCons(x, objFunc, smaD, eccD, incD, raanD, argD, bodyRadius, atmoHgt)
    [~, sma, ecc, inc, raan, arg, tru, T, Y, ~, ~] = objFunc(x);
    
    rVect = Y(end,1:3);
    r = norm(rVect);
    
    c = [(bodyRadius+atmoHgt) - r];
    ceq = [(sma - smaD)/(bodyRadius/10);
           ecc - eccD;
           inc - incD];
end