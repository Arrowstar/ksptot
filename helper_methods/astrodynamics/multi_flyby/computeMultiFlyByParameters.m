function [smaIn, eIn, hHat, sHat, smaOut, eOut, oHat] = computeMultiFlyByParameters(vInfIn, vInfOut, gmu)
%computeFlyByParameters Summary of this function goes here
%   Detailed explanation goes here

    normVInfIn = sqrt(sum(abs(vInfIn).^2,1));
    normVinfOut = sqrt(sum(abs(vInfOut).^2,1));

    sHat = bsxfun(@rdivide,vInfIn,normVInfIn);
    energyIn = normVInfIn.^2./2;
    smaIn = -gmu./(2*energyIn);

    oHat = bsxfun(@rdivide,vInfOut,normVinfOut);
    energyOut = normVinfOut.^2./2;
    smaOut = -gmu./(2*energyOut);

    crossSO = cross(sHat, oHat);
    normCrossSO = sqrt(sum(abs(crossSO).^2,1));
    hHat = bsxfun(@rdivide,crossSO,normCrossSO);
    delta = acos(dot(sHat,oHat)); %may need the dim argument

    e1Eqn = @(e2) 1+(smaOut./smaIn).*(e2-1);
    f = @(e2) delta - asin(1./e1Eqn(e2)) - asin(1./e2);
    lb = 1.0 * ones(1,length(delta));
    ub = 1000000000 * ones(1,length(delta));

    [eOut, ~, ~] = bisection(f,lb,ub, [], 1E-8);
    eIn = e1Eqn(eOut);
end

