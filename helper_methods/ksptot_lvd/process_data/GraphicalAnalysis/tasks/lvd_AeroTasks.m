function datapt = lvd_AeroTasks(stateLogEntry, subTask, inFrame)
%lvd_AeroTasks Summary of this function goes here
%   Detailed explanation goes here
    arguments
        stateLogEntry(1,1) LaunchVehicleStateLogEntry
        subTask(1,:) char
        inFrame(1,1) AbstractReferenceFrame
    end

    propObj = stateLogEntry.event.propagatorObj;
    if(isa(propObj, 'ForceModelPropagator') && ismember(ForceModelsEnum.Drag, propObj.forceModels))
        ut = stateLogEntry.time;
        rVect = stateLogEntry.position;
        vVect = stateLogEntry.velocity;
        bodyInfo = stateLogEntry.centralBody;
        mass = stateLogEntry.getTotalVehicleMass();
        aero = stateLogEntry.aero;
        attState = stateLogEntry.attitude;
        celBodyData = bodyInfo.celBodyData;
    
        vehElemSet = stateLogEntry.getCartesianElementSetRepresentation();
        
        maStateLogEntry = [ut, rVect(:)', vVect(:)', bodyInfo.id, mass, 0, 0, 0, -1];
        altitude = ma_GALongLatAltTasks(maStateLogEntry, 'alt', celBodyData);
        vVectEcefMag = ma_GALongLatAltTasks(maStateLogEntry, 'bodyFixedVNorm', celBodyData);
        [lat, long, ~, ~, ~, ~, ~, ~] = getLatLongAltFromInertialVect(ut, rVect, bodyInfo, vVect);
        [density, pressureKPA, ~] = getAtmoDensityAtAltitude(bodyInfo, altitude, lat, ut, long); 
        [~,angOfAttack,angOfSideslip,totalAoA] = attState.getAeroAngles(ut, rVect, vVect, bodyInfo);
    
        dragForceModel = DragForceModel();
        dragForceVect = dragForceModel.getForce(ut, rVect, vVect, mass, bodyInfo, aero, [], [], [], [], [], [], [], [], [], [], attState); %drag force in body centered frame
    
        bci = bodyInfo.getBodyCenteredInertialFrame();
        R_bci_to_global_inertial = bci.getRotMatToInertialAtTime(ut,[],[]);
        [~, ~, ~, R_inFrame_to_global_inertial] = inFrame.getOffsetsWrtInertialOrigin(stateLogEntry.time, vehElemSet);
        R_bci_to_inFrame = R_inFrame_to_global_inertial' * R_bci_to_global_inertial;
    
        dragForceVect = R_bci_to_inFrame * dragForceVect;
        dragForceVect = 1000*dragForceVect; %kN
        
    else
        dragForceVect = [0;0;0];
    end

    switch subTask            
        case 'dragCoeff'
            datapt = stateLogEntry.aero.getDragCoeff(ut, rVect, vVect, bodyInfo, mass, altitude, pressureKPA, density, vVectEcefMag, totalAoA, angOfAttack, angOfSideslip);
        case 'dragForce'
            datapt = norm(dragForceVect); %kN
        case 'dragForceVector'
            datapt = dragForceVect; %kN
    end
end