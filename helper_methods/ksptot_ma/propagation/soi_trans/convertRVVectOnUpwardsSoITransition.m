function [rVectUp, vVectUp] = convertRVVectOnUpwardsSoITransition(bodyInfo, celBodyData, ut, rVect, vVect)
%convertRVVectOnUpwardsSoITransition Summary of this function goes here
%   Detailed explanation goes here

%     [rVectBody, vVectBody] = getStateGMm(bodyInfo, ut, celBodyData);
%     rVectUp = rVectBody + rVect';
%     vVectUp = vVectBody + vVect';

%     cFrame = BodyCenteredInertialFrame(bodyInfo, celBodyData);
    cFrame = bodyInfo.getBodyCenteredInertialFrame();
%     pFrame = BodyCenteredInertialFrame(bodyInfo.getParBodyInfo(),  celBodyData);
    pFrame = bodyInfo.getParBodyInfo().getBodyCenteredInertialFrame();
    cState = CartesianElementSet(ut, rVect, vVect, cFrame);
    pState = cState.convertToFrame(pFrame);
    
    rVectUp = pState.rVect;
    vVectUp = pState.vVect;
end

