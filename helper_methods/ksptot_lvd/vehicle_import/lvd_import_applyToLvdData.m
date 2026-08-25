function lvdData = lvd_import_applyToLvdData(lvdData, newLv)
%lvd_import_applyToLvdData Installs an imported launch vehicle into LVD
%case data and regenerates the initial state model for it.
%
%   lvdData = lvd_import_applyToLvdData(lvdData, newLv)
%
%   NEWLV is a LaunchVehicle built by lvd_import_createLaunchVehicle. The
%   previous vehicle object is replaced; the initial state's central body
%   and time are preserved while stage/engine/tank states are rebuilt from
%   the new vehicle's defaults (all stages active, full tanks).

    if(isa(newLv, 'LaunchVehicle') && ~isempty(lvdData) && ...
       ~isempty(lvdData.launchVehicle) && ~isempty(lvdData.initStateModel))
        preservedTime = lvdData.initStateModel.time;
        preservedBody = lvdData.initStateModel.centralBody;
    else
        preservedTime = [];
        preservedBody = [];
    end

    lvdData.launchVehicle = newLv;

    if(isempty(preservedBody))
        % Fall back to the case default body.
        bodyInfo = LvdData.getDefaultInitialBodyInfo(lvdData.celBodyData);
    else
        bodyInfo = preservedBody;
    end

    lvdData.initStateModel = InitialStateModel. ...
        getDefaultInitialStateLogModelForLaunchVehicle(newLv, bodyInfo);

    if(~isempty(preservedTime))
        lvdData.initStateModel.time = preservedTime;
    end

end