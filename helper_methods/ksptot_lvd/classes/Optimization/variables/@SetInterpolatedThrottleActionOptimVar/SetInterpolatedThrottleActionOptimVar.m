 classdef SetInterpolatedThrottleActionOptimVar < AbstractOptimizationVariable
    %SetInterpolatedThrottleActionOptimVar Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj = ThrottleInterpolatedModel.getDefaultThrottleModel()
                
        %Var Flags
        varThrottle0(1,1) logical = false;
        varTDur(:,1) logical = false;
        varThrottles(:,1) logical = false;

        %Lower Bounds
        lbThrottle0(1,1) double = 0;
        lbTDur(:,1) double = 0;
        lbThrottles(:,1) double = 0;

        %Upper Bounds
        ubThrottle0(1,1) double = 1;
        ubTDur(:,1) double = 1;
        ubThrottles(:,1) double = 1;
    end
    
    methods
        function obj = SetInterpolatedThrottleActionOptimVar(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            obj.id = rand();
        end
        
        function x = getXsForVariable(obj)            
            xInitState = NaN(1, 1);           
            if(obj.varThrottle0)
                xInitState = obj.varObj.initThrottle;
            end

            numTabularVarRows = numel(obj.varTDur);
    
            xTDur = NaN(1, numTabularVarRows);
            xTDur(obj.varTDur) = obj.varObj.durations(obj.varTDur);

            xThrottles = NaN(1, numTabularVarRows);
            xThrottles(obj.varThrottles) = obj.varObj.throttles(obj.varThrottles);

            x = [xInitState, xTDur, xThrottles];
            
            x(isnan(x)) = [];
        end
        
        function [lb, ub] = getBndsForVariable(obj)            
            useTf = obj.getUseTfForVariable();

            [lb, ub] = obj.getAllBndsForVariable();
            lb = lb(useTf);
            ub = ub(useTf);
        end
        
        function [lb, ub] = getAllBndsForVariable(obj)
            lb = [obj.lbThrottle0, ...
                  obj.lbTDur(:)', ...
                  obj.lbThrottles(:)'];

            ub = [obj.ubThrottle0, ...
                  obj.ubTDur(:)', ...
                  obj.ubThrottles(:)'];
        end
        
        function setBndsForVariable(obj, lb, ub)
            ind = 1;
            if(obj.varThrottle0)
                obj.lbThrottle0 = lb(ind);
                obj.ubThrottle0 = ub(ind);
                ind = ind + 1;
            end

            if(any(obj.varTDur))
                inds = ind:ind+sum(obj.varTDur)-1;
                obj.lbTDur(obj.varTDur) = lb(inds);
                obj.ubTDur(obj.varTDur) = ub(inds);
                ind = inds(end)+1;
            end
            if(any(obj.varThrottles))
                inds = ind:ind+sum(obj.varThrottles)-1;
                obj.lbThrottles(obj.varThrottles) = lb(inds);
                obj.ubThrottles(obj.varThrottles) = ub(inds);
            end
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = [obj.varThrottle0, ...
                     obj.varTDur(:)', ...
                     obj.varThrottles(:)'];
        end
        
        function setUseTfForVariable(obj, useTf) 
            obj.varThrottle0 = useTf(1);

            numTabularVarRows = (numel(useTf)-1)/2;

            inds = 2 : 2+numTabularVarRows-1;
            obj.varTDur = useTf(inds);

            inds = inds(end)+1 : inds(end)+numTabularVarRows;
            obj.varThrottles = useTf(inds);
        end
        
        function updateObjWithVarValue(obj, x)
            ind = 1;

            if(obj.varThrottle0)
                obj.varObj.initThrottle = x(ind);
                ind = ind + 1;
            end

            if(any(obj.varTDur))
                inds = ind:ind+sum(obj.varTDur)-1;
                obj.varObj.durations(obj.varTDur) = x(inds);
                ind = inds(end)+1;
            end
            if(any(obj.varThrottles))
                inds = ind:ind+sum(obj.varThrottles)-1;
                obj.varObj.throttles(obj.varThrottles) = x(inds);
            end
        end
        
        function nameStrs = getStrNamesOfVars(obj, evtNum, varLocType)
           if(evtNum > 0)
                subStr = sprintf('Event %i',evtNum);
            else
                subStr = varLocType;
            end
            
            nameStrs = {sprintf('%s Initial Throttle', subStr)};

            numTabularVarRows = numel(obj.varTDur);
            for(i=1:numTabularVarRows)
                nameStrs = horzcat(nameStrs, ...
                                   {sprintf('%s Throttle Table Row %u Duration', subStr, i)}); %#ok<AGROW>
            end

            for(i=1:numTabularVarRows)
                nameStrs = horzcat(nameStrs, ...
                                   {sprintf('%s Throttle Table Row %u Throttle', subStr, i)}); %#ok<AGROW>
            end

            nameStrs = nameStrs(obj.getUseTfForVariable());
        end
    end
end