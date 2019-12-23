classdef GeographicElementSet < AbstractElementSet
    %GeographicElementSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lat(1,1) double %rad
        long(1,1) double %rad
        alt(1,1) double %km
        velAz(1,1) double %rad NEZ frame
        velEl(1,1) double %rad NEZ frame
        velMag(1,1) double %km/s NEZ frame
    end
    
    methods
        function obj = GeographicElementSet(time, lat, long, alt, velAz, velEl, velMag, frame)
            obj.time = time;
            obj.lat = lat;
            obj.long = long;
            obj.alt = alt;
            obj.velAz = velAz;
            obj.velEl = velEl;
            obj.velMag = velMag;
            obj.frame = frame;
        end
        
        function cartElemSet = convertToCartesianElementSet(obj)
            r = obj.frame.getOriginBody().radius + obj.alt;

            x = r.*cos(obj.lat).*cos(obj.long);
            y = r.*cos(obj.lat).*sin(obj.long);
            z = r.*sin(obj.lat);

            rVect = [x;y;z];
            
            sezVVectAz = pi - obj.velAz;
            sezVVectEl = obj.velEl;
            sezVVectMag = obj.velMag;

            [x,y,z] = sph2cart(sezVVectAz, sezVVectEl, sezVVectMag);
            vectorSez = [x;y;z];
            vVect = rotSEZVectToECEFCoords(rVect, vectorSez); %not necessarily ECEF coords here but the transform holds
            
%             [vx,vy,vz] = sph2cart(obj.velAz, obj.velEl, obj.velMag);
%             vVect = [vx;vy;vz];
            
            cartElemSet = CartesianElementSet(obj.time, rVect, vVect, obj.frame);
        end
        
        function kepElemSet = convertToKeplerianElementSet(obj)
            kepElemSet = obj.convertToCartesianElementSet().convertToKeplerianElementSet();
        end
        
        function geoElemSet = convertToGeographicElementSet(obj)
            geoElemSet = obj;
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
end