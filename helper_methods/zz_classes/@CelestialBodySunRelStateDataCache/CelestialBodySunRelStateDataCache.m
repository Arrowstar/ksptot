classdef CelestialBodySunRelStateDataCache < matlab.mixin.SetGet
    %CelestialBodySunRelStateDataCache Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bodyInfo KSPTOT_BodyInfo
        
        times(:,1) double = [];
        stateVects(:,6) double = [];
        relFrame AbstractReferenceFrame
        
        gi %gridded interpolant
    end
    
    methods
        function obj = CelestialBodySunRelStateDataCache(bodyInfo)
            obj.bodyInfo = bodyInfo;
        end
        
        function setStateData(obj, times, stateVects, relFrame)
            obj.times = times;
            obj.stateVects = stateVects;
            obj.relFrame = relFrame;
            
            obj.gi = griddedInterpolant(obj.times, obj.stateVects, 'spline');
        end
        
        function [rVect, vVect] = getCachedBodyStateAtTime(obj, time)
            if(numel(obj.times) <= 1 || any(time > max(obj.times)) || any(time < min(obj.times)))
                error('At least one of the points in time queried are out of the bounds of the numerical integration: %0.3f sec to %0.3f sec', min(obj.times), max(obj.times));
                
            else
                vq = obj.gi(time);
                
                rVect = vq(:,1:3)';
                vVect = vq(:,4:6)';
            end
        end
    end
end