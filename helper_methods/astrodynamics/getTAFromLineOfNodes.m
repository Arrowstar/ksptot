function tru = getTAFromLineOfNodes(nodeR_X, raan, inc, argPe, nodeR_Z) 
%     if(nodeR_Z == 0 && sin(inc) == 0)
        thetaGuess = 0;

        func = @(theta) cos(raan)*cos(theta) - sin(raan)*cos(inc)*sin(theta) - nodeR_X;
        [theta] = fzero(func,thetaGuess);
        tru = AngleZero2Pi(theta - argPe);
%     else
%         theta = asin(nodeR_Z/sin(inc));
%         tru = AngleZero2Pi(theta - argPe);
%     end
end