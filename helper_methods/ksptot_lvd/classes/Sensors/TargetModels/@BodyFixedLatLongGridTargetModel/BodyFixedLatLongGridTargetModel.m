classdef BodyFixedLatLongGridTargetModel < AbstractSensorTarget
    %BodyFixedLatLongGridTargetModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bodyInfo
        rVectECEF(3,:) double
    end
    
    methods
        function obj = BodyFixedLatLongGridTargetModel(bodyInfo, nwCornerLong, nwCornerLat, seCornerLong, seCornerLat, numPtsLong, numPtsLat, altitude)
            arguments
                bodyInfo(1,1) KSPTOT_BodyInfo
                nwCornerLong(1,1) double
                nwCornerLat(1,1) double
                seCornerLong(1,1) double
                seCornerLat(1,1) double
                numPtsLong(1,1) double
                numPtsLat(1,1) double
                altitude(1,1) double
            end
            obj.bodyInfo = bodyInfo;
            
            minLong = min([nwCornerLong, seCornerLong]);
            maxLong = max([nwCornerLong, seCornerLong]);
            longs = linspace(minLong, maxLong, numPtsLong);
            
            minLat = min([nwCornerLat, seCornerLat]);
            maxLat = max([nwCornerLat, seCornerLat]);
            lats = linspace(minLat, maxLat, numPtsLat);
            
            longLats = combvec(longs, lats)';
            longs = longLats(:,1);
            lats = longLats(:,2);
            alt = altitude * ones(size(longs));
            rVectECEF = getrVectEcefFromLatLongAlt(lats, longs, alt, bodyInfo);
            rVectECEF(abs(rVectECEF) < 1E-10) = 0;
            
            obj.rVectECEF = unique(rVectECEF','rows')';
        end
        
        function rVect = getTargetPositions(obj, time, vehElemSet, inFrame)
            arguments
                obj(1,1) BodyFixedLatLongGridTargetModel
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