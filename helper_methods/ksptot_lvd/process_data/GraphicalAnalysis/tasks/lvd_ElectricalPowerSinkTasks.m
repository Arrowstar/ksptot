function [datapt, unitStr] = lvd_ElectricalPowerSinkTasks(stateLogEntry, subTask, pwrSink)
%lvd_ElectricalPowerSinkTasks Summary of this function goes here
%   Detailed explanation goes here
    stageStates = stateLogEntry.stageStates;
    
    pwrSinkStates = AbstractLaunchVehicleElectricalPowerSnkState.empty(1,0);
    for(i=1:length(stageStates)) %#ok<*NO4LP>
        pwrSinkStates = horzcat(pwrSinkStates, stageStates(i).powerSinkStates); %#ok<AGROW>
    end
    
    pwrSinks = AbstractLaunchVehicleElectricalPowerSrcSnk.empty(1,0);
    for(i=1:length(pwrSinkStates))
        pwrSinks = horzcat(pwrSinks, pwrSinkStates(i).getEpsSinkComponent()); %#ok<AGROW>
    end
    
    pwrSinkInd = find(pwrSinks == pwrSink,1,'first');
    pwrSinkState = pwrSinkStates(pwrSinkInd);
    
    switch subTask
        case 'active'           
            if(not(isempty(pwrSinkState)))
                pwrSinkState = pwrSinkState(1);
                datapt = pwrSinkState.getActiveState();
                
                if(isempty(datapt))
                    datapt = -1;
                end
                
                unitStr = '';
            else
                datapt = -1;
                unitStr = '';
            end
            
        case 'dischargeRate'
            if(not(isempty(pwrSinkState)))
                pwrSinkState = pwrSinkState(1);
                
                elemSet = stateLogEntry.getCartesianElementSetRepresentation();
                steeringModel = stateLogEntry.steeringModel;
                datapt = pwrSinkState.getElectricalPwrRate(elemSet, steeringModel, [], [], []);
                
                if(isempty(datapt))
                    datapt = -1;
                end
                
                unitStr = 'EC/s';
            else
                datapt = -1;
                unitStr = 'EC/s';
            end
            
        otherwise
            error('Unknow EPS sink task: %s', subTask);            
    end
end