function R_BodyFixed_to_GlobalInertial = getBodyFixedToGlobalInertialFrame(time, spinAngle, bodyRotMatFromGlobalInertialToBodyInertial)
        axang = [repmat([0 0 1], length(time), 1), spinAngle(:)];
        R_BodyInertialFrame_to_BodyFixedFrame = pagetranspose(axang2rotmARH(axang)); %I'm not sure why this transpose is required here but I assume it has to do with the definition of the frame coming out of axang2rotm().  In any event, it's definitely needed, things get backwards without it.
        R_BodyFixed_to_GlobalInertial = pagetranspose(pagemtimes(R_BodyInertialFrame_to_BodyFixedFrame, repmat(bodyRotMatFromGlobalInertialToBodyInertial, [1 1 length(time)]))); 
end