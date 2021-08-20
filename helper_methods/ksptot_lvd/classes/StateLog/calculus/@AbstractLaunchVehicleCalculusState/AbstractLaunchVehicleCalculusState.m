classdef(Abstract) AbstractLaunchVehicleCalculusState < matlab.mixin.SetGet & matlab.mixin.Heterogeneous & matlab.mixin.Copyable
    %AbstractLaunchVehicleCalculusState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        calcObj AbstractLaunchVehicleCalculusCalc
        gridInterp griddedInterpolant = griddedInterpolant([0,1],[0 0]);
        
        testStr(1,:) char = 'Test';
    end
    
    properties(Dependent, Access=private)
        lvdData
        celBodyData
    end
    
    methods
        
        function value = get.lvdData(obj)
            value = obj.calcObj.lvdData;
        end
        
        function value = get.celBodyData(obj)
            value = obj.lvdData.celBodyData;
        end

        function createDataFromStates(obj, stateLogEntries)
            newTimes = [stateLogEntries.time];
            newDepVarValues = NaN(size(newTimes));
            
            propNames = obj.lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();
            maTaskList = ma_getGraphAnalysisTaskList(getLvdGAExcludeList());
            taskStr = obj.calcObj.quantStr;
            
            prevDistTraveled = 0;
            refBodyId = obj.calcObj.frame.getOriginBody().id;
            for(i=1:length(stateLogEntries))
                if(ismember(taskStr,maTaskList))
                    maSubLog = stateLogEntries(i).getMAFormattedStateLogMatrix(true);
                    [newDepVarValues(i), depVarUnits, prevDistTraveled] = ma_getDepVarValueUnit(1, maSubLog, taskStr, prevDistTraveled, refBodyId, [], [], propNames, [], obj.celBodyData, false);
                else
                    [newDepVarValues(i), depVarUnits] = lvd_getDepVarValueUnit(i, stateLogEntries, taskStr, refBodyId, obj.celBodyData, false, obj.calcObj.frame);
                end
            end
            
            if(isempty(obj.calcObj.unitStr))
                if(isa(obj.calcObj, 'LaunchVehicleDerivativeCalc'))
                    obj.calcObj.unitStr = sprintf('%s/s', depVarUnits);
                    
                elseif(isa(obj.calcObj, 'LaunchVehicleIntegralCalc'))
                    if(length(depVarUnits) >= 2 && strcmpi(depVarUnits(end-1:end),'/s'))
                        obj.calcObj.unitStr = depVarUnits(1:end-2);
                    else
                        obj.calcObj.unitStr = sprintf('%s*s', depVarUnits);
                    end
                else
                    error('Unknown calculus calculation object type.');
                end
            end
            
            [newTimes, ia, ~] = unique(newTimes);
            newDepVarValues = newDepVarValues(ia);
            
            if(length(newTimes) >= 2)
                obj.gridInterp = griddedInterpolant(newTimes, newDepVarValues, 'makima', 'none');
            else
%                 warning('Did not add gridded interpolant to calculus calculation, there was less than 2 states.');
            end
        end
        
        value = getValueAtTime(obj,time);
    end
    
    methods(Access=protected)
        function copyObj = copyElement(obj)
            copyObj = copyElement@matlab.mixin.Copyable(obj);
            
            for(i=1:length(obj))
                copyObj(i).calcObj = obj(i).calcObj;
            end
        end
    end
end