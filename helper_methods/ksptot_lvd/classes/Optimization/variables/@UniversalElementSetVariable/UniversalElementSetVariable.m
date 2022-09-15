classdef UniversalElementSetVariable < AbstractOrbitModelVariable
    %UniversalElementSetVariable Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj(1,1) UniversalElementSet = UniversalElementSet.getDefaultElements();
        
        lb(1,6) double = 0;
        ub(1,6) double = 0;
        
        varC3(1,1) logical = false;
        varRp(1,1) logical = false;
        varInc(1,1) logical = false;
        varRaan(1,1) logical = false;
        varArg(1,1) logical = false;
        varTau(1,1) logical = false;
    end
    
    methods
        function obj = UniversalElementSetVariable(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            obj.id = rand();
        end
        
        function x = getXsForVariable(obj)
            x = [];
            
            if(obj.varC3)
                x(end+1) = obj.varObj.c3;
            end
            
            if(obj.varRp)
                x(end+1) = obj.varObj.rP;
            end
            
            if(obj.varInc)
                x(end+1) = obj.varObj.inc;
            end
            
            if(obj.varRaan)
                x(end+1) = obj.varObj.raan;
            end
            
            if(obj.varArg)
                x(end+1) = obj.varObj.arg;
            end
            
            if(obj.varTau)
                x(end+1) = obj.varObj.tau;
            end
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
            if(length(lb) == 6 && length(ub) == 6)
                obj.lb = lb;
                obj.ub = ub;
            else
                useTf = obj.getUseTfForVariable();

                obj.lb(useTf) = lb;
                obj.ub(useTf) = ub;
            end
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = [obj.varC3        obj.varRp        obj.varInc        obj.varRaan        obj.varArg        obj.varTau];
        end
        
        function setUseTfForVariable(obj, useTf)
            obj.varC3  = useTf(1);     
            obj.varRp = useTf(2);    
            obj.varInc  = useTf(3);
            obj.varRaan = useTf(4);
            obj.varArg  = useTf(5);
            obj.varTau = useTf(6);
        end
        
        function updateObjWithVarValue(obj, x)
            xInd = 1;
            
            if(obj.varC3)
                obj.varObj.c3 = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varRp)
                obj.varObj.rP = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varInc)
                obj.varObj.inc = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varRaan)
                obj.varObj.raan = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varArg)
                obj.varObj.arg = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varTau)
                obj.varObj.tau = x(xInd);
                xInd = xInd + 1; %#ok<NASGU>
            end
        end
        
        function nameStrs = getStrNamesOfVars(obj, evtNum, varLocType)
            if(evtNum > 0)
                subStr = sprintf('Event %i',evtNum);
            else
                subStr = varLocType;
            end
            
            nameStrs = {sprintf('%s C3 Energy', subStr), ...
                        sprintf('%s Radius of Periapsis', subStr), ...
                        sprintf('%s Inclination', subStr), ...
                        sprintf('%s RAAN', subStr), ...
                        sprintf('%s Argument of Periapsis', subStr), ...
                        sprintf('%s Time Past Periapsis', subStr)};
                    
            nameStrs = nameStrs(obj.getUseTfForVariable());
        end

        function varsStoredInRad = getVarsStoredInRad(obj)
            varsStoredInRad = [false false true true true false];
        end
    end
end