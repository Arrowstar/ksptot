function [gammaAngle, betaAngle, alphaAngle] = getAnglesFromInertialBodyAxes_Func(dcm, ut, rVect, vVect, bodyInfo, baseFrame)
    ce = CartesianElementSet(ut, rVect(:), vVect(:), bodyInfo.getBodyCenteredInertialFrame());
    [~, ~, ~, base_frame_2_inertial] = baseFrame.getOffsetsWrtInertialOrigin(ut, ce);

    angles = rotm2eulARH(base_frame_2_inertial' * dcm, 'zyx');

    angles = real(angles);

    gammaAngle = angles(3);
    betaAngle = angles(2);
    alphaAngle = angles(1);
end