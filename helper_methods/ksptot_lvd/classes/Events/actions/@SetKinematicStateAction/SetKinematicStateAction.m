classdef SetKinematicStateAction < AbstractEventAction
    %SetTimePositionVelocityMassStateAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        orbitModel(1,1) AbstractElementSet = KeplerianElementSet.getDefaultElements();
        inheritTime(1,1) = false;
        inheritPosVel(1,1) = false;
        
        optVar SetKinematicStateActionVariable
    end
    
    properties(Dependent)
        time(1,1) double
        centralBody(1,1) KSPTOT_BodyInfo
    end
    
    methods
        function obj = SetKinematicStateAction(orbitModel)
            if(nargin > 0)
                obj.orbitModel = orbitModel;
            end
            
            obj.id = rand();
        end
        
        function time = get.time(obj)
            time = obj.orbitModel.time;
        end
        
        function set.time(obj, newTime)
            obj.orbitModel.time = newTime;
        end
        
        function time = get.centralBody(obj)
            time = obj.orbitModel.frame.getOriginBody();
        end
        
        function set.centralBody(obj, newCentralBody)
            obj.orbitModel.frame.setOriginBody(newCentralBody);
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry;

            if(obj.inheritTime == false)
                 newStateLogEntry.time = obj.orbitModel.time;
            end
            
            if(obj.inheritPosVel == false)
                cartElemSet = obj.orbitModel.convertToCartesianElementSet();
                rVect = cartElemSet.rVect;
                vVect = cartElemSet.vVect;
                bodyInfo = cartElemSet.frame.getOriginBody();
                
                newStateLogEntry.position = rVect;
                newStateLogEntry.velocity = vVect;
                newStateLogEntry.centralBody = bodyInfo;
            end
        end
        
        function initAction(obj, initialStateLogEntry)
            %nothing
        end
        
        function name = getName(obj)
            name = 'Set Kinematic State';
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
        
        function tf = usesStopwatch(obj, stopwatch)
            tf = false;
        end
        
        function tf = usesExtremum(obj, extremum)
            tf = false;
        end
        
        function tf = usesTankToTankConn(obj, tankToTank)
            tf = false;
        end
        
        function [tf, vars] = hasActiveOptimVar(obj)
            tf = false;
            vars = AbstractOptimizationVariable.empty(0,1);
            
            if(not(isempty(obj.optVar)))
                tf = any(obj.optVar.getUseTfForVariable());
                vars(end+1) = obj.optVar;
            end
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            addActionTf = lvd_EditActionSetKinematicStateGUI(action, lv.lvdData);
        end
    end
end