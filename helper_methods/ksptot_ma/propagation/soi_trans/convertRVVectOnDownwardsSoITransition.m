function [rVectDown, vVectDown] = convertRVVectOnDownwardsSoITransition(childBodyInfo, celBodyData, ut, rVect, vVect)
%convertRVVectOnDownwardsSoITransition Summary of this function goes here
%   Detailed explanation goes here

    [rVectBody, vVectBody] = getStateGMm(childBodyInfo, ut, celBodyData);
    rVectDown = (rVect' - rVectBody);
    vVectDown = (vVect' - vVectBody);
end

