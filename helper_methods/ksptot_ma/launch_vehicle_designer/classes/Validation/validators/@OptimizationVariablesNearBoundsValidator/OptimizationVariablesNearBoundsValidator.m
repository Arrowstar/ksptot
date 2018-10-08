classdef OptimizationVariablesNearBoundsValidator < AbstractLaunchVehicleDataValidator
    %NoOptimizationVariablesValidator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
    end
    
    methods
        function obj = OptimizationVariablesNearBoundsValidator(lvdData)
            obj.lvdData = lvdData;
        end
        
        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);
            
            varSet = obj.lvdData.optimizer.vars;
            [x,vars] = varSet.getTotalXVector();
            [lb, ub] = varSet.getTotalBndsVector();
            
            warnInd = [];
            for(i=1:length(x)) %#ok<*NO4LP>
                normX = (x(i) - lb(i)) / (ub(i) - lb(i));
                
                if(normX >= 0.99 || normX <= 0.01 || (ub(i) == lb(i) && x(i) == lb(i)))
                    warnInd(end+1) = i; %#ok<AGROW>
                end
            end
            
            if(isempty(warnInd))
                return;
            end
            
            lv = obj.lvdData.launchVehicle;
            [lvVars,~] = lv.getActiveOptVars();
            useLv = false;
            inds = find(ismember(vars,lvVars));
            if(not(isempty(inds)))
                if(ismember(inds,warnInd))
                    useLv = true;
                end
            end
            
            
            initStateModel = obj.lvdData.initStateModel;
            initStateModelOptVars = initStateModel.getAllOptVars();
            useInitState = false;
            if(not(isempty(initStateModelOptVars)))
                inds = zeros(size(vars));
                for(i=1:length(initStateModelOptVars))
                    inds = inds | ismember(vars,initStateModelOptVars(i));
                end
                
                inds = find(inds);
                if(not(isempty(inds)))
                    if(any(ismember(inds,warnInd)))
                        useInitState = true;
                    end
                end
            end
            
            eventNums = [];
            
            numEvents = obj.lvdData.script.getTotalNumOfEvents();
            for(i=1:numEvents)
                event = obj.lvdData.script.getEventForInd(i);
                [tf, eVars] = event.hasActiveOptVars();
                
                if(tf)
                    inds = zeros(size(vars));
                    for(j=1:length(eVars))
                        inds = inds | ismember(vars,eVars(j));
                    end

                    if(not(isempty(inds)))
                        if(ismember(inds,warnInd))
                            eventNums(end+1) = i; %#ok<AGROW>
                        end
                    end
                end
            end
            
            if(not(isempty(eventNums)))
                eventStr = makeEventsStr(eventNums);
            else
                eventStr = '';
            end
            
            combStrCell = {};
            if(useLv)
                combStrCell{end+1} = 'Launch Vehicle';
            end
            
            if(useInitState)
                combStrCell{end+1} = 'Initial State';
            end
            
            combStr = strjoin(combStrCell,', ');
            if(not(isempty(combStr)))
                combStr = sprintf('%s, ',combStr);
            end

            str = sprintf('Variables are near optimization bounds on some events (Events: %s%s)', combStr, eventStr);
            warnings(end+1) = LaunchVehicleDataValidationWarning(str);
        end
    end
end