classdef LaunchVehicleTank < matlab.mixin.SetGet
    %LaunchVehicleTank Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stage(1,1) LaunchVehicleStage = LaunchVehicleStage(LaunchVehicle(LvdData.getEmptyLvdData()));
        
        initialMass(1,1) double = 0; %mT
        
        name(1,:) char = 'Untitled Tank';
        id(1,1) double = 0;
    end
    
    methods
        function obj = LaunchVehicleTank(stage)
            obj.stage = stage;
            obj.id = rand();
        end
        
        function tankSummStr = getTankSummaryStr(obj)
            tankSummStr = {};
            
            tankSummStr{end+1} = sprintf('\t\t\t%s (Prop Mass = %.3f mT)', obj.name, obj.initialMass);
        end
        
        function initialMass = getInitialMass(obj)
            initialMass = obj.initialMass;
        end
        
        function tf = eq(A,B)
            tf = [A.id] == [B.id];
        end
    end
end