classdef LaunchVehicleTank < matlab.mixin.SetGet
    %LaunchVehicleTank Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stage LaunchVehicleStage
        initialMass(1,1) double = 0; %mT
        capacity(1,1) double {mustBeNonnegative} = 0; %mT; maximum propellant mass the tank can hold
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
            
            tankSummStr{end+1} = sprintf('\t\t\t%s (Prop Mass = %.3f mT, Capacity = %.3f mT)', obj.name, obj.initialMass, obj.capacity);
            tankSummStr{end+1} = sprintf('\t\t\t\tFluid Type: %s', obj.tankType.name);
        end

        function initialMass = getInitialMass(obj)
            initialMass = obj.initialMass;
        end

        function capacity = getCapacity(obj)
            %getCapacity Maximum propellant mass the tank can hold, mT.  The
            %fuel-remaining percentage that drives engine throttle curves is
            %measured against it and tank-to-tank crossfeed stops when the
            %receiving tank reaches it.
            capacity = obj.capacity;
        end

        function capacity = getLegacyCapacity(obj)
            %getLegacyCapacity Capacity for a tank saved before capacities
            %existed: the initial mass reproduces the old fuel-remaining
            %percentage exactly, raised to the optimization upper bound when
            %the initial mass is an active variable so the optimizer can
            %still reach the whole range it was given.
            capacity = obj.initialMass;

            if(not(isempty(obj.optVar)) && obj.optVar.getUseTfForVariable())
                [~, ub] = obj.optVar.getAllBndsForVariable();
                if(isfinite(ub))
                    capacity = max(capacity, ub);
                end
            end
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
            newTank.capacity = obj.capacity;
            newTank.name = sprintf('Copy of %s', obj.name);
        end
        
%         function tf = eq(A,B)
%             tf = [A.id] == [B.id];
%         end

        function tf = isVarFromTank(obj, var)
            if(not(isempty(obj.optVar)))
                tf = obj.optVar == var;
            else
                tf = false;
            end
        end
    end
end