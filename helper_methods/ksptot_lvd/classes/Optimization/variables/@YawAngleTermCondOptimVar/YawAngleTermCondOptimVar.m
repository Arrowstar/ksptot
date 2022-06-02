classdef YawAngleTermCondOptimVar < AbstractOptimizationVariable
    %YawAngleTermCondOptimVar Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj(1,1) YawTermCondition = YawTermCondition(0);
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
        
        useTf(1,1) = false;
    end
    
    methods
        function obj = YawAngleTermCondOptimVar(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            obj.id = rand();
        end
        
        function x = getXsForVariable(obj)
            x = [];
            
            if(obj.useTf)
                x = obj.varObj.targetYawAngle;
            end
        end
        
        function [lb, ub] = getBndsForVariable(obj)
            lb = obj.lb(obj.useTf);
            ub = obj.ub(obj.useTf);
        end
        
        function [lb, ub] = getAllBndsForVariable(obj)
            lb = obj.lb;
            ub = obj.ub;
        end
        
        function setBndsForVariable(obj, lb, ub)
            obj.lb = lb;
            obj.ub = ub;
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = obj.useTf;
        end
        
        function setUseTfForVariable(obj, useTf)
            obj.useTf = useTf;
        end
        
        function updateObjWithVarValue(obj, x)
            obj.varObj.targetYawAngle = x;
        end
        
        function nameStrs = getStrNamesOfVars(obj, evtNum, varLocType)
            nameStrs = {sprintf('Event %i Yaw Angle Termination Condition', evtNum)};
        end

        function varsStoredInRad = getVarsStoredInRad(obj)
            varsStoredInRad = true;
        end
    end
end