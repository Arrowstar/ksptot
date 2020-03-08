classdef SetDragAeroPropertiesAction < AbstractEventAction
    %SetDragAeroPropertiesAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties       
        %area
        areaToSet(1,1) double = 0;
        
        %drag
        CdInterpToSet
        CdIndepVarToSet(1,1) AeroIndepVar = AeroIndepVar.Altitude;
        CdInterpMethodToSet (1,1) GriddedInterpolantMethodEnum = GriddedInterpolantMethodEnum.Linear;
        CdInterpPtsToSet
    end
    
    %deprecated
    properties
        CdToSet(1,1) double = 0.3;
    end
    
    methods
        function obj = SetDragAeroPropertiesAction(areaToSet, CdInterpToSet, CdIndepVarToSet, CdInterpMethodToSet, CdInterpPtsToSet)
            if(nargin > 0)
                obj.CdInterpToSet = CdInterpToSet;
                obj.CdIndepVarToSet = CdIndepVarToSet;
                obj.CdInterpMethodToSet = CdInterpMethodToSet;
                obj.CdInterpPtsToSet = CdInterpPtsToSet;
                
                obj.areaToSet = areaToSet;
            else
                obj.CdInterpMethodToSet = GriddedInterpolantMethodEnum.Linear;

                pointSet = GriddedInterpolantPointSet();
                obj.CdInterpPtsToSet = pointSet;

                pointSet.addPoint(GriddedInterpolantPoint(0,0.3));
                pointSet.addPoint(GriddedInterpolantPoint(1,0.3));
                obj.CdInterpToSet = pointSet.getGriddedInterpFromPoints(obj.CdInterpMethod, GriddedInterpolantMethodEnum.Nearest);
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry;
            
            newStateLogEntry.aero.area = obj.areaToSet;
            newStateLogEntry.aero.CdInterp = obj.CdInterpToSet;
            newStateLogEntry.aero.CdIndepVar = obj.CdIndepVarToSet;
            newStateLogEntry.aero.CdInterpMethod = obj.CdInterpMethodToSet;
            newStateLogEntry.aero.CdInterpPts = obj.CdInterpPtsToSet;
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
            fakeLvdData = LvdData.getDefaultLvdData(lv.lvdData.celBodyData);
            
            initStateModel = fakeLvdData.initStateModel;
            
            initStateModel.aero.area = action.areaToSet;
            initStateModel.aero.CdInterp = action.CdInterpToSet;
            initStateModel.aero.CdIndepVar = action.CdIndepVarToSet;
            initStateModel.aero.CdInterpMethod = action.CdInterpMethodToSet;
            initStateModel.aero.CdInterpPts = action.CdInterpPtsToSet;
            
            [addActionTf, aero, area] = lvd_EditDragPropertiesGUI(fakeLvdData);
            if(addActionTf)
                action.areaToSet = area;
                
                action.CdInterpToSet = aero.CdInterp;
                action.CdIndepVarToSet = aero.CdIndepVar;
                action.CdInterpMethodToSet = aero.CdInterpMethod;
                action.CdInterpPtsToSet = aero.CdInterpPts;
            end
        end
        
        function obj = loadobj(obj)
            if(isempty(obj.CdInterpToSet))
                pointSet = GriddedInterpolantPointSet();
                obj.CdInterpMethodToSet = GriddedInterpolantMethodEnum.Linear;
                
                pointSet.addPoint(GriddedInterpolantPoint(0,obj.CdToSet));
                pointSet.addPoint(GriddedInterpolantPoint(1,obj.CdToSet));
                obj.CdInterpToSet = pointSet.getGriddedInterpFromPoints(obj.CdInterpMethodToSet, GriddedInterpolantMethodEnum.Nearest);
                obj.CdInterpPtsToSet = pointSet;
            end
        end
    end
end