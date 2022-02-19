classdef(Abstract) AbstractBodyFixedSensorTarget < AbstractSensorTarget
    %AbstractBodyFixedSensorTarget Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        rVectECEF(3,:) double
    end
    
    methods
        function rVect = getTargetPositions(obj, time, vehElemSet, inFrame)
            arguments
                obj(1,1) AbstractBodyFixedSensorTarget
                time(1,1) double
                vehElemSet(1,1) CartesianElementSet
                inFrame(1,1) AbstractReferenceFrame
            end
            
            bodyFixedFrame = obj.bodyInfo.getBodyFixedFrame();
            
            numPts = size(obj.rVectECEF, 2);
            
            times = time*ones(1, numPts);
            rVects = obj.rVectECEF;
            vVects = zeros(3,numPts);
            cartElem = CartesianElementSet(times, rVects, vVects, bodyFixedFrame, true);
            
            cartElem = convertToFrame(cartElem, inFrame);
            rVect = cartElem.rVect;
        end
        
        function numPts = getNumberOfTargetPts(obj)
            numPts = width(obj.rVectECEF);
        end
        
        function strs = getTargetPtLabelStrs(obj)
            strs = string.empty(1,0);
            for(i=1:width(obj.rVectECEF))
                cartElem = CartesianElementSet(0, obj.rVectECEF(:,i), [0;0;0], obj.bodyInfo.getBodyFixedFrame(), false);
                geoElem = cartElem.convertToGeographicElementSet();
                
                strs(i) = string(sprintf('Target %u (Lat %0.3f deg, Long %0.3f deg, Alt %0.3f km)', i, rad2deg(geoElem.lat), rad2deg(geoElem.long), geoElem.alt)); %#ok<AGROW>
            end
        end
    end
end

