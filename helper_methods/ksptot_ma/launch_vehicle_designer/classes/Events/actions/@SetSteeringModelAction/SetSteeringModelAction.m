classdef SetSteeringModelAction < AbstractEventAction
    %SetSteeringModelAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        steeringModel(1,1) AbstractSteeringModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel()
    end
    
    methods
        function obj = SetSteeringModelAction(steeringModel)
            if(nargin > 0)
                obj.steeringModel = steeringModel;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = exectuteAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry.deepCopy();
            newStateLogEntry.steeringModel = obj.steeringModel;
        end
        
        function initAction(obj, initialStateLogEntry)
            t0 = initialStateLogEntry.time;
            obj.steeringModel.setT0(t0);
            
            dcm = initialStateLogEntry.attitude.dcm;
            rVect = initialStateLogEntry.position;
            vVect = initialStateLogEntry.velocity;
            obj.steeringModel.setConstsFromDcmAndContinuitySettings(dcm, rVect, vVect);
        end
        
        function name = getName(obj)
            name = sprintf('Set Steering Model (%s)', obj.steeringModel.getTypeNameStr());
        end
        
        function tf = usesStage(obj, stage)
            tf = false;
        end
        
        function tf = usesEngine(obj, engine)
            tf = false;
        end
        
        function tf = usesTank(obj, tank)
            tf = false;
        end
        
        function tf = usesEngineToTankConn(obj, engineToTank)
            tf = false;
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            addActionTf = lvd_EditActionSetSteeringModelGUI(action, lv);
        end
    end
end