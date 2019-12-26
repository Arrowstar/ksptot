classdef SetKinematicStateAction < AbstractEventAction
    %SetTimePositionVelocityMassStateAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        orbitModel(1,1) AbstractElementSet = KeplerianElementSet.getDefaultElements();
        inheritTime(1,1) = false;
        inheritPosVel(1,1) = false;
        
        optVar SetKinematicStateActionVariable
    end
    
    methods
        function obj = SetKinematicStateAction(orbitModel)
            if(nargin > 0)
                obj.orbitModel = orbitModel;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry;

            if(obj.inheritTime == false)
                time = obj.orbitModel.time;
                newStateLogEntry.time = time;
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
%             addActionTf = lvd_EditActionSetStageStateGUI(action, lv);
        end
    end
end