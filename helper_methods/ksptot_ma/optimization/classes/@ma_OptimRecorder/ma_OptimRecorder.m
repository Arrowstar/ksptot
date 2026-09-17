classdef ma_OptimRecorder < matlab.mixin.SetGet
    %ma_OptimRecorder Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        iterNums = [];
        xVals = cell(0,1);
        fVals = [];
        maxCVal = [];

        %Per-iteration constraint history (LVD).  cVals{k} is the full
        %[c, ceq] row vector at iteration k; cNames labels each element;
        %ceqMask is true for equality rows.  All three stay empty for
        %recorders that only track the maximum violation (Mission Architect).
        cVals = cell(0,1);
        cNames = {};
        ceqMask = logical([]);

        %Set by the LVD optimizers before the first output-function call so
        %the observe window can be laid out with a constraint-history tile
        %from the start (TiledChartLayout cannot be resized once populated).
        expectConstraintHistory(1,1) logical = false;
    end
    
    methods
        function recordConstraintValues(obj, c, ceq, names)
            %recordConstraintValues Appends one iteration's constraint vector.
            %   names is only stored the first time (or when the vector length
            %   changes) so callers can pass it every iteration cheaply.
            row = [c(:)', ceq(:)'];

            if(isempty(obj.cNames) || numel(obj.cNames) ~= numel(row))
                if(nargin >= 4 && numel(names) == numel(row))
                    obj.cNames = names(:)';
                else
                    obj.cNames = arrayfun(@(i) sprintf('Constraint %u', i), 1:numel(row), 'UniformOutput', false);
                end
                obj.ceqMask = [false(1, numel(c)), true(1, numel(ceq))];
            end

            obj.cVals{end+1,1} = row;
        end

        function tf = hasConstraintHistory(obj)
            tf = not(isempty(obj.cVals)) && any(cellfun(@(r) not(isempty(r)), obj.cVals));
        end

        function [violations, names, iters] = getConstraintViolationHistory(obj)
            %getConstraintViolationHistory Violation matrix [numIters x numConstraints].
            %   Inequality rows report max(0, c); equality rows report abs(ceq).
            %   Iterations whose stored vector has a different length than the
            %   current names are padded with NaN.
            names = obj.cNames;
            numC = numel(names);
            numIters = numel(obj.cVals);
            violations = NaN(numIters, numC);

            for(k = 1:numIters) %#ok<*NO4LP>
                row = obj.cVals{k};
                if(numel(row) ~= numC)
                    continue;
                end

                v = row;
                v(not(obj.ceqMask)) = max(0, v(not(obj.ceqMask)));
                v(obj.ceqMask) = abs(v(obj.ceqMask));
                violations(k, :) = v;
            end

            if(numel(obj.iterNums) == numIters)
                iters = obj.iterNums(:)';
            else
                iters = 1:numIters;
            end
        end

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