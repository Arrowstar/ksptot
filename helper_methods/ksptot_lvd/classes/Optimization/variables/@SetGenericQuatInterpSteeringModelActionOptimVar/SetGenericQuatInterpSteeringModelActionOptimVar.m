classdef SetGenericQuatInterpSteeringModelActionOptimVar < AbstractOptimizationVariable
    %SetGenericPolySteeringModelActionOptimVar Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj = GenericQuatInterpSteeringModel.getDefaultSteeringModel()
        
        lb(1,7) double
        ub(1,7) double
        
        varTDur(1,1) logical = false;
        
        varGamma0(1,1) logical = false;
        varGamma1(1,1) logical   = false;
        
        varBeta0(1,1) logical = false;
        varBeta1(1,1) logical   = false;
        
        varAlpha0(1,1) logical = false;
        varAlpha1(1,1) logical   = false;
    end
    
    methods
        function obj = SetGenericQuatInterpSteeringModelActionOptimVar(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            obj.id = rand();
        end
        
        function x = getXsForVariable(obj)
            x = NaN(1,7);
            
            if(obj.varTDur)
                x(1) = obj.varObj.tDur;
            end
            
            if(obj.varGamma0)
                x(2) = obj.varObj.gamma0;
            end
            if(obj.varGamma1)
                x(3) = obj.varObj.gamma1;
            end
            
            if(obj.varBeta0)
                x(4) = obj.varObj.beta0;
            end
            if(obj.varBeta1)
                x(5) = obj.varObj.beta1;
            end
            
            if(obj.varAlpha0)
                x(6) = obj.varObj.alpha0;
            end
            if(obj.varAlpha1)
                x(7) = obj.varObj.alpha1;
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
            if(length(lb) == 7 && length(ub) == 7)
                obj.lb = lb;
                obj.ub = ub;
            else
                useTf = obj.getUseTfForVariable();

                obj.lb(useTf) = lb;
                obj.ub(useTf) = ub;
            end
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = [obj.varTDur ...
                     obj.varGamma0 obj.varGamma1 ...
                     obj.varBeta0 obj.varBeta1 ...
                     obj.varAlpha0 obj.varAlpha1];
        end
        
        function setUseTfForVariable(obj, useTf) 
            obj.varTDur = useTf(1);
            
            obj.varGamma0 = useTf(2);
            obj.varGamma1 = useTf(3);
            
            obj.varBeta0 = useTf(4);
            obj.varBeta1 = useTf(5);
            
            obj.varAlpha0 = useTf(6);
            obj.varAlpha1 = useTf(7);
        end
        
        function updateObjWithVarValue(obj, x)
            ind = 1;
            
            if(obj.varTDur)
                obj.varObj.tDur = x(ind);
                ind = ind + 1;
            end
            
            if(obj.varGamma0)
                obj.varObj.gamma0 = x(ind);
                ind = ind + 1;
            end
            if(obj.varGamma1)
                obj.varObj.gamma1 = x(ind);
                ind = ind + 1;
            end
            
            if(obj.varBeta0)
                obj.varObj.beta0 = x(ind);
                ind = ind + 1;
            end
            if(obj.varBeta1)
                obj.varObj.beta1 = x(ind);
                ind = ind + 1;
            end
            
            if(obj.varAlpha0)
                obj.varObj.alpha0 = x(ind);
                ind = ind + 1;
            end
            if(obj.varAlpha1)
                obj.varObj.alpha1 = x(ind);
                ind = ind + 1; %#ok<NASGU>
            end
        end
        
        function nameStrs = getStrNamesOfVars(obj, evtNum, varLocType)
           if(evtNum > 0)
                subStr = sprintf('Event %i',evtNum);
            else
                subStr = varLocType;
            end
            
            nameStrs = {sprintf('%s Rotation Duration', subStr), ...
                        sprintf('%s Initial Gamma Angle', subStr), ...
                        sprintf('%s Final Gamma Angle', subStr), ...
                        sprintf('%s Initial Beta Angle', subStr), ...
                        sprintf('%s Final Beta Angle', subStr), ...
                        sprintf('%s Initial Alpha Angle', subStr), ...
                        sprintf('%s Final Alpha Angle', subStr)};

                    
            nameStrs = nameStrs(obj.getUseTfForVariable());
        end

        function varsStoredInRad = getVarsStoredInRad(obj)
            varsStoredInRad = [false  true true  true true  true true];
        end
    end
end