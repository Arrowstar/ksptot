function [datapt, unitStr] = lvd_ElectricalPowerSrcTasks(stateLogEntry, subTask, powerSrc)
%lvd_ElectricalPowerSrcTasks Summary of this function goes here
%   Detailed explanation goes here

    pwrSrcStates = stateLogEntry.getAllActivePwrSrcsStates();
    
    pwrSrcState = AbstractLaunchVehicleElectricalPowerSrcState.empty(1,0);
    for(i=1:length(pwrSrcStates))
        if(pwrSrcStates(i).getEpsSrcComponent() == powerSrc)
            pwrSrcState = pwrSrcStates(i);
            break;
        end
    end
    
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
                datapt = pwrSrcState.getElectricalPwrRate(elemSet, steeringModel, [], []);
                
                if(isempty(datapt))
                    datapt = -1;
                end
                
                unitStr = '';
            else
                datapt = -1;
                unitStr = '';
            end
            
        otherwise
            error('Unknow EPS source task: %s', subTask);            
    end
end