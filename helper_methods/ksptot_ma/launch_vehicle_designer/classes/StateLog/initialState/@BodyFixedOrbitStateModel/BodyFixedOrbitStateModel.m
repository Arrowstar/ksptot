classdef BodyFixedOrbitStateModel < AbstractOrbitStateModel
    %BodyFixedOrbitStateModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lat(1,1) double
        long(1,1) double
        alt(1,1) double
        
        vVectECEF_x(1,1) double
        vVectECEF_y(1,1) double
        vVectECEF_z(1,1) double
        
        optVar BodyFixedOrbitVariable
    end
    
    methods
        function obj = BodyFixedOrbitStateModel(lat, long, alt, vVectECEF_x, vVectECEF_y, vVectECEF_z)
            obj.lat = deg2rad(lat);
            obj.long = deg2rad(long);
            obj.alt = alt;
            obj.vVectECEF_x = vVectECEF_x;
            obj.vVectECEF_y = vVectECEF_y;
            obj.vVectECEF_z = vVectECEF_z;
        end
        
        function [rVect, vVect] = getPositionAndVelocityVector(obj, ut, bodyInfo)
            vVectECEF = [obj.vVectECEF_x; obj.vVectECEF_y; obj.vVectECEF_z];
            
            [rVect,vVect] = getInertialVectFromLatLongAlt(ut, obj.lat, obj.long, obj.alt, bodyInfo, vVectECEF);
        end
        
        function elemVect = getElementVector(obj)
            elemVect = [rad2deg(obj.lat),rad2deg(obj.long),obj.alt,obj.vVectECEF_x,obj.vVectECEF_y,obj.vVectECEF_z];
        end
    end
    
    methods(Static)
        function defaultOrbitState = getDefaultOrbitState()
            defaultOrbitState = BodyFixedOrbitStateModel(0, 0, 0, 0, 0, 0);
        end
        
        function errMsg = validateInputOrbit(errMsg, hLat, hLong, hAlt, hBfVx, hBfVy, hBfVz, bodyInfo, bndStr)
            if(isempty(bndStr))
                bndStr = '';
            else
                bndStr = sprintf(' (%s Bound)', bndStr);
            end
            
            lat = str2double(get(hLat,'String'));
            enteredStr = get(hLat,'String');
            numberName = ['Latitude', bndStr];
            lb = -90;
            ub = 90;
            isInt = false;
            errMsg = validateNumber(lat, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            long = str2double(get(hLong,'String'));
            enteredStr = get(hLong,'String');
            numberName = ['Longitude', bndStr];
            lb = -360;
            ub = 360;
            isInt = false;
            errMsg = validateNumber(long, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            alt = str2double(get(hAlt,'String'));
            enteredStr = get(hAlt,'String');
            numberName = ['Altitude', bndStr];
            lb = -bodyInfo.radius;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(alt, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            bfVx = str2double(get(hBfVx,'String'));
            enteredStr = get(hBfVx,'String');
            numberName = ['Body-Fixed Velocity (X)', bndStr];
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(bfVx, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            bfVy = str2double(get(hBfVy,'String'));
            enteredStr = get(hBfVy,'String');
            numberName = ['Body-Fixed Velocity (Y)', bndStr];
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(bfVy, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            bfVz = str2double(get(hBfVz,'String'));
            enteredStr = get(hBfVz,'String');
            numberName = ['Body-Fixed Velocity (Z)', bndStr];
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(bfVz, numberName, lb, ub, isInt, errMsg, enteredStr);
        end
    end
end