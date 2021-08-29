classdef SetThirdBodyGravitySourcesAction < AbstractEventAction
    %ResetExtremumValueAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bodiesToSet KSPTOT_BodyInfo = KSPTOT_BodyInfo.empty(1,0); %an array of bodies
    end
    
    methods
        function obj = SetThirdBodyGravitySourcesAction()
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry;
            
            newStateLogEntry.thirdBodyGravity.bodies = obj.bodiesToSet;
        end
        
        function initAction(obj, initialStateLogEntry)
            %nothing
        end
        
        function name = getName(obj)                        
            name = sprintf('Set 3rd Body Gravity Sources');
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
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
%             addActionTf = lvd_EditActionSetThirdBodyGravitySourcesGUI(action, lv);

            output = AppDesignerGUIOutput({false});
            lvd_EditActionSetThirdBodyGravitySourcesGUI_App(action, lv, output);
            addActionTf = output.output{1};
        end
    end
end