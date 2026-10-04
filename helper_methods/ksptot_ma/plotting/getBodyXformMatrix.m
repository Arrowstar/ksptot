function M = getBodyXformMatrix(time, bodyInfo, viewFrame)
    bodyFixedFrame = bodyInfo.getBodyFixedFrame();
    ce = bodyInfo.getElementSetsForTimes(time);
    
    [~, ~, ~, R_BodyFixed_to_GlobalInertial] = bodyFixedFrame.getOffsetsWrtInertialOrigin(time, ce);
    [~, ~, ~, R_ViewFrame_to_GlobalInertial] = viewFrame.getOffsetsWrtInertialOrigin(time, ce);

    zRotOffset = bodyInfo.surftexturezrotoffset; %degrees
    rotMatZOffset = [cosd(zRotOffset) -sind(zRotOffset) 0; sind(zRotOffset) cosd(zRotOffset) 0; 0 0 1];
    
    R_BodyFixed_to_ViewFrame = R_ViewFrame_to_GlobalInertial' * R_BodyFixed_to_GlobalInertial;

    M33 = R_BodyFixed_to_ViewFrame * rotMatZOffset;
    axang = rotm2axangARH(M33);
    
    ce = bodyInfo.getElementSetsForTimes(time);
    ce = ce.convertToCartesianElementSet().convertToFrame(viewFrame);
    posOffset = ce.rVect;

    % A body plotted in a frame centered on itself must sit at the origin
    % by definition. The generic ephemeris path above can return a small
    % non-zero offset when two heliocentric code paths disagree (e.g. Earth
    % in bodiesSolarSystem.ini: getStateAtTime (MEX, equatorial threshold
    % 1E-4 rad) forces its 0.000418 deg osculating inclination to exactly
    % equatorial (Z=0), while getPositOfBodyWRTSun (fast chain, threshold
    % 1E-10 rad) keeps the ~611 km out-of-plane component; the difference
    % leaks into posOffset and shifts the texture sphere ~611 km off the
    % Body-Fixed grid/trajectory origin, moving 0,0 lat/long off the Gulf
    % of Guinea). Snap to the origin when the view frame is centered on
    % this body.
    try
        originBody = viewFrame.getOriginBody();
        if(isscalar(originBody) && originBody.id == bodyInfo.id)
            posOffset = [0;0;0];
        end
    catch
        % viewFrame has no single origin body; keep the computed offset.
    end
    
    M = makehgtform('translate',posOffset(:)', 'axisrotate',axang(1:3),axang(4));   
end