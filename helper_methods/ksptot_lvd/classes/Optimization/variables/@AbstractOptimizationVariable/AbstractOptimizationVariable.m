classdef(Abstract) AbstractOptimizationVariable < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractOptimizationVariable Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        id(1,1) double
    end

    properties(Constant)
        %Bound gaps at or below this are treated as a fixed (degenerate)
        %variable element by the [-1, 1] scaling.
        degenerateBndTol = 1E-10;
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
            %getScaledXsForVariable Maps each element of the variable onto the
            %optimizer's [-1, 1] box.  A degenerate element (ub - lb below
            %AbstractOptimizationVariable.degenerateBndTol) is fixed by its
            %bounds, so it is represented as 0 with bounds [0, 0] rather than
            %leaking its raw, arbitrarily scaled value into the x vector next
            %to the properly scaled ones.
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
                if(bndDiff > AbstractOptimizationVariable.degenerateBndTol)
                    xS(i) = (xi - bndCenter)/(bndDiff/2);
                    lbS(i) = -1;
                    ubS(i) = 1;
                else
                    xS(i) = 0;
                    lbS(i) = 0;
                    ubS(i) = 0;
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

                if(bndDiff > AbstractOptimizationVariable.degenerateBndTol)
                    x(i) = xSi * (bndDiff/2) + bndCenter;
                else
                    %degenerate bounds pin the value; the scaled coordinate
                    %carries no information (see getScaledXsForVariable)
                    x(i) = bndCenter;
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
            %This function is for variables that are displayed as degrees
            %but stored in radians.
            useTf = obj.getUseTfForVariable();
            varsStoredInRad = false(size(useTf));
        end

        function varsDisplayedAsPercent = getVarsDisplayedAsPercents(obj)
            %This function is for variables that are displayed as
            %percentages but stored as numbers 0 -> 1.  For example, 55%
            %might be the displayed value, but it is stored in the var as
            %0.55.
            useTf = obj.getUseTfForVariable();
            varsDisplayedAsPercent = false(size(useTf));
        end

        function varsDisplayedAsMeters = getVarsDisplayedAsMeters(obj)
            %This function is for variables that are displayed as
            %meters (or m/s, etc) but stored as kilometers (or km/s, etc).
            %For example, a DV burn component of 456 m/s might be displayed
            %that way, but stored internally as "0.456."
            useTf = obj.getUseTfForVariable();
            varsDisplayedAsMeters = false(size(useTf));
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