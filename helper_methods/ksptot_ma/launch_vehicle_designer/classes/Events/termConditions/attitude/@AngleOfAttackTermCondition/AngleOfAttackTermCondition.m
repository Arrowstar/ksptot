classdef AngleOfAttackTermCondition < AbstractEventTerminationCondition
    %AngleOfAttackTermCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        steeringModel(1,1) AbstractSteeringModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
        targetAoA(1,1) double = 0;
    end
    
    methods
        function obj = AngleOfAttackTermCondition(targetAoA)
            obj.targetAoA = targetAoA;
        end
        
        function evtTermCondFcnHndl = getEventTermCondFuncHandle(obj)
            evtTermCondFcnHndl = @(t,y) obj.eventTermCond(t,y, obj.targetAoA, obj.steeringModel);
        end
        
        function initTermCondition(obj, initialStateLogEntry)
            obj.steeringModel = initialStateLogEntry.steeringModel;
        end
        
        function name = getName(obj)
            name = 'Angle of Attack';
        end
    end
    
    methods(Static, Access=private)
        function [value,isterminal,direction] = eventTermCond(t,y, targetAoA, steeringModel)
            ut = t;
            rVect = y(1:3)';
            vVect = y(4:6)';
            
            dcm = steeringModel.getBody2InertialDcmAtTime(ut, rVect, vVect);
            [~,angOfAttack,~] = computeAeroAnglesFromBodyAxes(rVect, vVect, dcm(:,1), dcm(:,2), dcm(:,3));
            
            value = angOfAttack - targetAoA;
            isterminal = 1;
            direction = 0;
        end
    end
end