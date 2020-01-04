function tf = isVarInLaunchVehicle(var, lvdData)
    lv = lvdData.launchVehicle;
    [lvVars,~] = lv.getActiveOptVars();
    
    tf = false;
    for(i=1:length(lvVars))
        lvVar = lvVars(i);
        
        if(var == lvVar)
            tf = true;
            break;
        end
    end
end