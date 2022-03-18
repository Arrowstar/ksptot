classdef LaunchVehicleStaticSolarPanel < AbstractLaunchVehicleSolarPanel
    %LaunchVehicleStaticSolarPanel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stage LaunchVehicleStage
        
        name(1,:) char  = 'Untitled Fixed Solar Panel';
        
        bodyFrameNormVect(3,1) double = [0;1;0];
        refChargeRate(1,1) double = 0;
        refChargeRateDist(1,1) = 13599840.256;
        
        id = rand();
    end
    
    methods            
        function obj = LaunchVehicleStaticSolarPanel(stage)
            obj.stage = stage;
            
            obj.id = rand();
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function stage = getAttachedStage(obj)
            stage = obj.stage;
        end
        
        function srcState = createDefaultInitialState(obj, stageState)
            srcState = LaunchVehicleStaticSolarPanelState(stageState, obj);
        end
        
        function useTF = openEditDialog(obj)
%             useTF = lvd_EditFixedSolarPanelGUI(obj);
            
            output = AppDesignerGUIOutput({false});
            lvd_EditFixedSolarPanelGUI_App(obj, output);
            useTF = output.output{1};
        end
        
        function tf = isInUse(obj)
            tf = false;
        end
        
        function newPowerSrc = copy(obj)
            newPowerSrc = LaunchVehicleStaticSolarPanel(obj.stage);
            newPowerSrc.bodyFrameNormVect = obj.bodyFrameNormVect;
            newPowerSrc.refChargeRate = obj.refChargeRate;
            newPowerSrc.refChargeRateDist = obj.refChargeRateDist;
       
            newPowerSrc.name = sprintf('Copy of %s', obj.name);
        end
        
        function summStr = getSummaryStr(obj)
            summStr = {};
            
            summStr{end+1} = sprintf('\t\t\t%s', obj.name);
            summStr{end+1} = sprintf('\t\t\t\tRef. Charge Rate = %.3f EC/s', obj.refChargeRate);
            summStr{end+1} = sprintf('\t\t\t\tRef. Distance = %.3f km', obj.refChargeRateDist);
            summStr{end+1} = sprintf('\t\t\t\tNormal Vector = [%.3f, %.3f, %.3f]', obj.bodyFrameNormVect(1), obj.bodyFrameNormVect(2), obj.bodyFrameNormVect(3));
        end
        
        function bodyFrameNormVect = getBodyFrameSolarPanelNormalVector(obj, ~, ~, ~, ~)
            bodyFrameNormVect = obj.bodyFrameNormVect;
        end
        
        function refChargeRate = getRefChargeRate(obj)
            refChargeRate = obj.refChargeRate;
        end
        
        function refChargeRateDist = getRefChargeRateDist(obj)
            refChargeRateDist = obj.refChargeRateDist;
        end
    end
end