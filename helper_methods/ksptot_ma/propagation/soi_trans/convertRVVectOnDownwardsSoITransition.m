function [rVectDown, vVectDown] = convertRVVectOnDownwardsSoITransition(childBodyInfo, parentBodyInfo, ut, rVect, vVect)
%convertRVVectOnDownwardsSoITransition Summary of this function goes here
%   Detailed explanation goes here

    [rVectBody, vVectBody] = getStateAtTime(childBodyInfo, ut, parentBodyInfo.gm);
    rVectDown = (rVect' - rVectBody);
    vVectDown = (vVect' - vVectBody);
end

