classdef CelestialBodySunRelStateDataCache < matlab.mixin.SetGet
    %CelestialBodySunRelStateDataCache Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bodyInfo KSPTOT_BodyInfo
        
        times(:,1) double = [];
        stateVects(:,6) double = [];
        relFrame AbstractReferenceFrame
        
        gi %gridded interpolant

        maxTime(1,1) double
        minTime(1,1) double
    end
    
    methods
        function obj = CelestialBodySunRelStateDataCache(bodyInfo)
            obj.bodyInfo = bodyInfo;
        end

        function set.times(obj, newTimes)
            obj.times = newTimes;

            obj.maxTime = max(obj.times); %#ok<MCSUP>
            obj.minTime = min(obj.times); %#ok<MCSUP>
        end
        
        function setStateData(obj, times, stateVects, relFrame)
            obj.times = times;
            obj.stateVects = stateVects;
            obj.relFrame = relFrame;

            obj.maxTime = max(obj.times);
            obj.minTime = min(obj.times);
        
            obj.gi = griddedInterpolant(obj.times, obj.stateVects, 'spline', 'none');
        end
        
        function [rVect, vVect] = getCachedBodyStateAtTime(obj, time)
            bool = numel(obj.times) <= 1 || any(time > obj.maxTime) || any(time < obj.minTime);
            if(bool)
                maxUT = max(obj.times);
                boolMaxUT = maxUT - time < 0;
                worstMaxUTViolation = max(time(boolMaxUT));
                
                minUT = min(obj.times);
                boolMinUT = time - minUT < 0;
                worstMinUTViolation = min(time(boolMinUT));
                
                if(not(isempty(worstMaxUTViolation)) && not(isempty(worstMinUTViolation)))
                    str = sprintf('Adjust the minimum cache UT to below %0.3f sec and the maximum cache UT to above %0.3f sec.', worstMinUTViolation, worstMaxUTViolation);
                    
                elseif(not(isempty(worstMaxUTViolation)))
                    str = sprintf('Adjust the maximum cache UT to above %0.3f sec.', worstMaxUTViolation);
                    
                elseif(not(isempty(worstMinUTViolation)))
                    str = sprintf('Adjust the minimum cache UT to below %0.3f sec.', worstMinUTViolation);
                    
                end
                
                msg = sprintf('At least one of the points in time queried are out of the bounds of the numerical integration (%0.3f sec to %0.3f sec).  %s', min(obj.times), max(obj.times), str);
                
                errordlg(msg, 'Body State Cache Bounds', 'modal');
                error(msg);
            else
                vq = obj.gi(time);
                
                rVect = vq(:,1:3)';
                vVect = vq(:,4:6)';
            end
        end
    end
end