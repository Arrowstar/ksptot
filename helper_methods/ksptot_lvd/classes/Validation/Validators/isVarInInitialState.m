function tf = isVarInInitialState(var, lvdData)
    initStateModel = lvdData.initStateModel;
    initStateModelOptVars = initStateModel.getAllOptVars();
    
    tf = false;
    for(i=1:length(initStateModelOptVars))
        isVar = initStateModelOptVars(i);

        if(var == isVar)
            tf = true;
            break;
        end
    end
end