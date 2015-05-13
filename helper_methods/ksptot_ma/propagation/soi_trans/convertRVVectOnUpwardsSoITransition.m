function [rVectUp, vVectUp] = convertRVVectOnUpwardsSoITransition(bodyInfo, parentBodyInfo, ut, rVect, vVect)
%convertRVVectOnUpwardsSoITransition Summary of this function goes here
%   Detailed explanation goes here

    [rVectBody, vVectBody] = getStateAtTime(bodyInfo, ut, parentBodyInfo.gm);
    rVectUp = rVectBody + rVect';
    vVectUp = vVectBody + vVect';
end

