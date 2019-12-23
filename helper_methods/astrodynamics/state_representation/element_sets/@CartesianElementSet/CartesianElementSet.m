classdef CartesianElementSet < AbstractElementSet
    %CartesianElementSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        rVect(3,1) double %km
        vVect(3,1) double %km/s
    end
    
    methods
        function obj = CartesianElementSet(time, rVect, vVect, frame)
            obj.time = time;
            obj.rVect = rVect;
            obj.vVect = vVect;
            obj.frame = frame;
        end
        
        function cartElemSet = convertToCartesianElementSet(obj)
            cartElemSet = obj;
        end
        
        function kepElemSet = convertToKeplerianElementSet(obj)
            gmu = obj.frame.getOriginBody().gm;
            [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(obj.rVect, obj.vVect, gmu);
            
            kepElemSet = KeplerianElementSet(obj.time, sma, ecc, inc, raan, arg, tru, obj.frame);
        end
        
        function geoElemSet = convertToGeographicElementSet(obj)
            rNorm = norm(obj.rVect);
            
            long = AngleZero2Pi(atan2(obj.rVect(2),obj.rVect(1)));
            lat = pi/2 - acos(obj.rVect(3)/rNorm);
            alt = rNorm - obj.frame.getOriginBody().radius;
            
            [velAz, velEl, velMag] = cart2sph(obj.vVect(1), obj.vVect(2), obj.vVect(3));
            
            geoElemSet = GeographicElementSet(obj.time, lat, long, alt, velAz, velEl, velMag, obj.frame);
        end
    end
    
    methods(Access=protected)
        function displayScalarObject(obj)
            fprintf('Cartesian State \n\tTime: %0.3f sec UT \n\tPosition: [%0.3f, %0.3f, %0.3f] km \n\tVelocity: [%0.3f, %0.3f, %0.3f] km/s \n\tFrame: %s\n', ...
                    obj.time, ...
                    obj.rVect(1), obj.rVect(2), obj.rVect(3), ...
                    obj.vVect(1), obj.vVect(2), obj.vVect(3), ...
                    obj.frame.getNameStr());
        end        
    end
end