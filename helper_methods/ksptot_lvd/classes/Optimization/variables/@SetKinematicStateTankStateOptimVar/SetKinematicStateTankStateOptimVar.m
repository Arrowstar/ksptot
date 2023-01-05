classdef SetKinematicStateTankStateOptimVar < AbstractOptimizationVariable
    %SetKinematicStateTankStateOptimVar Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj SetKinematicStateTankState
        
        lwrBnd(1,1) double = 0;
        uprBnd(1,1) double = 0;
        
        useTf(1,1) = false;
    end
    
    methods
        function obj = SetKinematicStateTankStateOptimVar(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            obj.id = rand();
        end
        
        function x = getXsForVariable(obj)
            x = [];
            
            if(obj.useTf)
                x = obj.varObj.tankStateMassToSet;
            end
        end
        
        function [lb, ub] = getBndsForVariable(obj)
            lb = obj.lwrBnd(obj.useTf);
            ub = obj.uprBnd(obj.useTf);
        end
        
        function [lb, ub] = getAllBndsForVariable(obj)
            lb = obj.lwrBnd;
            ub = obj.uprBnd;
        end
        
        function setBndsForVariable(obj, lb, ub)
            obj.lwrBnd = lb;
            obj.uprBnd = ub;
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = obj.useTf;
        end
        
        function setUseTfForVariable(obj, useTf)
            obj.useTf = useTf;
        end
        
        function updateObjWithVarValue(obj, x)            
            obj.varObj.tankStateMassToSet = x;
        end
        
        function nameStrs = getStrNamesOfVars(obj, evtNum, varLocType)
            if(evtNum > 0)
                subStr = sprintf('Event %i',evtNum);
            else
                subStr = varLocType;
            end
            
            tankName = obj.varObj.tank.name;
            if(isempty(tankName))
                tankName = 'Untitled Tank';
            end
            
            nameStrs = {sprintf('%s Tank "%s" Mass', subStr, tankName)};
        end
    end
end