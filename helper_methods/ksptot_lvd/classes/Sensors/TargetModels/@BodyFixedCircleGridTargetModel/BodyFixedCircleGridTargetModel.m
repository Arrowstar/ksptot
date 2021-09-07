classdef BodyFixedCircleGridTargetModel < AbstractBodyFixedSensorTarget
    %BodyFixedCircleGridTargetModel Summary of this class goes here
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
        function obj = BodyFixedCircleGridTargetModel(bodyInfo, longCenter, latCenter, radius, numPtsLong, numPtsLat, altitude)
            arguments
                bodyInfo(1,1) KSPTOT_BodyInfo
                longCenter(1,1) double
                latCenter(1,1) double
                radius(1,1) double
                numPtsLong(1,1) double
                numPtsLat(1,1) double
                altitude(1,1) double
            end
            obj.bodyInfo = bodyInfo;
            bRadius = bodyInfo.radius;
            
            S = [0,0,0, bRadius+altitude];
            sphere = sphereMesh(S, 'nTheta', numPtsLat*(pi/radius), 'nPhi', numPtsLong);
            sPtsRaw = unique(sphere.vertices,'rows');
            sPtsAngs = dang(repmat([0;0;1],1,size(sPtsRaw,1)), sPtsRaw');
            sPts = sPtsRaw(sPtsAngs <= radius+1E-10, :);
            
            [x,y,z] = sph2cart(longCenter, latCenter, 1);
            v = [x;y;z];
            r = vrrotvec([0;0;1],v);
            M = makehgtform('axisrotate',r(1:3),r(4));
            sPts = transformPoint3d(sPts(:,1), sPts(:,2), sPts(:,3), M);
            
            obj.rVectECEF = unique(sPts,'rows')';
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