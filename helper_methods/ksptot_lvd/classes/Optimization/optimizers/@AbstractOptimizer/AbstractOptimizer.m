classdef(Abstract) AbstractOptimizer < matlab.mixin.SetGet
    %AbstractOptimizer Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        optimize(obj, lvdOpt, writeOutput);
        
        options = getOptions(obj);
        
        openOptionsDialog(obj);
    end
    
    methods(Static, Access=protected)
        function evtNumToStartScriptExecAt = getEvtNumToStartScriptExecAt(lvdOptim, actVars)
            evtNumToStartScriptExecAt = lvdOptim.lvdData.script.getTotalNumOfEvents();
            for(i=1:length(actVars)) %#ok<*NO4LP>
                var = actVars(i);
                
                if(isVarInLaunchVehicle(var, lvdOptim.lvdData) || isVarInLaunchVehicle(var, lvdOptim.lvdData))
                    varEvtNum = 1;
                else
                    varEvtNum = getEventNumberForVar(var, lvdOptim.lvdData);
                    
                    if(isempty(varEvtNum))
                        varEvtNum = 1;
                    end
                end
                
                if(varEvtNum < evtNumToStartScriptExecAt)
                    evtNumToStartScriptExecAt = varEvtNum;
                end
                
                if(evtNumToStartScriptExecAt == 1)
                    break; %it can't go lower than 1, so we're executing the whole thing.  No reason to keep going.
                end
            end
        end
    end
end

