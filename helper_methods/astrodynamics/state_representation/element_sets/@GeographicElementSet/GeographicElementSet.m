classdef GeographicElementSet < AbstractElementSet
    %GeographicElementSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lat%(1,1) double %rad
        long%(1,1) double %rad
        alt%(1,1) double %km
        velAz%(1,1) double %rad NEZ frame
        velEl%(1,1) double %rad NEZ frame
        velMag%(1,1) double %km/s NEZ frame
        
        optVar GeographicElementSetVariable
    end
    
    properties(Constant)
        typeEnum = ElementSetEnum.GeographicElements;
    end
    
    methods
        function obj = GeographicElementSet(time, lat, long, alt, velAz, velEl, velMag, frame)
            if(nargin > 0)
                obj.time = time;
                obj.lat = lat;
                obj.long = long;
                obj.alt = alt;
                obj.velAz = velAz;
                obj.velEl = velEl;
                obj.velMag = velMag;
                obj.frame = frame;
            end
        end
        
        %vectorized
        function cartElemSet = convertToCartesianElementSet(obj)
            radius = NaN(1, length(obj));
            for(i=1:length(obj))
                radius(i) = obj(i).frame.getOriginBody().radius;
            end
            r = radius + [obj.alt];

            x = r.*cos([obj.lat]).*cos([obj.long]);
            y = r.*cos([obj.lat]).*sin([obj.long]);
            z = r.*sin([obj.lat]);

            rVect = [x;y;z];
            
            sezVVectAz = pi - [obj.velAz];
            sezVVectEl = [obj.velEl];
            sezVVectMag = [obj.velMag];

            [x,y,z] = sph2cart(sezVVectAz, sezVVectEl, sezVVectMag);
            vectorSez = [x;y;z];
            vVect = rotSEZVectToECEFCoords(rVect, vectorSez); %not necessarily ECEF coords here but the transform holds
            
%             cartElemSet = CartesianElementSet(obj.time, rVect, vVect, obj.frame);
%             cartElemSet = repmat(CartesianElementSet.getDefaultElements(), size(obj));
%             for(i=1:length(obj))
%                 cartElemSet(i) = CartesianElementSet(obj(i).time, rVect(:,i), vVect(:,i), obj(i).frame);
%             end

            obj = obj(:)';
            cartElemSet = CartesianElementSet([obj.time], rVect, vVect, [obj.frame]);
        end
        
        %vectorized
        function kepElemSet = convertToKeplerianElementSet(obj)
            kepElemSet = convertToKeplerianElementSet(convertToCartesianElementSet(obj));
        end
        
        %vectorized
        function geoElemSet = convertToGeographicElementSet(obj)
            geoElemSet = obj;
        end
        
        %vectorized
        function univElemSet = convertToUniversalElementSet(obj)
            univElemSet = convertToUniversalElementSet(convertToKeplerianElementSet(obj));
        end
        
        function elemVect = getElementVector(obj)
            elemVect = [rad2deg(obj.lat),rad2deg(obj.long),obj.alt,rad2deg(obj.velAz),rad2deg(obj.velEl),obj.velMag];
        end
        
        function newElemSet = copyWithoutOptVar(obj)
            newElemSet = GeographicElementSet(obj.time, obj.lat, obj.long, obj.alt, obj.velAz, obj.velEl, obj.velMag, obj.frame);
        end
    end
    
    methods(Access=protected)
        function displayScalarObject(obj)
            fprintf('Geographic State \n\tTime: %0.3f sec UT \n\tLatitude: %0.3f deg \n\tLongitude: %0.3f deg \n\tAltitude: %0.3f km \n\tVel Az (NEZ): %0.3f deg \n\tVel El (NEZ): %0.3f deg \n\tVel Mag (NEZ): %0.3f km/s \n\tFrame: %s\n', ...
                    obj.time, ...
                    rad2deg(obj.lat), ...
                    rad2deg(obj.long), ...
                    obj.alt, ...
                    rad2deg(obj.velAz), ...
                    rad2deg(obj.velEl), ...
                    obj.velMag, ...
                    obj.frame.getNameStr());
        end        
    end
    
    methods(Static)
        function elemSet = getDefaultElements()
            elemSet = GeographicElementSet();
        end
        
        function errMsg = validateInputOrbit(errMsg, hLat, hLong, hAlt, hVelAz, hVelEl, hVelMag, bodyInfo, bndStr, checkElement)
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
                bfVx = str2double(get(hVelAz,'String'));
                enteredStr = get(hVelAz,'String');
                numberName = ['Body-Fixed Velocity Azimuth', bndStr];
                lb = -360;
                ub = 360;
                isInt = false;
                errMsg = validateNumber(bfVx, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(5))
                bfVy = str2double(get(hVelEl,'String'));
                enteredStr = get(hVelEl,'String');
                numberName = ['Body-Fixed Velocity Elevation', bndStr];
                lb = -90;
                ub = 90;
                isInt = false;
                errMsg = validateNumber(bfVy, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(6))
                bfVz = str2double(get(hVelMag,'String'));
                enteredStr = get(hVelMag,'String');
                numberName = ['Body-Fixed Velocity Magnitude', bndStr];
                lb = 0;
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(bfVz, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
        end
    end
end