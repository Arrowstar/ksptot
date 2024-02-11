classdef SetPolyThrottleModelActionOptimVar < AbstractOptimizationVariable
    %SetRPYSteeringModelActionOptimVar Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj = ThrottlePolyModel.getDefaultThrottleModel()
        
        lb(1,4) double
        ub(1,4) double
        
        varConst(1,1) logical = false;
        varLin(1,1) logical   = false;
        varAccel(1,1) logical = false;
        
        varTimeOffset(1,1) logical = false;
    end
    
    methods
        function obj = SetPolyThrottleModelActionOptimVar(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            obj.id = rand();
        end
        
        function x = getXsForVariable(obj)
            x = NaN(1,4);
            
            if(obj.varConst)
                x(1) = obj.varObj.throttleModel.constTerm;
            end
            if(obj.varLin)
                x(2) = obj.varObj.throttleModel.linearTerm;
            end
            if(obj.varAccel)
                x(3) = obj.varObj.throttleModel.accelTerm;
            end
            
            if(obj.varTimeOffset)
                x(4) = obj.varObj.throttleModel.tOffset;
            end
            
            x(isnan(x)) = [];
        end
        
        function [lb, ub] = getBndsForVariable(obj)            
            useTf = obj.getUseTfForVariable();

            lb = obj.lb(useTf);
            ub = obj.ub(useTf);
        end
        
        function [lb, ub] = getAllBndsForVariable(obj)
            lb = obj.lb;
            ub = obj.lb;
        end
        
        function setBndsForVariable(obj, lb, ub)
            if(length(lb) == 4 && length(ub) == 4)
                obj.lb = lb;
                obj.ub = ub;
            else
                useTf = obj.getUseTfForVariable();

                obj.lb(useTf) = lb;
                obj.ub(useTf) = ub;
            end
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = [obj.varConst obj.varLin obj.varAccel ...
                     obj.varTimeOffset];
        end
        
        function setUseTfForVariable(obj, useTf)                 
            obj.varConst = useTf(1);
            obj.varLin = useTf(2);
            obj.varAccel = useTf(3);
            obj.varTimeOffset = useTf(4);
        end
        
        function updateObjWithVarValue(obj, x)
            ind = 1;
            
            if(obj.varConst)
                obj.varObj.throttleModel.constTerm = x(ind);
                ind = ind + 1;
            end
            if(obj.varLin)
                obj.varObj.throttleModel.linearTerm = x(ind);
                ind = ind + 1;
            end
            if(obj.varAccel)
                obj.varObj.throttleModel.accelTerm = x(ind);
                ind = ind + 1;
            end
            
            if(obj.varTimeOffset)
                obj.varObj.throttleModel.tOffset = x(ind);
                ind = ind + 1; %#ok<NASGU>
            end
        end
        
        function nameStrs = getStrNamesOfVars(obj, evtNum, varLocType)
           if(evtNum > 0)
                subStr = sprintf('Event %i',evtNum);
            else
                subStr = varLocType;
            end
            
            nameStrs = {sprintf('%s Throttle Constant', subStr), ...
                        sprintf('%s Throttle Rate', subStr), ...
                        sprintf('%s Throttle Acceleration', subStr), ...
                        sprintf('%s Throttle Time Offset', subStr)};
                    
            nameStrs = nameStrs(obj.getUseTfForVariable());
        end

        function varsDisplayedAsPercent = getVarsDisplayedAsPercents(obj)
            %This function is for variables that are displayed as
            %percentages but stored as numbers 0 -> 1.  For example, 55%
            %might be the displayed value, but it is stored in the var as
            %0.55.
            varsDisplayedAsPercent = [true, true, true, false];
        end
    end
end