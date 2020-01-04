classdef SetHoldDownClampActiveStateAction < AbstractEventAction
    %SetStageActiveStateAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        activeStateToSet(1,1) logical = false;
    end
    
    properties(Constant)
        emptyVarArr = AbstractOptimizationVariable.empty(0,1);
    end
    
    methods
        function obj = SetHoldDownClampActiveStateAction(activeStateToSet)
            if(nargin > 0)
                obj.activeStateToSet = activeStateToSet;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry;
            newStateLogEntry.lvState.holdDownEnabled = obj.activeStateToSet;
            
            if(obj.activeStateToSet == true)
                %need to set planet relative velocity to zero or it gets
                %carried by the integrator through "hold down"
                rVectECEF = getFixedFrameVectFromInertialVect(newStateLogEntry.time, newStateLogEntry.position, newStateLogEntry.centralBody);
                vVectECEF = [0;0;0];
                [~, vVectECI] = getInertialVectFromFixedFrameVect(newStateLogEntry.time, rVectECEF, newStateLogEntry.centralBody, vVectECEF);
                newStateLogEntry.velocity = vVectECI;
            end
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
            
            name = sprintf('Set Hold Down Clamp State (%s)', tf);
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
            vars = obj.emptyVarArr;
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            addActionTf = lvd_EditActionSetClampStateGUI(action);
        end
    end
end