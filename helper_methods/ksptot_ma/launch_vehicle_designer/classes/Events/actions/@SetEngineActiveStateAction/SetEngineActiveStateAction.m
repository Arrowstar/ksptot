classdef SetEngineActiveStateAction < AbstractEventAction
    %AbstractEventAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        engine(1,1) LaunchVehicleEngine = LaunchVehicleEngine(LaunchVehicleStage(LaunchVehicle(LvdData.getEmptyLvdData())));
        activeStateToSet(1,1) logical = false;
    end
    
    methods
        function obj = SetEngineActiveStateAction(engine, activeStateToSet)
            if(nargin > 0)
                obj.engine = engine;
                obj.activeStateToSet = activeStateToSet;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = exectuteAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry.deepCopy();
            stage = obj.engine.stage;
            
            stgState = newStateLogEntry.stageStates([newStateLogEntry.stageStates.stage] == stage);
            
            engineState = stgState.engineStates([stgState.engineStates.engine] == obj.engine);
            engineState.active = obj.activeStateToSet;
        end
        
        function initAction(obj, initialStateLogEntry)
            %nothing
        end
        
        function name = getName(obj)
            if(obj.activeStateToSet)
                tf = 'Active';
            else
                tf = 'Inactive';
            end
            
            name = sprintf('Set Engine State (%s = %s)',obj.engine.name,tf);
        end
        
        function tf = usesStage(obj, stage)
            tf = false;
        end
        
        function tf = usesEngine(obj, engine)
            tf = ([obj.engine] == engine);
        end
        
        function tf = usesTank(obj, tank)
            tf = false;
        end
        
        function tf = usesEngineToTankConn(obj, engineToTank)
            tf = false;
        end
        
        function tf = hasActiveOptimVar(obj)
            tf = false;
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            addActionTf = lvd_EditActionSetEngineStateGUI(action, lv);
        end
    end
end