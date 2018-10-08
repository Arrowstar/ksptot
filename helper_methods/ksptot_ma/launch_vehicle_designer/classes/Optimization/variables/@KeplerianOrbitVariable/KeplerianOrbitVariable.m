classdef KeplerianOrbitVariable < AbstractOrbitModelVariable
    %KeplerianOrbitVariable Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj(1,1) KeplerianOrbitStateModel = KeplerianOrbitStateModel.getDefaultOrbitState();
        
        lb(1,6) double = 0;
        ub(1,6) double = 0;
        
        varSma(1,1) logical = false;
        varEcc(1,1) logical = false;
        varInc(1,1) logical = false;
        varRaan(1,1) logical = false;
        varArg(1,1) logical = false;
        varTru(1,1) logical = false;
    end
    
    methods
        function obj = KeplerianOrbitVariable(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            obj.id = rand();
        end
        
        function x = getXsForVariable(obj)
            x = [];
            
            if(obj.varSma)
                x(end+1) = obj.varObj.sma;
            end
            
            if(obj.varEcc)
                x(end+1) = obj.varObj.ecc;
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
            
            if(obj.varTru)
                x(end+1) = obj.varObj.tru;
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
            useTf = [obj.varSma        obj.varEcc        obj.varInc        obj.varRaan        obj.varArg        obj.varTru];
        end
        
        function setUseTfForVariable(obj, useTf)
            obj.varSma  = useTf(1);     
            obj.varEcc = useTf(2);    
            obj.varInc  = useTf(3);
            obj.varRaan = useTf(4);
            obj.varArg  = useTf(5);
            obj.varTru = useTf(6);
        end
        
        function updateObjWithVarValue(obj, x)
            xInd = 1;
            
            if(obj.varSma)
                obj.varObj.sma = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varEcc)
                obj.varObj.ecc = x(xInd);
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
            
            if(obj.varTru)
                obj.varObj.tru = x(xInd);
                xInd = xInd + 1; %#ok<NASGU>
            end
        end
    end
end