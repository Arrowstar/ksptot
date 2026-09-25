function [datapt, depVarUnit] = lvd_SunTasks(stateLogEntry, subTask, celBodyData)
%lvd_SunTasks Sun-geometry Graphical Analysis tasks.
%   'sunPhaseAngle': angle at the spacecraft (vertex at the S/C, per the F2
%   decision) between the directions to the Sun and to the central-body
%   center, in degrees.  0 deg means the Sun and the planet center lie in
%   the same direction from the vehicle; 180 deg means the vehicle looks
%   from the Sun toward the planet center (fully lit face).  Both arms are
%   evaluated in the Sun-centered inertial frame so no frame-rotation
%   assumption is needed.
    arguments
        stateLogEntry(1,1) LaunchVehicleStateLogEntry
        subTask(1,:) char
        celBodyData
    end

    depVarUnit = 'deg';

    switch subTask
        case 'sunPhaseAngle'
            ut = stateLogEntry.time;
            bodyInfo = stateLogEntry.centralBody;

            sunBodyInfo = celBodyData.getTopLevelBody();
            sunInertFrame = sunBodyInfo.getBodyCenteredInertialFrame();

            elemSet = stateLogEntry.getCartesianElementSetRepresentation();
            elemSetSun = elemSet.convertToFrame(sunInertFrame).convertToCartesianElementSet();
            scWrtSun = elemSetSun.rVect(:);

            bodyWrtSun = getPositOfBodyWRTSun(ut, bodyInfo, celBodyData);
            bodyWrtSun = bodyWrtSun(:);

            scToSun = -scWrtSun;
            scToBody = bodyWrtSun - scWrtSun;

            if(norm(scToSun) == 0 || norm(scToBody) == 0)
                datapt = NaN;
            else
                datapt = rad2deg(dang(scToSun, scToBody));
            end

        otherwise
            error('Unrecognized sun sub-task: %s', subTask);
    end
end
