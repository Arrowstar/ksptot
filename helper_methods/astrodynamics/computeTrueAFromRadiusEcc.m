function tru = computeTrueAFromRadiusEcc(r, sma, ecc)
%trueFromRadiusEcc Summary of this function goes here
%   Detailed explanation goes here
    p=sma.*(1-ecc.^2);
    tru = real(acos((p./r - 1)./ecc));
end

