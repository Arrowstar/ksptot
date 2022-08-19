classdef SetLiftAeroPropertiesAction < AbstractEventAction
    %SetLiftAeroPropertiesAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        liftCoeffModel LiftCoeffModel
    end

    %deprecated
    properties(Access=private)
        useLift(1,1) logical = false;
        areaLift(1,1) double = 16.2; 
        Cl_0(1,1) double = 0.731;  
        bodyLiftVect(3,1) double = [0;0;-1];
    end
    
    methods
        function obj = SetDragAeroPropertiesAction(liftCoeffModel)
            if(nargin > 0)
                obj.liftCoeffModel = liftCoeffModel;
            else
                obj.liftCoeffModel = LiftCoeffModel();
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            arguments
                obj(1,1) SetDragAeroPropertiesAction
                stateLogEntry(1,1) LaunchVehicleStateLogEntry 
            end

            newStateLogEntry = stateLogEntry;
            
            newStateLogEntry.aero.liftCoeffModel = obj.liftCoeffModel;
        end
        
        function initAction(obj, initialStateLogEntry)
            %none
        end
        
        function name = getName(obj)           
            name = 'Set Lift Aero Properties';
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
            arguments
                action(1,1) SetLiftAeroPropertiesAction
                lv(1,1) LaunchVehicle
            end

            addActionTf = action.liftCoeffModel.openEditDialog(lv.lvdData);

%             fakeLvdData = LvdData.getDefaultLvdData(lv.lvdData.celBodyData);
%             
%             initStateModel = fakeLvdData.initStateModel;
%             initStateModel.aero.useLift = action.useLift;
%             initStateModel.aero.areaLift = action.areaLift;
%             initStateModel.aero.Cl_0 = action.Cl_0;
%             initStateModel.aero.bodyLiftVect = action.bodyLiftVect;
%             
% %             [addActionTf, useLift, areaLift, Cl_0, bodyLiftVect] = lvd_EditLiftPropertiesGUI(fakeLvdData);
%             output = AppDesignerGUIOutput({false,false,false,false,false});
%             lvd_EditLiftPropertiesGUI_App(fakeLvdData, output);
%             
%             addActionTf = output.output{1};
%             useLift = output.output{2};
%             areaLift = output.output{3};
%             Cl_0 = output.output{4};
%             bodyLiftVect = output.output{5};
% 
%             if(addActionTf)
%                 action.useLift = useLift;
%                 action.areaLift = areaLift;
%                 action.Cl_0 = Cl_0;
%                 action.bodyLiftVect = bodyLiftVect;
%             end
        end
    end
end