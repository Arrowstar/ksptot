classdef AtmoTempDataCache < matlab.mixin.SetGet
    %AtmoTempDataCache Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bodyInfo KSPTOT_BodyInfo
        cacheAltGrid double
        
        cacheTimeBlockSize(1,1) double = NaN;
        cacheTimeIncr(1,1) double = NaN;
    end
    
    properties(Constant)       
        cacheLatGrid double = deg2rad(-90:10:90);
        cacheLongGrid double = deg2rad(0:10:360);
    end
    
    properties(Transient)
        atmoTempFitObj griddedInterpolant = griddedInterpolant([0 1], [0 0]);

        cacheStartTime(1,1) double = NaN;
        cacheEndTime(1,1) double = NaN;
    end
    
    methods
        function obj = AtmoTempDataCache(bodyInfo)
            obj.bodyInfo = bodyInfo;
        end
        
        function atmoTemp = getAtmoTemperature(obj, time, lat, long, alt)
            if(isnan(obj.cacheTimeBlockSize))
                obj.cacheAltGrid = linspace(0, obj.bodyInfo.atmohgt, 20);
                obj.cacheTimeIncr = obj.bodyInfo.rotperiod/10;
                obj.cacheTimeBlockSize = 1000*obj.cacheTimeIncr;
            end
            
            %init cache if things are empty
            if(isnan(obj.cacheStartTime) || isnan(obj.cacheEndTime))
                times = [time : obj.cacheTimeIncr : time+obj.cacheTimeBlockSize]; %#ok<NBRAK>
                lats = obj.cacheLatGrid;
                longs = obj.cacheLongGrid;
                alts = obj.cacheAltGrid;
                
                combVects = combvec(times,lats,longs,alts)';
                
%                 data = obj.bodyInfo.getBodyAtmoTemperature(combVects(:,1), combVects(:,2), combVects(:,3), combVects(:,4));
                data = getTemperatureAtAltitude(obj.bodyInfo, combVects(:,4), combVects(:,2), combVects(:,1), combVects(:,3));
                dataRS = reshape(data, [length(times), length(lats), length(longs), length(alts)]);
                
                obj.atmoTempFitObj = griddedInterpolant({times,lats,longs,alts},dataRS,'linear');
                
                obj.cacheStartTime = times(1);
                obj.cacheEndTime = times(end);
                clear combVects;
            end
            
            %now handle adding to the cache, if needed
            if(time < obj.cacheStartTime)
                numBlocksToAdd = ceil((obj.cacheStartTime - time)/obj.cacheTimeBlockSize);
                
                for(i=1:numBlocksToAdd)
                    timesToAdd = [obj.cacheStartTime - 1*obj.cacheTimeBlockSize : obj.cacheTimeIncr : obj.cacheStartTime]; %#ok<NBRAK>
                    timesToAdd = timesToAdd(1:end-1); %don't duplicate the end point

                    obj.addDataAtTimesToCache(timesToAdd);
                end
            elseif(time > obj.cacheEndTime)
                numBlocksToAdd = ceil((time - obj.cacheEndTime)/obj.cacheTimeBlockSize);
                
                for(i=1:numBlocksToAdd)
                    timesToAdd = [obj.cacheEndTime : obj.cacheTimeIncr : obj.cacheEndTime + 1*obj.cacheTimeBlockSize]; %#ok<NBRAK>
                    timesToAdd = timesToAdd(2:end); %don't duplicate the start point
                    
                    obj.addDataAtTimesToCache(timesToAdd);
                end
            end
            
            atmoTemp = obj.atmoTempFitObj(time, lat, long, alt);
        end
    end
    
    methods(Access=private)
        function addDataAtTimesToCache(obj, times)
            lats = obj.cacheLatGrid;
            longs = obj.cacheLongGrid;
            alts = obj.cacheAltGrid;

            combVects = combvec(times,lats,longs,alts)';

%             data = obj.bodyInfo.getBodyAtmoTemperature(combVects(:,1), combVects(:,2), combVects(:,3), combVects(:,4));
            data = getTemperatureAtAltitude(obj.bodyInfo, combVects(:,4), combVects(:,2), combVects(:,1), combVects(:,3));
            dataRS = reshape(data, [length(times), length(lats), length(longs), length(alts)]);
            clear combVects;
            
            timeCache = [obj.atmoTempFitObj.GridVectors{1}, times];
            [timeCache,I] = sort(timeCache);
            obj.atmoTempFitObj.GridVectors = {timeCache, lats, longs, alts};

            newValues = [obj.atmoTempFitObj.Values; dataRS];
            newValues = newValues(I,:,:,:);
            obj.atmoTempFitObj.Values = newValues;

            obj.cacheStartTime = min(timeCache);
            obj.cacheEndTime = max(timeCache);
        end
    end
    
    methods(Static)
        function obj = loadobj(obj)
            if(isempty(obj.atmoTempFitObj))
                obj.atmoTempFitObj = griddedInterpolant([0 1], [0 0]);
                
                obj.cacheStartTime = NaN;
                obj.cacheEndTime = NaN;
            end
        end
    end
end