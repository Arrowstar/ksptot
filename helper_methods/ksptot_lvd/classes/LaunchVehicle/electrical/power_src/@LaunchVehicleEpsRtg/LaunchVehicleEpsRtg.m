classdef LaunchVehicleEpsRtg < AbstractLaunchVehicleElectricalPowerSrcSnk
    %LaunchVehicleEpsRtg Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stage LaunchVehicleStage
        
        name(1,:) char  = 'Untitled RTG';
        pwrRate(1,1) double = 0;
        
        id = rand();
    end
    
    methods
        function obj = LaunchVehicleEpsRtg(stage)
            obj.stage = stage;
            
            obj.id = rand();
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function stage = getAttachedStage(obj)
            stage = obj.stage;
        end
        
        function newState = createDefaultInitialState(obj, stageState)
            newState = LaunchVehicleEpsRtgState(stageState, obj);
        end
        
        function useTF = openEditDialog(obj)
            useTF = lvd_EditPowerRtgGUI(obj);
        end
        
        function tf = isInUse(obj)
            tf = false;
        end
        
        function newPowerSrc = copy(obj)
            newPowerSrc = LaunchVehicleEpsRtg(obj.stage, obj.pwrRate);
            newPowerSrc.pwrRate = obj.pwrRate;
            
            newPowerSrc.name = sprintf('Copy of %s', obj.name);
        end
        
        function pwrRate = getElectricalPwrRate(obj, ~, ~, ~, ~)
            pwrRate = obj.pwrRate;
        end
        
        function summStr = getSummaryStr(obj)
            summStr = {};
            
            summStr{end+1} = sprintf('\t\t\t%s', obj.name);
            summStr{end+1} = sprintf('\t\t\t\tCharge Rate = %.3f EC/s', obj.pwrRate);
        end
    end
end