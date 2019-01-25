function [rVectUp, vVectUp] = convertRVVectOnUpwardsSoITransition(bodyInfo, celBodyData, ut, rVect, vVect)
%convertRVVectOnUpwardsSoITransition Summary of this function goes here
%   Detailed explanation goes here

    [rVectBody, vVectBody] = getStateGMm(bodyInfo, ut, celBodyData);
    rVectUp = rVectBody + rVect';
    vVectUp = vVectBody + vVect';
end

