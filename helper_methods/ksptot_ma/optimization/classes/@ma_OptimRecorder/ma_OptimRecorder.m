classdef ma_OptimRecorder < matlab.mixin.SetGet
    %ma_OptimRecorder Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        iterNums = [];
        xVals = cell(0,1);
        fVals = [];
        maxCVal = [];
    end
    
    methods
        function [iterNum, xVals, fVal, maxCVal] = getIterWithLowestFVal(obj)
            [fVal,I] = min(obj.fVals);
            
            inds = find(obj.fVals == fVal & not(isnan(obj.fVals)));
            if(isempty(inds))
                inds = find(obj.fVals == fVal);
            end
            
            if(length(inds) > 1)
                minCVal = obj.maxCVal(inds(1));
                for(i=1:length(inds)) %#ok<*NO4LP>
                    if(obj.maxCVal(inds(i)) < minCVal)
                        minCVal = obj.maxCVal(inds(i));
                        I = inds(i);
                    end
                end
            end
            
            iterNum = obj.iterNums(I);
            xVals = obj.xVals{I};
            fVal = obj.fVals(I);
            maxCVal = obj.maxCVal(I);
        end
        
        function [iterNum, xVals, fVal, maxCVal] = getIterWithLowestCVal(obj)
            obj.maxCVal(isnan(obj.fVals)) = NaN;
            
            [minCVal,I] = min(obj.maxCVal);
            
            inds = find(obj.maxCVal == minCVal & not(isnan(obj.fVals)));
            if(isempty(inds))
                inds = find(obj.maxCVal == minCVal);
            end            
            
            if(length(inds) > 1)
                minFVal = obj.fVals(inds(1));
                for(i=1:length(inds)) %#ok<*NO4LP>
                    if(obj.fVals(inds(i)) < minFVal)
                        minFVal = obj.fVals(inds(i));
                        I = inds(i);
                    end
                end
            end
            
            iterNum = obj.iterNums(I);
            xVals = obj.xVals{I};
            fVal = obj.fVals(I);
            maxCVal = obj.maxCVal(I);
        end
        
        function [iterNum, xVals, fVal, maxCVal] = getLastIter(obj)
            iterNum = obj.iterNums(end);
            xVals = obj.xVals{end};
            fVal = obj.fVals(end);
            maxCVal = obj.maxCVal(end);
        end
    end
end