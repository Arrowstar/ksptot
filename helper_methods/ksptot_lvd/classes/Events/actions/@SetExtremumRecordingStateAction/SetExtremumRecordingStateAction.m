classdef SetExtremumRecordingStateAction < AbstractEventAction
    %SetExtremumRecordingStateAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        extremum LaunchVehicleExtrema
        runningStateToSet(1,1) LaunchVehicleExtremaRecordingEnum = LaunchVehicleExtremaRecordingEnum.NotRecording
    end
    
    methods
        function obj = SetExtremumRecordingStateAction(extremum, runningStateToSet)
            if(nargin > 0)
                obj.extremum = extremum;
                obj.runningStateToSet = runningStateToSet;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry;
            
            if(not(isempty(obj.extremum)))
                extremaState = newStateLogEntry.extremaStates([newStateLogEntry.extremaStates.extrema] == obj.extremum);
                extremaState.active = obj.runningStateToSet;
            end
        end
        
        function initAction(obj, initialStateLogEntry)
            %nothing
        end
        
        function name = getName(obj)
            if(not(isempty(obj.extremum)))
                nameStr = obj.extremum.getNameStr();
            else
                nameStr = '<No Extremum Selected>';
            end
            
            name = sprintf('Set Extremum State (%s = %s)', nameStr, obj.runningStateToSet.nameStr);
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
            tf = [obj.extremum] == extremum;
        end
        
        function tf = usesTankToTankConn(obj, tankToTank)
            tf = false;
        end
        
        function [tf, vars] = hasActiveOptimVar(obj)
            tf = false;
            vars = AbstractOptimizationVariable.empty(0,1);
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            %             addActionTf = lvd_EditActionSetExtremumRecordingStateGUI(action, lv);
            
            [~, extrema] = lv.getExtremaListBoxStr();
            if(not(isempty(extrema)))
                output = AppDesignerGUIOutput({false});
                lvd_EditActionSetExtremumRecordingStateGUI_App(action, lv, output);
                addActionTf = output.output{1};
            else
                addActionTf = false;
                warndlg('There are no extrema in the scenario.  Create one first.','Cannot Create Action','modal');
            end
        end
    end
end