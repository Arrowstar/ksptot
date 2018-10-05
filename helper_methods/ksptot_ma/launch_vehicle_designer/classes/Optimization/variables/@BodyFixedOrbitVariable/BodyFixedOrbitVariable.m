classdef BodyFixedOrbitVariable < AbstractOrbitModelVariable
    %KeplerianOrbitVariable Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj(1,1) BodyFixedOrbitStateModel = BodyFixedOrbitStateModel.getDefaultOrbitState();
        
        lb(1,6) double = 0;
        ub(1,6) double = 0;
        
        varLat(1,1) logical = false;
        varLong(1,1) logical = false;
        varAlt(1,1) logical = false;
        varBFVx(1,1) logical = false;
        varBFVy(1,1) logical = false;
        varBFVz(1,1) logical = false;
    end
    
    methods
        function obj = BodyFixedOrbitVariable(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            obj.id = rand();
        end
        
        function x = getXsForVariable(obj)
            x = [];
            
            if(obj.varLat)
                x(end+1) = obj.varObj.lat;
            end
            
            if(obj.varLong)
                x(end+1) = obj.varObj.long;
            end
            
            if(obj.varAlt)
                x(end+1) = obj.varObj.alt;
            end
            
            if(obj.varBFVx)
                x(end+1) = obj.varObj.vVectECEF_x;
            end
            
            if(obj.varBFVy)
                x(end+1) = obj.varObj.vVectECEF_y;
            end
            
            if(obj.varBFVz)
                x(end+1) = obj.varObj.vVectECEF_z;
            end
        end
        
        function [lb, ub] = getBndsForVariable(obj)
            useTf = obj.getUseTfForVariable();

            lb = obj.lb(useTf);
            ub = obj.ub(useTf);
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
            useTf = [obj.varLat        obj.varLong        obj.varAlt        obj.varBFVx        obj.varBFVy        obj.varBFVz];
        end
        
        function setUseTfForVariable(obj, useTf)
            obj.varLat  = useTf(1);     
            obj.varLong = useTf(2);    
            obj.varAlt  = useTf(3);
            obj.varBFVx = useTf(4);
            obj.varBFVy  = useTf(5);
            obj.varBFVz = useTf(6);
        end
        
        function updateObjWithVarValue(obj, x)
            xInd = 1;
            
            if(obj.varLat)
                obj.varObj.lat = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varLong)
                obj.varObj.long = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varAlt)
                obj.varObj.alt = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varBFVx)
                obj.varObj.vVectECEF_x = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varBFVy)
                obj.varObj.vVectECEF_y = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varBFVz)
                obj.varObj.vVectECEF_z = x(xInd);
                xInd = xInd + 1; %#ok<NASGU>
            end
        end
    end
end