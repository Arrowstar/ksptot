classdef SetStageActiveStateAction < AbstractEventAction
    %SetStageActiveStateAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stage(1,1) LaunchVehicleStage = LaunchVehicleStage(LaunchVehicle());
        activeStateToSet(1,1) logical = false;
    end
    
    methods
        function obj = SetStageActiveStateAction(stage, activeStateToSet)
            obj.stage = stage;
            obj.activeStateToSet = activeStateToSet;
        end
        
        function newStateLogEntry = exectuteAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry.deepCopy();
            
            stgState = newStateLogEntry.stageStates([newStateLogEntry.stageStates.stage] == obj.stage);
            stgState.active = obj.activeStateToSet;
        end
        
        function initAction(obj, initialStateLogEntry)
            %nothing
        end
        
        function name = getName(obj)
            name = 'Set Launch Vehicle Stage State';
        end
    end
end