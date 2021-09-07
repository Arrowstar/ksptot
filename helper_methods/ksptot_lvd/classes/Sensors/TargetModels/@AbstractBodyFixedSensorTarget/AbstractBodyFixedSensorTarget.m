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
    end
end

