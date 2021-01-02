classdef GenericObjectiveFcn < AbstractObjectiveFcn
    %GenericObjectiveFcn Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        event LaunchVehicleEvent
        targetBodyInfo KSPTOT_BodyInfo
        fcn AbstractConstraint %use abstract constraints because they return values of their functions, too
        scaleFactor (1,1) double = 1;
        
        lvdOptim LvdOptimization
        lvdData LvdData
    end
    
    methods
        function obj = GenericObjectiveFcn(event, targetBodyInfo, fcn, scaleFactor, lvdOptim, lvdData)
            if(nargin > 0)
                obj.lvdData = lvdData;
                obj.lvdOptim = lvdOptim;
                obj.event = event;
                obj.fcn = fcn;
                obj.targetBodyInfo = targetBodyInfo;
                obj.scaleFactor = scaleFactor;
            end
        end
        
        function set.targetBodyInfo(obj, newValue)
            obj.targetBodyInfo = newValue;
            
            if(not(isempty(obj.fcn))) %#ok<MCSUP>
                obj.fcn.refBodyInfo = newValue; %#ok<MCSUP>
            end
        end
        
        function listBoxStr = getListBoxStr(obj)
            listBoxStr = sprintf('%s - Event %u', obj.fcn.getConstraintType(), obj.event.getEventNum());
        end
        
        function [f, fUnscaled] = evalObjFcn(obj, stateLog)            
            [~, ~, value, ~, ~, ~, ~] = obj.fcn.evalConstraint(stateLog, obj.lvdData.celBodyData);
            
            f = value/obj.scaleFactor;
            fUnscaled = value;
        end
        
        function tf = usesStage(obj, stage)
            tf = obj.fcn.usesStage(stage);
        end
        
        function tf = usesEngine(obj, engine)
            tf = obj.fcn.usesEngine(engine);
        end
        
        function tf = usesTank(obj, tank)
            tf = obj.fcn.usesTank(tank);
        end
        
        function tf = usesEngineToTankConn(obj, engineToTank)
            tf = obj.fcn.usesEngineToTankConn(engineToTank);
        end
        
        function tf = usesEvent(obj, event)
            tf = obj.event == event;
        end
        
        function tf = usesExtremum(obj, extremum)
            tf = obj.fcn.usesExtremum(extremum);
        end
        
        function tf = usesGroundObj(obj, grdObj)
            tf = obj.fcn.usesExtremum(grdObj);
        end
        
        function tf = usesCalculusCalc(obj, calculusCalc)
            tf = obj.fcn.usesCalculusCalc(calculusCalc);
        end
        
        function event = getRefEvent(obj)
            event = obj.event;
        end
        
        function bodyInfo = getRefBody(obj)
            bodyInfo = obj.targetBodyInfo;
        end
    end

    methods(Static)
        function objFcn = getDefaultObjFcn(event, refBodyInfo, lvdOptim, lvdData)
            fcn = GenericMAConstraint.getDefaultConstraint('Total Spacecraft Mass');
            objFcn = GenericObjectiveFcn(event, refBodyInfo, fcn, lvdOptim, lvdData);
        end
        
        function params = getParams()
            params = struct();
            
            params.usesEvents = true;
            params.usesBodies = true;
        end
    end
end