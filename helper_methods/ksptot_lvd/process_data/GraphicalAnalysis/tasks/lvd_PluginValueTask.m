function datapt = lvd_PluginValueTask(stateLogEntry, subTask, plugin, lvdData, inFrame)
%lvd_PluginValueTask Summary of this function goes here
%   Detailed explanation goes here

    stateLogEntry = stateLogEntry.deepCopy();
    
    stateLog = lvdData.stateLog;
    event = stateLogEntry.event;
    pluginSet = lvdData.plugins;
    pluginVarSet = lvdData.pluginVars;
    
    switch subTask
        case 'plugin_value'
            datapt = plugin.executePlugin(lvdData, stateLog, event, LvdPluginExecLocEnum.GraphAnalysis, [],[],[], pluginSet.userData, stateLogEntry, inFrame);

        case 'plugin_var_value'
            pluginVarSet
    end
end