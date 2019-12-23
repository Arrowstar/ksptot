classdef LaunchVehicleTank < matlab.mixin.SetGet
    %LaunchVehicleTank Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stage LaunchVehicleStage
        initialMass(1,1) double = 0; %mT
        name char = 'Untitled Tank';
        tankType TankFluidType = TankFluidType.empty(1,0);
        
        id(1,1) double = 0;
        optVar StageTankInitMassOptimVar
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
        
        function tankType = get.tankType(obj)
            if(not(isempty(obj.tankType)))
                tankType = obj.tankType;
            else
                tankType = obj.lvdData.launchVehicle.tankTypes.getTypeForInd(1);
                obj.tankType = tankType;
            end
        end
        
        function tankSummStr = getTankSummaryStr(obj)
            tankSummStr = {};
            
            tankSummStr{end+1} = sprintf('\t\t\t%s (Prop Mass = %.3f mT)', obj.name, obj.initialMass);
            tankSummStr{end+1} = sprintf('\t\t\t\tFluid Type: %s', obj.tankType.name);
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