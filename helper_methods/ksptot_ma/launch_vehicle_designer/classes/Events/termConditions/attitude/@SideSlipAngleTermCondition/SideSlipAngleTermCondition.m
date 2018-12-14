classdef SideSlipAngleTermCondition < AbstractEventTerminationCondition
    %SideSlipAngleTermCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        steeringModel(1,1) AbstractSteeringModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
        targetSlipAngle(1,1) double = 0;
        bodyInfo KSPTOT_BodyInfo
    end
    
    methods
        function obj = SideSlipAngleTermCondition(targetSlipAngle)
            obj.targetSlipAngle = targetSlipAngle;
        end
        
        function evtTermCondFcnHndl = getEventTermCondFuncHandle(obj)
            evtTermCondFcnHndl = @(t,y) obj.eventTermCond(t,y, obj.targetSlipAngle, obj.steeringModel, obj.bodyInfo);
        end
        
        function initTermCondition(obj, initialStateLogEntry)
            obj.steeringModel = initialStateLogEntry.steeringModel;
            obj.bodyInfo = initialStateLogEntry.centralBody;
        end
        
        function name = getName(obj)
            name = sprintf('Side Slip Angle (%.3f deg)', rad2deg(obj.targetSlipAngle));
        end
        
        function tf = shouldBeReinitOnRestart(obj)
            tf = false;
        end
        
        function params = getTermCondUiStruct(obj)
            params = struct();
            
            params.paramName = 'Target Side Slip Angle';
            params.paramUnit = 'deg';
            params.useParam = 'on';
            params.useStages = 'off';
            params.useTanks = 'off';
            params.useEngines = 'off';
            
            params.value = rad2deg(obj.targetSlipAngle);
            params.refStage = LaunchVehicleStage.empty(1,0);
            params.refTank = LaunchVehicleEngine.empty(1,0);
            params.refEngine = LaunchVehicleEngine.empty(1,0);
        end
        
        function optVar = getNewOptVar(obj)
            optVar = SideSlipAngleTermCondOptimVar(obj);
        end
        
        function optVar = getExistingOptVar(obj)
            optVar = obj.optVar;
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
    end
    
    methods(Static)
        function termCond = getTermCondForParams(paramValue, stage, tank, engine)
            termCond = SideSlipAngleTermCondition((paramValue));
        end
    end
    
    methods(Static, Access=private)
        function [value,isterminal,direction] = eventTermCond(t,y, targetSlipAngle, steeringModel, bodyInfo)
            ut = t;
            rVect = y(1:3);
            vVect = y(4:6);
            
            dcm = steeringModel.getBody2InertialDcmAtTime(ut, rVect, vVect, bodyInfo);
            [~,~,angOfSideslip] = computeAeroAnglesFromBodyAxes(ut, rVect, vVect, bodyInfo, dcm(:,1), dcm(:,2), dcm(:,3));
            
            angOfSideslip = AngleZero2Pi(angOfSideslip);
            
            value = angOfSideslip - targetSlipAngle;
            isterminal = 1;
            direction = 0;
        end
    end
end