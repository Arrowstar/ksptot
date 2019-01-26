classdef BodyFixedOrbitStateModel < AbstractOrbitStateModel
    %BodyFixedOrbitStateModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lat(1,1) double
        long(1,1) double
        alt(1,1) double
        
        vVectNEZ_az(1,1) double
        vVectNEZ_el(1,1) double
        vVectNEZ_mag(1,1) double
        
        optVar BodyFixedOrbitVariable
    end
    
    methods
        function obj = BodyFixedOrbitStateModel(lat, long, alt, vVectNEZ_az, vVectNEZ_el, vVectNEZ_mag)
            obj.lat = deg2rad(lat);
            obj.long = deg2rad(long);
            obj.alt = alt;
            obj.vVectNEZ_az = deg2rad(vVectNEZ_az);
            obj.vVectNEZ_el = deg2rad(vVectNEZ_el);
            obj.vVectNEZ_mag = vVectNEZ_mag;
        end
        
        function [rVect, vVect] = getPositionAndVelocityVector(obj, ut, bodyInfo)
%             vVectECEF = [obj.vVectECEF_x; obj.vVectECEF_y; obj.vVectECEF_z];
            rVectECEF = getrVectEcefFromLatLongAlt(obj.lat, obj.long, obj.alt, bodyInfo);
            
            sezVVectAz = pi - obj.vVectNEZ_az;
            sezVVectEl = obj.vVectNEZ_el;
            sezVVectMag = obj.vVectNEZ_mag;
            
            [x,y,z] = sph2cart(sezVVectAz, sezVVectEl, sezVVectMag);
            vectorSez = [x;y;z];
            vVectECEF = rotSEZVectToECEFCoords(rVectECEF, vectorSez);
            
            [rVect,vVect] = getInertialVectFromLatLongAlt(ut, obj.lat, obj.long, obj.alt, bodyInfo, vVectECEF);
        end
        
        function elemVect = getElementVector(obj)
            elemVect = [rad2deg(obj.lat),rad2deg(obj.long),obj.alt,rad2deg(obj.vVectNEZ_az),rad2deg(obj.vVectNEZ_el),obj.vVectNEZ_mag];
        end
    end
    
    methods(Static)
        function defaultOrbitState = getDefaultOrbitState()
            defaultOrbitState = BodyFixedOrbitStateModel(0, 0, 0, 0, 0, 0);
        end
        
        function errMsg = validateInputOrbit(errMsg, hLat, hLong, hAlt, hBfVx, hBfVy, hBfVz, bodyInfo, bndStr, checkElement)
            if(isempty(bndStr))
                bndStr = '';
            else
                bndStr = sprintf(' (%s Bound)', bndStr);
            end
            
            if(checkElement(1))
                lat = str2double(get(hLat,'String'));
                enteredStr = get(hLat,'String');
                numberName = ['Latitude', bndStr];
                lb = -90;
                ub = 90;
                isInt = false;
                errMsg = validateNumber(lat, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(2))
                long = str2double(get(hLong,'String'));
                enteredStr = get(hLong,'String');
                numberName = ['Longitude', bndStr];
                lb = -360;
                ub = 360;
                isInt = false;
                errMsg = validateNumber(long, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(3))
                alt = str2double(get(hAlt,'String'));
                enteredStr = get(hAlt,'String');
                numberName = ['Altitude', bndStr];
                lb = -bodyInfo.radius;
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(alt, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(4))
                bfVx = str2double(get(hBfVx,'String'));
                enteredStr = get(hBfVx,'String');
                numberName = ['Body-Fixed Velocity Azimuth', bndStr];
                lb = -360;
                ub = 360;
                isInt = false;
                errMsg = validateNumber(bfVx, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(5))
                bfVy = str2double(get(hBfVy,'String'));
                enteredStr = get(hBfVy,'String');
                numberName = ['Body-Fixed Velocity Elevation', bndStr];
                lb = -90;
                ub = 90;
                isInt = false;
                errMsg = validateNumber(bfVy, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(6))
                bfVz = str2double(get(hBfVz,'String'));
                enteredStr = get(hBfVz,'String');
                numberName = ['Body-Fixed Velocity Magnitude', bndStr];
                lb = 0;
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(bfVz, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
        end
    end
end