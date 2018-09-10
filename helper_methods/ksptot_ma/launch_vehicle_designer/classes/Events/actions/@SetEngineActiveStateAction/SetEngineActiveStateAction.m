classdef SetEngineActiveStateAction < AbstractEventAction
    %AbstractEventAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        engine(1,1) LaunchVehicleEngine = LaunchVehicleEngine(LaunchVehicleStage(LaunchVehicle()));
        activeStateToSet(1,1) logical = false;
    end
    
    methods
        function obj = SetEngineActiveStateAction(engine, activeStateToSet)
            obj.engine = engine;
            obj.activeStateToSet = activeStateToSet;
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
            name = 'Set Launch Vehicle Engine State';
        end
    end
end