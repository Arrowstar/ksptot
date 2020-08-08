classdef SunDotNormalDataCache < matlab.mixin.SetGet
    %SunDotNormalDataCache Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bodyInfo KSPTOT_BodyInfo
        
        sunDotNormalFitObj griddedInterpolant = griddedInterpolant([0 1], [0 0]);

        cacheStartTime(1,1) double = NaN;
        cacheEndTime(1,1) double = NaN;
    end
    
    properties(Constant)
        cacheTimeBlockSize(1,1) double = 100000;
        cacheTimeIncr(1,1) double = 1000;
        cacheLongGrid = deg2rad(linspace(0, 360, 37));
    end
    
    methods
        function obj = SunDotNormalDataCache(bodyInfo)
            obj.bodyInfo = bodyInfo;
        end
        
        function sunDotNormal = getCachedBodyStateAtTimeAndLong(obj, time, long)
            %init cache if things are empty
            if(isnan(obj.cacheStartTime) || isnan(obj.cacheEndTime))
                times = [time : obj.cacheTimeIncr : time+obj.cacheTimeBlockSize]; %#ok<NBRAK>
                combTimeLongs = combvec(times,obj.cacheLongGrid)';
                
                sunDotNormal = computeSunDotNormal(combTimeLongs(:,1), combTimeLongs(:,2)', obj.bodyInfo, obj.bodyInfo.celBodyData);
                sunDotNormalR = reshape(sunDotNormal, length(times), length(obj.cacheLongGrid));
                
                obj.sunDotNormalFitObj = griddedInterpolant({times,obj.cacheLongGrid},sunDotNormalR);
                
                obj.cacheStartTime = times(1);
                obj.cacheEndTime = times(end);
            end
            
            %now handle adding to the cache, if needed
            if(time < obj.cacheStartTime)
                numBlocksToAdd = ceil((obj.cacheStartTime - time)/obj.cacheTimeBlockSize);
                
                for(i=1:length(numBlocksToAdd))
                    timesToAdd = [obj.cacheStartTime - 1*obj.cacheTimeBlockSize : obj.cacheTimeIncr : obj.cacheStartTime]; %#ok<NBRAK>
                    timesToAdd = timesToAdd(1:end-1); %don't duplicate the end point

                    obj.addSdnAtTimesToCache(timesToAdd);
                end
            elseif(time > obj.cacheEndTime)
                numBlocksToAdd = ceil((time - obj.cacheEndTime)/obj.cacheTimeBlockSize);
                for(i=1:numBlocksToAdd)
                    timesToAdd = [obj.cacheEndTime : obj.cacheTimeIncr : obj.cacheEndTime + 1*obj.cacheTimeBlockSize]; %#ok<NBRAK>
                    timesToAdd = timesToAdd(2:end); %don't duplicate the start point
                    
                    obj.addSdnAtTimesToCache(timesToAdd);
                end
            end
            
            sunDotNormal = obj.sunDotNormalFitObj(time, long);
        end
    end
    
    methods(Access=private)
        function addSdnAtTimesToCache(obj, times)
            combTimeLongs = combvec(times,obj.cacheLongGrid)';
            sunDotNormal = computeSunDotNormal(combTimeLongs(:,1), combTimeLongs(:,2)', obj.bodyInfo, obj.bodyInfo.celBodyData);
            sunDotNormalR = reshape(sunDotNormal, length(times), length(obj.cacheLongGrid));
            
            timeCache = [obj.sunDotNormalFitObj.GridVectors{1}, times];
            [timeCache,I] = sort(timeCache);
            obj.sunDotNormalFitObj.GridVectors = {timeCache, obj.cacheLongGrid};

            newValues = [obj.sunDotNormalFitObj.Values; sunDotNormalR];
            newValues = newValues(I,:);
            obj.sunDotNormalFitObj.Values = newValues;
            
            obj.cacheStartTime = min(timeCache);
            obj.cacheEndTime = max(timeCache);
        end
    end
end