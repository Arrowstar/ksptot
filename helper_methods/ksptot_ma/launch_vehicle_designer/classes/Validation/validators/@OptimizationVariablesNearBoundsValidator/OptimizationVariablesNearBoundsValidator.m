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
            
            eventNums = [];
            useLv = false;
            useIs = false;
            for(i=1:length(warnInd))
                var = vars(warnInd(i));
                
                evtNum = getEventNumberForVar(var, obj.lvdData);
                useLv = useLv | isVarInLaunchVehicle(var, obj.lvdData);
                useIs = useIs | isVarInInitialState(var, obj.lvdData);
                eventNums = horzcat(eventNums,evtNum); %#ok<AGROW>
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
            
            if(useIs)
                combStrCell{end+1} = 'Initial State';
            end
            
            if(not(isempty(eventStr)))
                combStrCell{end+1} = eventStr;
            end
            
            combStr = strjoin(combStrCell,', ');
            if(not(isempty(combStr)))
                combStr = sprintf('%s',combStr);
            end

            str = sprintf('Variables are near optimization bounds on some events (Events: %s)', combStr);
            warnings(end+1) = LaunchVehicleDataValidationWarning(str);
        end
    end
end

function evtNum = getEventNumberForVar(var, lvdData)
    evtNum = [];
    
    numEvents = lvdData.script.getTotalNumOfEvents();
    for(i=1:numEvents)
        event = lvdData.script.getEventForInd(i);
        
        [~, eVars] = event.hasActiveOptVars();
        
        for(j=1:length(eVars))
            eVar = eVars(j);
            
            if(strcmpi(class(var), class(eVar)) && var == eVar)
                evtNum = i;
                break;
            end
        end
        
        if(not(isempty(evtNum)))
            break;
        end
    end
end

function tf = isVarInLaunchVehicle(var, lvdData)
    lv = lvdData.launchVehicle;
    [lvVars,~] = lv.getActiveOptVars();
    
    tf = false;
    for(i=1:length(lvVars))
        lvVar = lvVars(i);
        
        if(var == lvVar)
            tf = true;
            break;
        end
    end
end

function tf = isVarInInitialState(var, lvdData)
    initStateModel = lvdData.initStateModel;
    initStateModelOptVars = initStateModel.getAllOptVars();
    
    tf = false;
    for(i=1:length(initStateModelOptVars))
        isVar = initStateModelOptVars(i);

        if(var == isVar)
            tf = true;
            break;
        end
    end
end