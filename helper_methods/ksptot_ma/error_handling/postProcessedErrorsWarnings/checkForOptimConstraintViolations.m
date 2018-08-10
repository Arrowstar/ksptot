function checkForOptimConstraintViolations(maData, celBodyData)
%checkForOptimConstraintViolations Summary of this function goes here
%   Detailed explanation goes here

    if(isempty(maData))
        return;
    end

    x = [];
    for(i=1:length(maData.script))
        event = maData.script{i};
        
        if(~isfield(event,'vars') || all(event.vars(1,:)==0))
            continue;
        else
            x1 = ma_getX0ForEvent(event);
            x1 = reshape(x1, 1, length(x1));
            x = [x, x1]; %#ok<AGROW>
        end
    end
    
	if(isempty(maData.optimizer.constraints) || ...
        isempty(maData.optimizer.problem))
        addToExecutionWarnings('Optimization constraint analysis not available.  Run optimizer first.', -1, -1, celBodyData);
        return;
	end
    
    if(isempty(maData.optimizer.problem.nonlcon))
        return;
    end
    
    consts = maData.optimizer.constraints{1};
%     [~,~,~,~,~,~,~] = maData.optimizer.problem.nonlcon(maData.optimizer.problem.x0);
    [c, ceq, values, lbs, ubs, types, eventNums] = maData.optimizer.problem.nonlcon(x);
    
    unitStrs = {};
    for(i=1:size(consts,1))
        constData = consts{i,5};
        lbActive = constData(9);
        ubActive = constData(10);
        
        if(lbActive || ubActive)
            unitStrs{end+1} = strtrim(consts{i,4}); %#ok<AGROW>
        end
    end
    
    violStrs = {};
    violEventNums = [];
    constTol = maData.optimizer.problem.options.ConstraintTolerance;
    for(i=1:length(values)) %#ok<*NO4LP>
        value = values(i);
        lb = lbs(i);
        ub = ubs(i);
        type = types{i};
        eventNum = eventNums(i);
        unit = unitStrs{i};
               
        if(isempty(unit))
           unitStr = ''; 
        else
            unitStr = sprintf(' %s', unit);
        end
        
        if(lbs(i) == ubs(i)) %equality constraint
            if(abs(ceq(i)) > constTol)
                violStrs{end+1} = getViolStr(type, eventNum, value, unitStr, lb, ub); %#ok<AGROW>
                violEventNums(end+1) = eventNum; %#ok<AGROW>
            end
        else %inequality constraint
            if(c(2*i) > constTol || c(2*i - 1) > constTol)
                violStrs{end+1} = getViolStr(type, eventNum, value, unitStr, lb, ub); %#ok<AGROW>
                violEventNums(end+1) = eventNum; %#ok<AGROW>
            end
        end
    end
    
    if(~isempty(violEventNums))
        violStrs = violStrs';
        violEventNums = unique(violEventNums);
        eventStr = makeEventsStr(violEventNums);
        warnStr = sprintf('Optimization constraints are active or violated on some events (Events: %s)',eventStr);
        warnStr = vertcat(warnStr,cellstr(violStrs));

        addToExecutionWarnings(strjoin(warnStr,'\n'), -1, -1, celBodyData);
    end
end

function violStr = getViolStr(type, eventNum, value, unitStr, lb, ub)
    violStr = sprintf('%s Constraint (Event %i) - Value: %f%s, Bounds: [%f, %f] %s', type, eventNum, value, unitStr, lb, ub, unitStr);
end
