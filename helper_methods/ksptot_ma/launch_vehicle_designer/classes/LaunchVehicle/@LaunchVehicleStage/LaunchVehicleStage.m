classdef LaunchVehicleStage < matlab.mixin.SetGet
    %LaunchVehicleStage Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        launchVehicle(1,1) LaunchVehicle = LaunchVehicle(LvdData.getEmptyLvdData())
        
        name(1,:) char = 'Untitled Stage';
        engines(1,:) LaunchVehicleEngine
        tanks(1,:) LaunchVehicleTank
        
        dryMass(1,1) double = 0; %mT
        
        id(1,1) double = 0;
    end
    
    methods
        function obj = LaunchVehicleStage(launchVehicle)
            obj.launchVehicle = launchVehicle;
            obj.id = rand();
        end
        
        function stageSummStr = getStageSummaryStr(obj)
            stageSummStr = {};
            
            propMass = obj.getStageInitPropMass();
            totalMass = obj.getStageInitTotalMass();
            
            stageSummStr{end+1} = sprintf('\t%s (Dry Mass = %0.3f mT, Prop Mass = %.3f mT, Total = %.3f mT)', obj.name, obj.dryMass, propMass, totalMass);
            
            stageSummStr{end+1} = sprintf('\t\tTanks');
            for(i=1:length(obj.tanks)) %#ok<*NO4LP>
                stageSummStr = horzcat(stageSummStr,obj.tanks(i).getTankSummaryStr()); %#ok<AGROW>
            end
            
            stageSummStr{end+1} = sprintf('\t\tEngines');
            for(i=1:length(obj.engines))
                stageSummStr = horzcat(stageSummStr,obj.engines(i).getEngineSummaryStr()); %#ok<AGROW>
            end
        end
        
        function dryMass = getStageDryMass(obj)
            dryMass = obj.dryMass;
        end
        
        function propMass = getStageInitPropMass(obj)
            propMass = 0;
            for(i=1:length(obj.tanks))
                propMass = propMass + obj.tanks(i).getInitialMass();
            end
        end
        
        function totalMass = getStageInitTotalMass(obj)
            totalMass = obj.dryMass + obj.getStageInitPropMass();
        end
        
        function tf = eq(A,B)
            tf = [A.id] == [B.id];
        end
    end
end