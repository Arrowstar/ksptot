classdef BodyFixedCircleGridTargetModel < AbstractBodyFixedSensorTarget
    %BodyFixedCircleGridTargetModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name(1,:) char
        
        bodyInfo
        
        %input data
        longCenter(1,1) double
        latCenter(1,1) double
        radius(1,1) double
        numPtsCircumference(1,1) double
        numPtsRadial(1,1) double 
        altitude(1,1) double
        
        %display
        markerShape(1,1) MarkerStyleEnum = MarkerStyleEnum.Circle;
        markerFoundFaceColor(1,1) ColorSpecEnum = ColorSpecEnum.Green;
        markerFoundEdgeColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        markerNotFoundFaceColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        markerNotFoundEdgeColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        markerSize(1,1) double = 3;
        
        lvdData LvdData
    end
    
    methods
        function obj = BodyFixedCircleGridTargetModel(name, bodyInfo, longCenter, latCenter, radius, arcOffset, arcAngle, numPtsCircumference, numPtsRadial, altitude, lvdData)
            arguments
                name(1,:) char
                bodyInfo(1,1) KSPTOT_BodyInfo
                longCenter(1,1) double
                latCenter(1,1) double
                radius(1,1) double {mustBeGreaterThanOrEqual(radius,0)}
                arcOffset(1,1) double
                arcAngle(1,1) double
                numPtsCircumference(1,1) double {mustBeInteger(numPtsCircumference), mustBeGreaterThanOrEqual(numPtsCircumference,2)}
                numPtsRadial(1,1) double {mustBeInteger(numPtsRadial), mustBeGreaterThanOrEqual(numPtsRadial,2)}
                altitude(1,1) double {mustBeGreaterThanOrEqual(altitude,0)}
                lvdData(1,1) LvdData
            end
            
            obj.name = name;
            obj.bodyInfo = bodyInfo;
            obj.setGridPointsFromInputs(bodyInfo, longCenter, latCenter, radius, arcOffset, arcAngle, numPtsCircumference, numPtsRadial, altitude); 
            obj.lvdData = lvdData;
        end
        
        function setGridPointsFromInputs(obj, bodyInfo, longCenter, latCenter, radius, arcOffset, arcAngle, numPtsCircumference, numPtsRadial, altitude)
            bRadius = bodyInfo.radius;
            
            S = [0,0,0, bRadius+altitude];
            sphere = sphereMesh(S, 'nTheta', (numPtsRadial-1)*(pi/radius), 'nPhi', (numPtsCircumference-1)*(2*pi/arcAngle));
            sPtsRaw = unique(sphere.vertices,'rows');
            sPtsAngs = dang(repmat([0;0;1],1,size(sPtsRaw,1)), sPtsRaw');
            sPts = sPtsRaw(sPtsAngs <= radius+1E-10, :);
            
            [theta, ~] = cart2pol(sPts(:,1), sPts(:,2));
            theta = AngleZero2Pi(theta);
            sPts = sPts(theta <= arcAngle,:);
            sPts = reshape(sPts',3,1,numel(sPts)/3);
            rotMat = repmat(rotz(rad2deg(arcOffset)),1,1,size(sPts,3));
            sPts = pagemtimes(rotMat, sPts);
            sPts = squeeze(sPts)';
            
            [x,y,z] = sph2cart(longCenter, latCenter, 1);
            v = [x;y;z];
            r = vrrotvec([0;0;1],v);
            M = makehgtform('axisrotate',r(1:3),r(4));
            sPts = transformPoint3d(sPts(:,1), sPts(:,2), sPts(:,3), M);
            
            obj.longCenter = longCenter;
            obj.latCenter = latCenter;
            obj.radius = radius;
            obj.numPtsCircumference = numPtsCircumference;
            obj.numPtsRadial = numPtsRadial;
            obj.altitude = altitude;
            
            obj.rVectECEF = unique(sPts,'rows')';
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = obj.name;
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
        
        function tf = isInUse(obj, lvdData)
            tf = false;
        end
        
        function useTf = openEditDialog(obj)
            useTf = false;
        end
    end
end