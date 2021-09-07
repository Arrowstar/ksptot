classdef BodyFixedLatLongGridTargetModel < AbstractBodyFixedSensorTarget
    %BodyFixedLatLongGridTargetModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bodyInfo
        
        %display
        markerShape(1,1) MarkerStyleEnum = MarkerStyleEnum.Circle;
        markerFoundFaceColor(1,1) ColorSpecEnum = ColorSpecEnum.Green;
        markerFoundEdgeColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        markerNotFoundFaceColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        markerNotFoundEdgeColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        markerSize(1,1) double = 3;
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
        
        function shape = getMarkerShape(obj)
            shape = obj.markerShape;
        end
        
        function color = getFoundMarkerFaceColor(obj)
            color = obj.markerFoundFaceColor;
        end
        
        function color = getFoundMarkerEdgeColor(obj)
            color = obj.markerFoundEdgeColor;
        end
        
        function color = getNotFoundMarkerFaceColor(obj)
            color = obj.markerNotFoundFaceColor;
        end
        
        function color = getNotFoundMarkerEdgeColor(obj)
            color = obj.markerNotFoundEdgeColor;
        end
        
        function markerSize = getMarkerSize(obj)
            markerSize = obj.markerSize;
        end
    end
end