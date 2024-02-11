classdef AddDeltaVActionVariable < AbstractOrbitModelVariable
    %AddDeltaVActionVariable Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj(1,1) AddDeltaVAction
        
        lb(1,3) double = 0;
        ub(1,3) double = 0;
        
        varDVx(1,1) logical = false;
        varDVy(1,1) logical = false;
        varDVz(1,1) logical = false;
    end
    
    methods
        function obj = AddDeltaVActionVariable(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            obj.id = rand();
        end
        
        function x = getXsForVariable(obj)
            x = [];
            
            if(obj.varDVx)
                x(end+1) = obj.varObj.deltaVVect(1);
            end
            
            if(obj.varDVy)
                x(end+1) = obj.varObj.deltaVVect(2);
            end
            
            if(obj.varDVz)
                x(end+1) = obj.varObj.deltaVVect(3);
            end
        end
        
        function [lb, ub] = getBndsForVariable(obj)
            useTf = obj.getUseTfForVariable();

            lb = obj.lb(useTf);
            ub = obj.ub(useTf);
        end
        
        function [lb, ub] = getAllBndsForVariable(obj)
            lb = obj.lb;
            ub = obj.ub;
        end
        
        function setBndsForVariable(obj, lb, ub)
            if(length(lb) == 3 && length(ub) == 3)
                obj.lb = lb;
                obj.ub = ub;
            else
                useTf = obj.getUseTfForVariable();

                obj.lb(useTf) = lb;
                obj.ub(useTf) = ub;
            end
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = [obj.varDVx        obj.varDVy        obj.varDVz];
        end
        
        function setUseTfForVariable(obj, useTf)
            obj.varDVx = useTf(1);     
            obj.varDVy = useTf(2);    
            obj.varDVz = useTf(3);
        end
        
        function updateObjWithVarValue(obj, x)
            xInd = 1;
            
            if(obj.varDVx)
                obj.varObj.deltaVVect(1) = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varDVy)
                obj.varObj.deltaVVect(2) = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varDVz)
                obj.varObj.deltaVVect(3) = x(xInd);
                xInd = xInd + 1;
            end
        end
        
        function nameStrs = getStrNamesOfVars(obj, evtNum, varLocType)
            compNames = obj.varObj.frame.compNames;
            
            nameStrs = {sprintf('Event %i Delta-V (%s)', evtNum, compNames{1}), ...
                        sprintf('Event %i Delta-V (%s)', evtNum, compNames{2}), ...
                        sprintf('Event %i Delta-V (%s)', evtNum, compNames{3})};
                    
            nameStrs = nameStrs(obj.getUseTfForVariable());
        end

        function varsDisplayedAsMeters = getVarsDisplayedAsMeters(obj)
            %This function is for variables that are displayed as
            %meters (or m/s, etc) but stored as kilometers (or km/s, etc).
            %For example, a DV burn component of 456 m/s might be displayed
            %that way, but stored internally as "0.456."
            varsDisplayedAsMeters = [true true true];
        end
    end
end