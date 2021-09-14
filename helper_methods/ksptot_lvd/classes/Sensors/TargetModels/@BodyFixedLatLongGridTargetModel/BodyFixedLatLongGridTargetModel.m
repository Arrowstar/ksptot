classdef BodyFixedLatLongGridTargetModel < AbstractBodyFixedSensorTarget
    %BodyFixedLatLongGridTargetModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name(1,:) char
        
        bodyInfo
        
        %grid data
        nwCornerLong(1,1) double
        nwCornerLat(1,1) double
        seCornerLong(1,1) double
        seCornerLat(1,1) double
        numPtsLong(1,1) double
        numPtsLat(1,1) double
        altitude(1,1) double
        
        %display
        markerShape(1,1) MarkerStyleEnum = MarkerStyleEnum.Circle;
        markerFoundFaceColor(1,1) ColorSpecEnum = ColorSpecEnum.Green;
        markerFoundEdgeColor(1,1) ColorSpecEnum = ColorSpecEnum.Green;
        markerNotFoundFaceColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        markerNotFoundEdgeColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        markerSize(1,1) double = 3;
        
        lvdData LvdData
    end
    
    methods
        function obj = BodyFixedLatLongGridTargetModel(name, bodyInfo, nwCornerLong, nwCornerLat, seCornerLong, seCornerLat, numPtsLong, numPtsLat, altitude, lvdData)
            arguments
                name(1,:) char
                bodyInfo(1,1) KSPTOT_BodyInfo
                nwCornerLong(1,1) double
                nwCornerLat(1,1) double
                seCornerLong(1,1) double
                seCornerLat(1,1) double
                numPtsLong(1,1) double
                numPtsLat(1,1) double
                altitude(1,1) double
                lvdData(1,1) LvdData
            end
            
            obj.name = name;
            obj.bodyInfo = bodyInfo;
            obj.setGridPointsFromInputs(bodyInfo, nwCornerLong, nwCornerLat, seCornerLong, seCornerLat, numPtsLong, numPtsLat, altitude);
            obj.lvdData = lvdData;
        end
        
        function setGridPointsFromInputs(obj, bodyInfo, nwCornerLong, nwCornerLat, seCornerLong, seCornerLat, numPtsLong, numPtsLat, altitude)
            obj.bodyInfo = bodyInfo;
            
            obj.nwCornerLong = nwCornerLong;
            obj.nwCornerLat = nwCornerLat;
            obj.seCornerLong = seCornerLong;
            obj.seCornerLat = seCornerLat;
            obj.numPtsLong = numPtsLong;
            obj.numPtsLat = numPtsLat;
            obj.altitude = altitude;
            
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
            output = AppDesignerGUIOutput({false});
            lvd_EditLatLongRectGridSensorTargetGUI_App(obj, obj.lvdData, output);
            useTf = output.output{1};
        end
    end
end