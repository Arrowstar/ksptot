classdef(Abstract) AbstractOptimizationVariable < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractOptimizationVariable Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        id(1,1) double
    end
    
    methods
        x = getXsForVariable(obj)
        
        [lb, ub] = getBndsForVariable(obj)
        
        [lb, ub] = getAllBndsForVariable(obj)
        
        setBndsForVariable(obj, lb, ub)
        
        useTf = getUseTfForVariable(obj)
        
        setUseTfForVariable(obj, useTf)
        
        updateObjWithVarValue(obj, x)
        
        nameStrs = getStrNamesOfVars(obj, evtNum, varLocType)
        
        function [xS, lbS, ubS] = getScaledXsForVariable(obj)
            x = obj.getXsForVariable();
            [lb, ub] = obj.getBndsForVariable();
            
            xS = x;
            lbS = lb;
            ubS = ub;
            for(i=1:length(x))
                xi = x(i);
                lbi = lb(i);
                ubi = ub(i);
                
                bndDiff = ubi - lbi;
                bndCenter = (lbi + ubi)/2;
                if(bndDiff > 1E-10)
                    xS(i) = (xi - bndCenter)/(bndDiff/2);
                    lbS(i) = -1;
                    ubS(i) = 1; 
                else
                    xS(i) = xi;
                    lbS(i) = lbi;
                    ubS(i) = ubi; 
                end
            end
        end
        
        function updateObjWithScaledVarValue(obj, xS)
            [lb, ub] = obj.getBndsForVariable();
            
            x = xS;
            for(i=1:length(xS))
                xSi = xS(i);
                lbi = lb(i);
                ubi = ub(i);
                
                bndDiff = ubi - lbi;
                bndCenter = (lbi + ubi)/2;
                
                if(bndDiff > 1E-10)
                    x(i) = xSi * (bndDiff/2) + bndCenter;
                else                    
                    x(i) = xSi;
                end
            end
            
            obj.updateObjWithVarValue(x);
        end
        
        function perturbVar(obj, pPct)
            x = obj.getXsForVariable();
            [lb, ub] = obj.getBndsForVariable();
            
            if(isempty(x))
                return;
            end
            
            for(i=1:length(x)) %#ok<*NO4LP>
                xi = x(i);
                lbi = lb(i);
                ubi = ub(i);

                fact = xi;
                if(abs(fact) < 1E-10)
                    fact = 1;
                end

                p1 = xi - (pPct/100)*fact;
                p2 = xi + (pPct/100)*fact;

                lbRnd = max(min(p1,p2),lbi);
                ubRnd = min(max(p1,p2),ubi);

                xRnd = lbRnd + (ubRnd - lbRnd)*rand();
                x(i) = xRnd;
            end
            
            obj.updateObjWithVarValue(x);
        end

        function varsStoredInRad = getVarsStoredInRad(obj)
            useTf = obj.getUseTfForVariable();
            varsStoredInRad = false(size(useTf));
        end
    end
    
    methods(Sealed)
        function numVars = getNumOfVars(obj)
            [lb,~] = obj.getBndsForVariable();
            numVars = numel(lb);
        end
        
        function tf = eq(A,B)
            tf = [A.id] == [B.id];
        end 
        
        function tf = ne(A,B)
            tf = [A.id] ~= [B.id];
        end 
    end
end