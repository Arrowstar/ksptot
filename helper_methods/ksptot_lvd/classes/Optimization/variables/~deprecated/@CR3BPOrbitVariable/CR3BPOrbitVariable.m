classdef CR3BPOrbitVariable < AbstractOrbitModelVariable
    %BodyFixedOrbitVariable Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj(1,1) CR3BPOrbitStateModel = CR3BPOrbitStateModel.getDefaultOrbitState();
        
        lb(1,6) double = 0;
        ub(1,6) double = 0;
        
        varX(1,1) logical = false;
        varY(1,1) logical = false;
        varZ(1,1) logical = false;
        varVx(1,1) logical = false;
        varVy(1,1) logical = false;
        varVz(1,1) logical = false;
    end
    
    methods
        function obj = CR3BPOrbitVariable(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            obj.id = rand();
        end
        
        function x = getXsForVariable(obj)
            x = [];
            
            if(obj.varX)
                x(end+1) = obj.varObj.x;
            end
            
            if(obj.varY)
                x(end+1) = obj.varObj.y;
            end
            
            if(obj.varZ)
                x(end+1) = obj.varObj.z;
            end
            
            if(obj.varVx)
                x(end+1) = obj.varObj.vx;
            end
            
            if(obj.varVy)
                x(end+1) = obj.varObj.vy;
            end
            
            if(obj.varVz)
                x(end+1) = obj.varObj.vz;
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
            useTf = [obj.varX        obj.varY        obj.varZ        obj.varVx        obj.varVy        obj.varVz];
        end
        
        function setUseTfForVariable(obj, useTf)
            obj.varX  = useTf(1);     
            obj.varY = useTf(2);    
            obj.varZ  = useTf(3);
            obj.varVx = useTf(4);
            obj.varVy  = useTf(5);
            obj.varVz = useTf(6);
        end
        
        function updateObjWithVarValue(obj, x)
            xInd = 1;
            
            if(obj.varX)
                obj.varObj.x = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varY)
                obj.varObj.y = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varZ)
                obj.varObj.z = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varVx)
                obj.varObj.vx = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varVy)
                obj.varObj.vy = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varVz)
                obj.varObj.vz = x(xInd);
                xInd = xInd + 1; %#ok<NASGU>
            end
        end
        
        function nameStrs = getStrNamesOfVars(obj, evtNum, varLocType)
            nameStrs = {sprintf('Event %i CR3BP Position (X)', evtNum), ...
                        sprintf('Event %i CR3BP Position (Y)', evtNum), ...
                        sprintf('Event %i CR3BP Position (Z)', evtNum), ...
                        sprintf('Event %i CR3BP Velocity (X)', evtNum), ...
                        sprintf('Event %i CR3BP Velocity (Y)', evtNum), ...
                        sprintf('Event %i CR3BP Velocity (Z)', evtNum)};
                    
            nameStrs = nameStrs(obj.getUseTfForVariable());
        end
    end
end