classdef LaunchVehicleGroundObjectWayPt < matlab.mixin.SetGet 
    %LaunchVehicleGroundObjectWayPt Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        elemSet(1,:) GeographicElementSet
        timeToNextWayPt(1,1) double = 0
    end
    
    methods
        function obj = LaunchVehicleGroundObjectWayPt(elemSet, timeToNextWayPt)
            obj.elemSet = elemSet;
            obj.timeToNextWayPt = timeToNextWayPt;
        end
        
        function str = getDisplayStr(obj)
            str = sprintf('Lat: %0.3f deg, Long: %0.3f deg, Alt: %0.3f km', ...
                          rad2deg(obj.getLatitude()), rad2deg(obj.getLongitude()), obj.getAltitude());
        end
        
        function timesToNextWayPt = getTimesToNextWaypt(obj)
            timesToNextWayPt = [obj.timeToNextWayPt];
        end
        
        function gElemSet = getElemSet(obj)
            gElemSet = obj.elemSet;
        end
        
        function lat = getLatitude(obj)
            lat = obj.elemSet.lat;
        end
        
        function long = getLongitude(obj)
            long = obj.elemSet.long;
        end
        
        function alt = getAltitude(obj)
            alt = obj.elemSet.alt;
        end
        
        function setLatitude(obj, newLat)
            obj.elemSet.lat = newLat;
        end
        
        function setLongitude(obj, newLong)
            obj.elemSet.long = newLong;
        end
        
        function setAltitude(obj, newAlt)
            obj.elemSet.alt = newAlt;
        end
    end
    
    methods(Static)
        function wayPt = getDefaultWayPt(initialTime, frameToUse)
            durToNextWayPt1 = 3600;
            elemSet = GeographicElementSet(initialTime + durToNextWayPt1, 0, 0, 0, 0, 0, 0, frameToUse);
            wayPt = LaunchVehicleGroundObjectWayPt(elemSet, durToNextWayPt1);
        end
    end
end

