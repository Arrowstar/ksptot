classdef LaunchVehicleExtremaState < matlab.mixin.SetGet & matlab.mixin.Copyable
    %LaunchVehicleExtremaState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        extrema LaunchVehicleExtrema
        value(1,1) double = NaN;
        active(1,1) LaunchVehicleExtremaRecordingEnum = LaunchVehicleExtremaRecordingEnum.Recording;
    end
    
    methods
        function obj = LaunchVehicleExtremaState(extrema)
            obj.extrema = extrema;
        end
        
        function val = getValue(obj)
            val = obj.value;
        end
                
        function [newValue] = updateExtremaStateWithStateLogEntry(obj, stateLogEntry, prevValue)    
            if(obj.active == LaunchVehicleExtremaRecordingEnum.Recording) %if it's not recording, then we can just return the exState as it is b/c it won't change                
                i = 1;
                maSubLog = stateLogEntry.getMAFormattedStateLogMatrix();
                taskStr = obj.extrema.quantStr;
                prevDistTraveled = 0;
                refBodyId = obj.extrema.refBody.id;
                otherSCId = [];
                stationID = [];
                propNames = obj.extrema.lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();
%                 propNames = {'Liquid Fuel/Ox','Monopropellant','Xenon'};
                celBodyData = obj.extrema.lvdData.celBodyData;

                [depVarValue, depVarUnit, ~] = ma_getDepVarValueUnit(i, maSubLog, taskStr, prevDistTraveled, refBodyId, otherSCId, stationID, propNames, [], celBodyData, false);
                
%                 ow = false;
                if(isempty(obj.value))
                    obj.value = depVarValue;
                else
                    if(obj.extrema.type == LaunchVehicleExtremaTypeEnum.Maximum)
                        if(isnan(prevValue) || prevValue < depVarValue)
                            obj.value = depVarValue;
%                             ow = true;
                        else
                            obj.value = prevValue;
%                             ow = false;
                        end
                    elseif(obj.extrema.type == LaunchVehicleExtremaTypeEnum.Minimum)
                        if(isnan(prevValue) || prevValue > depVarValue)
                            obj.value = depVarValue;
                        else
                            obj.value = prevValue;
                        end
                    end
                end
                
%                 fprintf('%.3f --- %.3f --- %.0f\n', prevValue, obj.value, ow);
                newValue = obj.value;

                if(isempty(obj.extrema.unitStr))
                    obj.extrema.unitStr = depVarUnit;
                end
            else
                newValue = obj.value;
            end
        end
    end
    
    methods(Access=protected)
        function copyObj = copyElement(obj)
            copyObj = copyElement@matlab.mixin.Copyable(obj);
        end
    end
end