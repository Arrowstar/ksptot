function datapt = lvd_PluginVarValueTask(stateLogEntry, subTask, pluginVar, lvdData, inFrame)
%lvd_PluginVarValueTask Summary of this function goes here
%   Detailed explanation goes here
    arguments
        stateLogEntry(1,1) LaunchVehicleStateLogEntry
        subTask(1,:) char
        pluginVar(1,1) LvdPluginOptimVarWrapper
        lvdData(1,1) LvdData
        inFrame(1,1) AbstractReferenceFrame
    end

    stateLogEntry = stateLogEntry.deepCopy();
    pluginVarStates = stateLogEntry.pluginVarStates;

    pluginVars = [pluginVarStates.pluginVar];
    valuesAtState = [pluginVarStates.valueAtState];
    
    switch subTask
        case 'plugin_var_value'
            datapt = valuesAtState(pluginVars == pluginVar);
    end
end