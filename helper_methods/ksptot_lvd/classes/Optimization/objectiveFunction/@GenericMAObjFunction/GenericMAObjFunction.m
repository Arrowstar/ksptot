classdef GenericMAObjFunction < AbstractObjectiveFcn
    %GenericMAObjFunction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        objFuncType char = '';
        normFact = 1;
        event LaunchVehicleEvent
        
        refStation struct
        refOtherSC struct
        refBodyInfo KSPTOT_BodyInfo
    end
    
    methods
        function obj = GenericMAObjFunction(objFuncType, event, refStation, refOtherSC, refBodyInfo)
            obj.objFuncType = objFuncType;
            obj.event = event;
            obj.refStation = refStation;
            obj.refOtherSC = refOtherSC;
            obj.refBodyInfo = refBodyInfo; 
            
            obj.id = rand();
        end
        
        function [value, type, eventNum] = evalConstraint(obj, stateLog, celBodyData)           
            stateLogEntry = stateLog.getLastStateLogForEvent(obj.event).getMAFormattedStateLogMatrix();
            type = obj.objFuncType;
            
            if(not(isempty(obj.refBodyInfo)))
                refBodyId = obj.refBodyInfo.id;
            else
                refBodyId = [];
            end
            
            oscId = -1;
            if(not(isempty(obj.refOtherSC)))
                oscId = obj.refOtherSC.id;
            end
            
            stnId = -1;
            if(not(isempty(obj.refStation)))
                stnId = obj.refStation.id;
            end
            
            maData.spacecraft = struct();
            propNames = obj.event.lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();
            value = ma_getDepVarValueUnit(1, stateLogEntry, type, 0, refBodyId, oscId, stnId, propNames, maData, celBodyData, false);
           
            eventNum = obj.event.getEventNum();
        end
        
        function sF = getScaleFactor(obj)
            sF = obj.normFact;
        end
        
        function setScaleFactor(obj, sF)
            obj.normFact = sF;
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
        
        function tf = usesEvent(obj, event)
            tf = obj.event == event;
        end
        
        function tf = usesStopwatch(obj, stopwatch)
            tf = false;
        end
        
        function tf = usesExtremum(obj, extremum)
            tf = false;
        end
        
        function type = getObjFunctionType(obj)
            type = obj.constraintType;
        end
        
        function [unit, usesCelBody, usesRefSc] = getObjFuncStaticDetails(obj)
            [unit, ~, ~, ~, ~, ~, ~, ~, usesCelBody, usesRefSc] = ma_getConstraintStaticDetails(obj.objFuncType);           
        end
    end
    
    methods(Static)
        function constraint = getDefaultObjFunc(constraintType)            
            constraint = GenericMAObjFunction(constraintType, LaunchVehicleEvent.empty(1,0), [], [], KSPTOT_BodyInfo.empty(1,0));
        end
    end
end