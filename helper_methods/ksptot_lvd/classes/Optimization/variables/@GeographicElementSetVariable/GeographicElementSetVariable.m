classdef GeographicElementSetVariable < AbstractOrbitModelVariable
    %GeographicElementSetVariable Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj(1,1) GeographicElementSet = GeographicElementSet.getDefaultElements();
        
        lb(1,6) double = 0;
        ub(1,6) double = 0;
        
        varLat(1,1) logical = false;
        varLong(1,1) logical = false;
        varAlt(1,1) logical = false;
        varBFAz(1,1) logical = false;
        varBFEl(1,1) logical = false;
        varBFMag(1,1) logical = false;
    end
    
    methods
        function obj = GeographicElementSetVariable(varObj)
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
            
            if(obj.varBFAz)
                x(end+1) = obj.varObj.velAz;
            end
            
            if(obj.varBFEl)
                x(end+1) = obj.varObj.velEl;
            end
            
            if(obj.varBFMag)
                x(end+1) = obj.varObj.velMag;
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
            useTf = [obj.varLat        obj.varLong        obj.varAlt        obj.varBFAz        obj.varBFEl        obj.varBFMag];
        end
        
        function setUseTfForVariable(obj, useTf)
            obj.varLat  = useTf(1);     
            obj.varLong = useTf(2);    
            obj.varAlt  = useTf(3);
            obj.varBFAz = useTf(4);
            obj.varBFEl  = useTf(5);
            obj.varBFMag = useTf(6);
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
            
            if(obj.varBFAz)
                obj.varObj.velAz = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varBFEl)
                obj.varObj.velEl = x(xInd);
                xInd = xInd + 1;
            end
            
            if(obj.varBFMag)
                obj.varObj.velMag = x(xInd);
                xInd = xInd + 1; %#ok<NASGU>
            end
        end
        
        function nameStrs = getStrNamesOfVars(obj, evtNum, varLocType)
            if(evtNum > 0)
                subStr = sprintf('Event %i',evtNum);
            else
                subStr = varLocType;
            end
            
            nameStrs = {sprintf('%s Latitude', subStr), ...
                        sprintf('%s Longitude', subStr), ...
                        sprintf('%s Altitude', subStr), ...
                        sprintf('%s Body-Fixed Velocity Azimuth', subStr), ...
                        sprintf('%s Body-Fixed Velocity Elevation', subStr), ...
                        sprintf('%s Body-Fixed Velocity Magnitude', subStr)};
                    
            nameStrs = nameStrs(obj.getUseTfForVariable());
        end
    end
end