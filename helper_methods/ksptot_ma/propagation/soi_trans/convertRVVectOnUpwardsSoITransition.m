function [rVectUp, vVectUp] = convertRVVectOnUpwardsSoITransition(bodyInfo, celBodyData, ut, rVect, vVect)
%convertRVVectOnUpwardsSoITransition Summary of this function goes here
%   Detailed explanation goes here
%     pBodyInfo = getParentBodyInfo(childBodyInfo, celBodyData);
%     gmu = pBodyInfo.gm;

%     [rVectBody, vVectBody] = getStateAtTime(bodyInfo, ut, getParentGM(bodyInfo, celBodyData)); %getParentGM(bodyInfo, celBodyData)
    [rVectBody, vVectBody] = getStateGMm(bodyInfo, ut, celBodyData);
    rVectUp = rVectBody + rVect';
    vVectUp = vVectBody + vVect';
end

