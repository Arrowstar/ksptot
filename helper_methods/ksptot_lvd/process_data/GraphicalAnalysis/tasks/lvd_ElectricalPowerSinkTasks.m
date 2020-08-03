function [datapt, unitStr] = lvd_ElectricalPowerSinkTasks(stateLogEntry, subTask, powerSink)
%lvd_ElectricalPowerSinkTasks Summary of this function goes here
%   Detailed explanation goes here

    pwrSinkStates = stateLogEntry.getAllActivePwrSinksStates();
    pwrSinkState = pwrSinkStates([pwrSinkStates.getEpsSinkComponent()] == powerSink);
    
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
            
        otherwise
            error('Unknow EPS sink task: %s', subTask);            
    end
end