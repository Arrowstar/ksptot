classdef LaunchVehicleTank < matlab.mixin.SetGet
    %LaunchVehicleTank Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stage(1,:) LaunchVehicleStage
        
        initialMass(1,1) double = 0; %mT
        
        name(1,:) char = 'Untitled Tank';
        id(1,1) double = 0;
        
        optVar(1,:) StageTankInitMassOptimVar
    end
    
    properties(Dependent)
        lvdData
    end
    
    methods
        function obj = LaunchVehicleTank(stage)
            if(nargin>0)
                obj.stage = stage;
            end
            obj.id = rand();
        end
        
        function lvdData = get.lvdData(obj)
            lvdData = obj.stage.launchVehicle.lvdData;
        end
        
        function tankSummStr = getTankSummaryStr(obj)
            tankSummStr = {};
            
            tankSummStr{end+1} = sprintf('\t\t\t%s (Prop Mass = %.3f mT)', obj.name, obj.initialMass);
        end
        
        function initialMass = getInitialMass(obj)
            initialMass = obj.initialMass;
        end
        
        function tf = isInUse(obj)
            tf = obj.lvdData.usesTank(obj);
        end
        
        function optVar = getNewOptVar(obj)
            optVar = StageTankInitMassOptimVar(obj);
        end
        
        function optVar = getExistingOptVar(obj)
            optVar = obj.optVar;
        end
        
        function newTank = copy(obj)
            newTank = LaunchVehicleTank(obj.stage);
        
            newTank.initialMass = obj.initialMass;
            newTank.name = sprintf('Copy of %s', obj.name);
        end
        
%         function tf = eq(A,B)
%             tf = [A.id] == [B.id];
%         end
    end
end