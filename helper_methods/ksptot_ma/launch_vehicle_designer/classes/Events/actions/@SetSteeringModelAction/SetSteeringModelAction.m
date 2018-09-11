classdef SetSteeringModelAction < AbstractEventAction
    %SetSteeringModelAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        steeringModel(1,1) AbstractSteeringModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel()
    end
    
    methods
        function obj = SetSteeringModelAction(steeringModel)
            obj.steeringModel = steeringModel;
        end
        
        function newStateLogEntry = exectuteAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry.deepCopy();
            newStateLogEntry.steeringModel = obj.steeringModel;
        end
        
        function initAction(obj, initialStateLogEntry)
            t0 = initialStateLogEntry.time;
            obj.steeringModel.setT0(t0);
        end
        
        function name = getName(obj)
            name = 'Set Steering Model';
        end
    end
end