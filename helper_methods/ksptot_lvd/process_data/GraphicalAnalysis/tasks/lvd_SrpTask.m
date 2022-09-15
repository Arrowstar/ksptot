function datapt = lvd_SrpTask(stateLogEntry, subTask, inFrame)
%lvd_SrpTask Summary of this function goes here
%   Detailed explanation goes here
    arguments
        stateLogEntry(1,1) LaunchVehicleStateLogEntry
        subTask(1,:) char
        inFrame(1,1) AbstractReferenceFrame
    end

    propObj = stateLogEntry.event.propagatorObj;
    if(isa(propObj, 'ForceModelPropagator') && ismember(ForceModelsEnum.SolarRadPress, propObj.forceModels))
        vehElemSet = stateLogEntry.getCartesianElementSetRepresentation();
    
        ut = stateLogEntry.time;
        rVect = stateLogEntry.position;
        vVect = stateLogEntry.velocity;
        bodyInfo = stateLogEntry.centralBody;
        steeringModel = stateLogEntry.steeringModel;
        
        srpForceVector = stateLogEntry.srp.getSolarRadiationForce(ut, rVect, vVect, bodyInfo, steeringModel);

        bci = bodyInfo.getBodyCenteredInertialFrame();
        R_bci_to_global_inertial = bci.getRotMatToInertialAtTime(ut,[],[]);
        [~, ~, ~, R_inFrame_to_global_inertial] = inFrame.getOffsetsWrtInertialOrigin(stateLogEntry.time, vehElemSet);
        R_bci_to_inFrame = R_inFrame_to_global_inertial' * R_bci_to_global_inertial;

        srpForceVector = R_bci_to_inFrame * srpForceVector;

    else
        srpForceVector = [0;0;0];
    end

    srpForceVector = srpForceVector * 1000^2; %convert mT*km/s^2 to N

    switch subTask
        case 'SrpForceVectX'
            datapt = srpForceVector(1); %N

        case 'SrpForceVectY'
            datapt = srpForceVector(2); %N

        case 'SrpForceVectZ'
            datapt = srpForceVector(3); %N

        case 'SrpForceVectMag'
            datapt = norm(srpForceVector); %N

        case 'SrpForceVector'
            datapt = srpForceVector;    %N

        otherwise
            error('Unrecongized task: %s', subTask);
    end
end