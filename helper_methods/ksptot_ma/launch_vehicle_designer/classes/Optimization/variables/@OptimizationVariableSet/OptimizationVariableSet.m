classdef OptimizationVariableSet < matlab.mixin.SetGet
    %OptimizationVariableSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        vars(1,:) AbstractOptimizationVariable
    end
    
    methods
        function obj = OptimizationVariableSet()

        end
        
        function addVariable(obj, newVar)
            obj.vars(end+1) = newVar;
        end
        
        function removeVariable(obj, var)
            obj.vars(obj.vars == var) = [];
        end
        
        function x = getTotalXVector(obj)
            x = [];
            
            for(i=1:length(obj.vars)) %#ok<*NO4LP>
                x = horzcat(x, obj.vars(i).getXsForVariable()); %#ok<AGROW>
            end
        end
        
        function [LwrBnds, UprBnds] = getTotalBndsVector(obj)
            LwrBnds = [];
            UprBnds = [];
            
            for(i=1:length(obj.vars)) %#ok<*NO4LP>
                [lb, ub]= obj.vars(i).getBndsForVariable();
                LwrBnds = horzcat(LwrBnds, lb); %#ok<AGROW>
                UprBnds = horzcat(UprBnds, ub); %#ok<AGROW>
            end
        end
        
        function updateObjsWithVarValues(obj, x)
            initInd = 1;
            
            for(i=1:length(obj.vars))
                numVars = obj.vars(i).getNumOfVars();
                
                inds = initInd:initInd+numVars-1;
                subX = x(inds);
                obj.vars(i).updateObjWithVarValue(subX);
                
                initInd = inds(end) + 1;
            end            
        end
    end
end