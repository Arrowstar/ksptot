classdef GenericObjectiveFcn < AbstractObjectiveFcn
    %GenericObjectiveFcn Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        event LaunchVehicleEvent
        fcn AbstractConstraint %use abstract constraints because they return values of their functions, too
        scaleFactor (1,1) double = 1;
        
        lvdOptim LvdOptimization
        lvdData LvdData
        
        %deprecated
        targetBodyInfo KSPTOT_BodyInfo
    end
    
    properties(Dependent)
        frame AbstractReferenceFrame
    end
    
    methods
        function obj = GenericObjectiveFcn(event, frame, fcn, scaleFactor, lvdOptim, lvdData)
            if(nargin > 0)
                obj.lvdData = lvdData;
                obj.lvdOptim = lvdOptim;
                obj.event = event;
                obj.fcn = fcn;
                obj.frame = frame;
                obj.scaleFactor = scaleFactor;
            end
        end
        
        function value = get.frame(obj)
            value = obj.fcn.frame;
        end
        
        function set.frame(obj, newFrame)
            obj.fcn.frame = newFrame;
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
            tf = obj.fcn.usesGroundObj(grdObj);
        end
        
        function tf = usesCalculusCalc(obj, calculusCalc)
            tf = obj.fcn.usesCalculusCalc(calculusCalc);
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = obj.fcn.usesGeometricPoint(point);
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = obj.fcn.usesGeometricVector(vector);
        end
        
        function tf = usesGeometricCoordSys(obj, coordSys)
            tf = obj.fcn.usesGeometricCoordSys(coordSys);
        end
        
        function tf = usesGeometricRefFrame(obj, refFrame)
            tf = obj.fcn.usesGeometricRefFrame(refFrame);
        end
        
        function tf = usesGeometricAngle(obj, angle)
            tf = obj.fcn.usesGeometricAngle(angle);
        end
        
        function tf = usesGeometricPlane(obj, plane)
            tf = obj.fcn.usesGeometricPlane(plane);
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
            if(not(isempty(refBodyInfo)))
                someFrame = refBodyInfo.getBodyCenteredInertialFrame();
            else
                someFrame = LvdData.getDefaultInitialBodyInfo(lvdData.celBodyData).getBodyCenteredInertialFrame();
            end
            
            fcn = GenericMAConstraint.getDefaultConstraint('Total Spacecraft Mass');
            objFcn = GenericObjectiveFcn(event, someFrame, fcn, lvdOptim, lvdData);
        end
        
        function params = getParams()
            params = struct();
            
            params.usesEvents = true;
            params.usesBodies = true;
        end
        
        function obj = loadobj(obj)
            if(isempty(obj.frame))
                if(not(isempty(obj.targetBodyInfo)))
                    obj.frame = obj.refBody.getBodyCenteredInertialFrame();
                else
                    obj.frame = LvdData.getDefaultInitialBodyInfo(obj.lvdData.celBodyData).getBodyCenteredInertialFrame();
                end
            end
        end
    end
end