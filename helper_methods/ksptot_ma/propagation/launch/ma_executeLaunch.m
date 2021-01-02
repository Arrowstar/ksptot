function eventLog = ma_executeLaunch(initialState, launchEvent, celBodyData)
%ma_executeLaunch Summary of this function goes here
%   Detailed explanation goes here

    if(isempty(initialState))
        bodyInfo = getBodyInfoByNumber(launchEvent.bodyId, celBodyData);
        
        initTime = launchEvent.launchValue(1);
        LLA1 = [launchEvent.launchValue(2), launchEvent.launchValue(3), launchEvent.launchValue(4)];
    else
        initTime = initialState(1);
        rVect = initialState(2:4)';
        vVect = initialState(5:7)';
        bodyId = initialState(8);        
        
        bodyInfo = getBodyInfoByNumber(bodyId, celBodyData);
        
        [lat, long, alt, ~, ~, ~] = getLatLongAltFromInertialVect(initTime, rVect, bodyInfo, vVect);
        
        LLA1 = [lat, long, alt];
    end

    LLA2 = [launchEvent.launchValue(6), launchEvent.launchValue(7), launchEvent.launchValue(8)];
    tof = launchEvent.launchValue(5);
    
    eventLog = computeLaunchTrajectory(LLA1, initTime, LLA2, tof, bodyInfo);
end

function eventLog = computeLaunchTrajectory(LLA1, initTime, LLA2, tof, bodyInfo)
    rBody = bodyInfo.radius;
    gmu = bodyInfo.gm;

    %%% Starting Conditions %%%
    lat1 = LLA1(1);   %deg
    long1 = LLA1(2);  %deg
    alt1 = LLA1(3);   %km
    t1 = initTime;    %sec

    %%% Burnout Conditions %%%
    lat2 = LLA2(1);        %deg
    long2 = LLA2(2);         %deg
    alt2 = LLA2(3);     %km

    %%%%%%%%%%%% Output %%%%%%%%%%%%%%%%%%%%
    r1 = getInertialVectFromLatLongAlt(initTime, lat1, long1, alt1, bodyInfo, [NaN;NaN;NaN]);
    r2 = getInertialVectFromLatLongAlt(initTime+tof, lat2, long2, alt2, bodyInfo, [NaN;NaN;NaN]);
%     [x1,y1,z1] = sph2cart(deg2rad(long1),deg2rad(lat1),rBody);
%     [x2,y2,z2] = sph2cart(deg2rad(long2),deg2rad(lat2),rBody);
%     r1 = [x1,y1,z1]';
%     r2 = [x2,y2,z2]';
    startEndDAng = atan2(norm(cross(r1,r2)),dot(r1,r2));
    downrange = startEndDAng * rBody;

    a = downrange;
    b = alt2 - alt1;

    t = linspace(pi,pi/2,100);
    x = a + a*cos(t);
    y = alt1 + b*sin(t);

    arcDr = x/rBody;
    radius = y + rBody;

    rotAx = cross(r1,r2);
    rotAx = rotAx/norm(rotAx);

    r = repmat(rotAx, [1, length(arcDr)]);
    r(4,:) = arcDr;

    posVects = zeros(3,size(r,2));

    r1Unit = r1/norm(r1);
    r2Unit = r2/norm(r2);
    for(i=1:size(r,2)) %#ok<NO4LP>
        rotMat = vrrotvec2mat(r(:,i));
        posVects(:,i) = (rotMat * r1Unit) * (rBody + y(i));
    end

    t_p = (tof/(pi/2))*t - tof;
    t_p = t1 + t_p(end:-1:1);

    iniSpeed = cos(lat1) * (2*pi*(rBody+alt1))/(bodyInfo.rotperiod);
    
    finalCircSpeed = sqrt(gmu/(alt2 + rBody));
    finalCircVelUnitVector = cross(rotAx,r2Unit);
    finalCircVelVector = finalCircSpeed * finalCircVelUnitVector;

    speeds = interp1([initTime,initTime+tof], [iniSpeed, finalCircSpeed], t_p,'linear','extrap');
    
    velVects = zeros(3,size(r,2));
    velVects(:,1:end-1) = bsxfun(@rdivide, posVects(:,2:end) - posVects(:,1:end-1), t_p(2:end) - t_p(1:end-1));
    velVects(:,end) = finalCircVelVector;
    
    velVectsUnit = bsxfun(@rdivide, velVects, sqrt(sum(velVects.^2,1)));
    velVects = bsxfun(@times, speeds, velVectsUnit);

    eventLog = horzcat(t_p', posVects', velVects');
end