function [rVectDown, vVectDown] = convertRVVectOnDownwardsSoITransition(childBodyInfo, celBodyData, ut, rVect, vVect)
%convertRVVectOnDownwardsSoITransition Summary of this function goes here
%   Detailed explanation goes here

%     [rVectBody, vVectBody] = getStateGMm(childBodyInfo, ut, celBodyData);
%     rVectDown = (rVect' - rVectBody);
%     vVectDown = (vVect' - vVectBody);

%     cFrame = BodyCenteredInertialFrame(childBodyInfo, celBodyData);
    cFrame = childBodyInfo.getBodyCenteredInertialFrame();
%     pFrame = BodyCenteredInertialFrame(childBodyInfo.getParBodyInfo(),  celBodyData);
    pFrame = childBodyInfo.getParBodyInfo().getBodyCenteredInertialFrame();
    pState = CartesianElementSet(ut, rVect, vVect, pFrame);
    cState = pState.convertToFrame(cFrame);
    
    rVectDown = cState.rVect;
    vVectDown = cState.vVect;
end

