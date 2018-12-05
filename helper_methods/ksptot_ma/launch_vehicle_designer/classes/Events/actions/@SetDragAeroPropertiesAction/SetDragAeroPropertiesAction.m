classdef SetDragAeroPropertiesAction < AbstractEventAction
    %SetDragAeroPropertiesAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        CdToSet(1,1) double = 0;
        areaToSet(1,1) double = 0;
    end
    
    methods
        function obj = SetDragAeroPropertiesAction(CdToSet, areaToSet)
            if(nargin > 0)
                obj.CdToSet = CdToSet;
                obj.areaToSet = areaToSet;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry.deepCopy();
            
            newStateLogEntry.aero.Cd = obj.CdToSet;
            newStateLogEntry.aero.area = obj.areaToSet;
        end
        
        function initAction(obj, initialStateLogEntry)
            %none
        end
        
        function name = getName(obj)           
            name = 'Set Drag Aero Properties';
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
        
        function [tf, vars] = hasActiveOptimVar(obj)
            tf = false;
            vars = AbstractOptimizationVariable.empty(0,1);
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            fakeLvdData = LvdData.getDefaultLvdData(lv.lvdData.celBodyData);
            
            initStateModel = fakeLvdData.initStateModel;
            initStateModel.aero.area = action.areaToSet;
            initStateModel.aero.Cd = action.CdToSet;
            
            [addActionTf, Cd, area] = lvd_EditDragPropertiesGUI(fakeLvdData);
            if(addActionTf)
                action.CdToSet = Cd;
                action.areaToSet = area;
            end
        end
    end
end