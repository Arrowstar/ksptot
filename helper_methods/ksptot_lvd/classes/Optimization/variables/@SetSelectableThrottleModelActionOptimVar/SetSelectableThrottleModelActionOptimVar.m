classdef SetSelectableThrottleModelActionOptimVar < AbstractOptimizationVariable
    %SetSelectableThrottleModelActionOptimVar Optimization variable for the
    %selectable throttle model.
    %
    %   Mirrors SetGenericSelectableSteeringModelActionOptimVar for a single
    %   throttle branch: element 1 is the shared time offset, the rest
    %   delegate to the currently selected math model.  Two deliberate
    %   differences from the steering version:
    %     * getVarsStoredInRad is all false.  The steering math models
    %       report their constant/coefficient/amplitude elements as stored
    %       in radians, which the variable table would display as degrees.
    %       Throttle coefficients are dimensionless 0-1 fractions.
    %     * updateObjWithVarValue routes the time offset through
    %       setTimeOffset (the steering version calls the getter).

    properties
        varObj = SelectableThrottleModel.getDefaultThrottleModel()

        varTimeOffset(1,1) logical = false;
        tOffsetLb(1,1) double = 0;
        tOffsetUb(1,1) double = 0;
    end

    methods
        function obj = SetSelectableThrottleModelActionOptimVar(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;

            obj.id = rand();
        end

        function numVars = getMaxNumVars(obj)
            numVars = 1 + obj.varObj.throttleMathModel.getNumVars(); %tOffset + branch
        end

        function x = getXsForVariable(obj)
            x = NaN(1,1);

            if(obj.varTimeOffset)
                x(1) = obj.varObj.getTimeOffsets();
            end

            x = [x, obj.varObj.throttleMathModel.getXsForVariable()];

            x(isnan(x)) = [];
        end

        function [lb, ub] = getBndsForVariable(obj)
            useTf = obj.getUseTfForVariable();
            [lb, ub] = obj.getAllBndsForVariable();

            lb = lb(useTf);
            ub = ub(useTf);
        end

        function [lb, ub] = getAllBndsForVariable(obj)
            [branchLb, branchUb] = obj.varObj.throttleMathModel.getBndsForVariable();

            lb = [obj.tOffsetLb, branchLb];
            ub = [obj.tOffsetUb, branchUb];
        end

        function setBndsForVariable(obj, lb, ub)
            numVars = obj.getMaxNumVars();

            if(length(lb) ~= numVars || length(ub) ~= numVars)
                useTf = obj.getUseTfForVariable();

                useLb = NaN(1,numVars);
                useUb = NaN(1,numVars);

                useLb(useTf) = lb;
                useUb(useTf) = ub;
            else
                useLb = lb;
                useUb = ub;
            end

            if(not(isnan(useLb(1))))
                obj.tOffsetLb = useLb(1);
            end

            if(not(isnan(useUb(1))))
                obj.tOffsetUb = useUb(1);
            end

            branchVars = obj.varObj.throttleMathModel.getNumVars();
            inds = 2 : 1 + branchVars;
            obj.varObj.throttleMathModel.setBndsForVariable(useLb(inds), useUb(inds));
        end

        function useTf = getUseTfForVariable(obj)
            useTf = [obj.varTimeOffset, ...
                     obj.varObj.throttleMathModel.getUseTfForVariable()];
            useTf = logical(useTf);
        end

        function setUseTfForVariable(obj, useTf)
            numVars = obj.getMaxNumVars();
            if(numel(useTf) ~= numVars)
                error('SetSelectableThrottleModelActionOptimVar:useTfLengthMismatch', ...
                    'Expected %d variable flags for the %s branch, got %d.  Rebuild the flags after switching the math model type.', ...
                    numVars, obj.varObj.selModel.name, numel(useTf));
            end

            obj.varTimeOffset = useTf(1);
            obj.varObj.throttleMathModel.setUseTfForVariable(useTf(2:end));
        end

        function updateObjWithVarValue(obj, x)
            numVars = obj.getMaxNumVars();

            if(length(x) ~= numVars)
                useTf = obj.getUseTfForVariable();

                useX = NaN(1,numVars);
                useX(useTf) = x;
            else
                useX = x;
            end

            if(obj.varTimeOffset && not(isnan(useX(1))))
                obj.varObj.setTimeOffsets(useX(1));
            end

            branchVars = obj.varObj.throttleMathModel.getNumVars();
            inds = 2 : 1 + branchVars;
            obj.varObj.throttleMathModel.updateObjWithVarValue(useX(inds));
        end

        function nameStrs = getStrNamesOfVars(obj, evtNum, varLocType)
            if(evtNum > 0)
                subStr = sprintf('Event %i',evtNum);
            else
                subStr = varLocType;
            end

            nameStrs = {sprintf('%s Throttle Time Offset', subStr)};

            modelNameStrs = obj.varObj.throttleMathModel.getStrNamesOfVars();
            for(i=1:length(modelNameStrs)) %#ok<*NO4LP>
                nameStrs = horzcat(nameStrs, sprintf('%s Throttle %s', subStr, modelNameStrs{i})); %#ok<AGROW>
            end

            nameStrs = nameStrs(obj.getUseTfForVariable());
        end

        function varsStoredInRad = getVarsStoredInRad(obj)
            %All false by design: throttle math-model coefficients are
            %dimensionless fractions, even though the shared steering math
            %model classes report theirs as stored in radians.
            varsStoredInRad = false(1, obj.getMaxNumVars());
        end

        function varsDisplayedAsPercent = getVarsDisplayedAsPercents(obj)
            %Only the 0-1 throttle fractions display as percents: the
            %constant offset, every polynomial coefficient, and every sine
            %amplitude.  Exponents, periods, phases, linear-tangent
            %parameters and the time offset do not.
            varsDisplayedAsPercent = false(1, obj.getMaxNumVars());

            branch = obj.varObj.throttleMathModel;
            iVar = 2; %element 1 is the time offset
            if(isa(branch, 'SumOfPolyTermsModel'))
                varsDisplayedAsPercent(iVar) = true; %constant offset
                iVar = iVar + 1;

                for(i=1:numel(branch.terms)) %#ok<*NO4LP>
                    varsDisplayedAsPercent(iVar) = true; %coefficient, not exponent
                    iVar = iVar + 2;
                end
            elseif(isa(branch, 'SumOfSinesModel'))
                varsDisplayedAsPercent(iVar) = true; %constant offset
                iVar = iVar + 1;

                for(i=1:numel(branch.sines)) %#ok<*NO4LP>
                    varsDisplayedAsPercent(iVar) = true; %amplitude, not period/phase
                    iVar = iVar + 3;
                end
            end
        end
    end
end
