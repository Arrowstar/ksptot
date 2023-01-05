function [datapt, unitStr] = lvd_ElectricalPowerSrcTasks(stateLogEntry, subTask, powerSrc)
%lvd_ElectricalPowerSrcTasks Summary of this function goes here
%   Detailed explanation goes here
    stageStates = stateLogEntry.stageStates;

    pwrSrcStates = AbstractLaunchVehicleElectricalPowerSrcState.empty(1,0);
    for(i=1:length(stageStates)) %#ok<*NO4LP>
        pwrSrcStates = horzcat(pwrSrcStates, stageStates(i).powerSrcStates); %#ok<AGROW>
    end
        
    pwrSrcs = AbstractLaunchVehicleElectricalPowerSrcSnk.empty(1,0);
    for(i=1:length(pwrSrcStates))
        pwrSrcs = horzcat(pwrSrcs, pwrSrcStates(i).getEpsSrcComponent()); %#ok<AGROW>
    end
    
    pwrSrcInd = find(pwrSrcs == powerSrc,1,'first');
    pwrSrcState = pwrSrcStates(pwrSrcInd);
    
    switch subTask
        case 'active'           
            if(not(isempty(pwrSrcState)))
                pwrSrcState = pwrSrcState(1);
                datapt = pwrSrcState.getActiveState();
                
                if(isempty(datapt))
                    datapt = -1;
                end
                
                unitStr = '';
            else
                datapt = -1;
                unitStr = '';
            end
            
        case 'chargeRate'
            if(not(isempty(pwrSrcState)))
                pwrSrcState = pwrSrcState(1);
                
                elemSet = stateLogEntry.getCartesianElementSetRepresentation();
                steeringModel = stateLogEntry.steeringModel;
                datapt = pwrSrcState.getElectricalPwrRate(elemSet, steeringModel, [], [], []);
                
                if(isempty(datapt))
                    datapt = -1;
                end
                
                unitStr = 'EC/s';
            else
                datapt = -1;
                unitStr = 'EC/s';
            end
            
        otherwise
            error('Unknow EPS source task: %s', subTask);            
    end
end