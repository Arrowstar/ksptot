classdef LaunchVehicleSimplePwrSink < AbstractLaunchVehicleElectricalPowerSrcSnk
    %LaunchVehicleSimplePwrSink Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stage LaunchVehicleStage
        
        name(1,:) char  = 'Untitled Power Sink';
        pwrRate(1,1) double = 0;
        
        id = rand();
    end
    
    methods
        function obj = LaunchVehicleSimplePwrSink(stage)
            obj.stage = stage;
            
            obj.id = rand();
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function stage = getAttachedStage(obj)
            stage = obj.stage;
        end
        
        function pwrRate = getElectricalPwrRate(obj, ~, ~, ~, ~, ~)
            pwrRate = obj.pwrRate;
        end
        
        function newState = createDefaultInitialState(obj, stageState)
            newState = LaunchVehicleSimplePwrSinkState(stageState, obj);
        end
        
        function useTF = openEditDialog(obj)
%             useTF = lvd_EditSimplePowerSinkGUI(obj);
            
            output = AppDesignerGUIOutput({false});
            lvd_EditSimplePowerSinkGUI_App(obj, output);
            useTF = output.output{1};
        end
        
        function tf = isInUse(obj)
            tf = false;
        end
        
        function newPowerSink = copy(obj)
            newPowerSink = LaunchVehicleSimplePwrSink(obj.stage);
            
            newPowerSink.pwrRate = obj.pwrRate;            
            newPowerSink.name = sprintf('Copy of %s', obj.name);
        end
        
        function summStr = getSummaryStr(obj)
            summStr = {};
            
            summStr{end+1} = sprintf('\t\t\t%s', obj.name);
            summStr{end+1} = sprintf('\t\t\t\tDischarge Rate = %.3f EC/s', obj.pwrRate);
        end
    end
end