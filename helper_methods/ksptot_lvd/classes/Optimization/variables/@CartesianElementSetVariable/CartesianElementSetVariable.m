classdef CartesianElementSetVariable < AbstractOrbitModelVariable
    %CartesianElementSetVariable Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj(1,1) CartesianElementSet = CartesianElementSet.getDefaultElements();
        
        lb(1,6) double = 0;
        ub(1,6) double = 0;
        
        varRx(1,1) logical = false;
        varRy(1,1) logical = false;
        varRz(1,1) logical = false;
        varVx(1,1) logical = false;
        varVy(1,1) logical = false;
        varVz(1,1) logical = false;
    end
    
    methods
        function obj = CartesianElementSetVariable(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            obj.id = rand();
        end
        
        function x = getXsForVariable(obj)
            x = [];
            
            if(obj.varRx)
                x(end+1) = obj.varObj.rVect(1);
            end
            
            if(obj.varRy)
                x(end+1) = obj.varObj.rVect(2);
            end
            
            if(obj.varRz)
                x(end+1) = obj.varObj.rVect(3);
            end
            
            if(obj.varVx)
                x(end+1) = obj.varObj.vVect(1);
            end
            
            if(obj.varVy)
                x(end+1) = obj.varObj.vVect(2);
            end
            
            if(obj.varVy)
                x(end+1) = obj.varObj.vVect(3);
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
            useTf = [obj.varRx        obj.varRy        obj.varRz        obj.varVx        obj.varVy        obj.varVz];
        end
        
        function setUseTfForVariable(obj, useTf)
            obj.varRx  = useTf(1);     
            obj.varRy = useTf(2);    
            obj.varRz  = useTf(3);
            obj.varVx = useTf(4);
            obj.varVy  = useTf(5);
            obj.varVz = useTf(6);
        end
        
        function updateObjWithVarValue(obj, x)
            xInd = 1;
            
            if(obj.varRx)
                obj.varObj.rVect(1) = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varRy)
                obj.varObj.rVect(2) = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varRz)
                obj.varObj.rVect(3) = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varVx)
                obj.varObj.vVect(1) = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varVy)
                obj.varObj.vVect(2) = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varVz)
                obj.varObj.vVect(3) = x(xInd);
                xInd = xInd + 1; %#ok<NASGU>
            end
        end
        
        function nameStrs = getStrNamesOfVars(obj, evtNum)
            nameStrs = {sprintf('Event %i Rx', evtNum), ...
                        sprintf('Event %i Ry', evtNum), ...
                        sprintf('Event %i Rz', evtNum), ...
                        sprintf('Event %i Vx', evtNum), ...
                        sprintf('Event %i Vy', evtNum), ...
                        sprintf('Event %i Vz', evtNum)};
                    
            nameStrs = nameStrs(obj.getUseTfForVariable());
        end
    end
end