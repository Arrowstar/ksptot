function checkEventVariablesAndBounds(script, celBodyData)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    bndWarns = zeros(0,1);
    for(i=1:length(script)) %#ok<*NO4LP>
        event = script{i};
        if(isfield(event,'vars'))
            vars = event.vars;
            for(j=1:size(vars,2))
                var = vars(:,j);
                if(var(1)==1) %variable opt is on
                    lb = var(2);
                    ub = var(3);
                    spaceWidth = ub - lb;
                    
                    eventType = event.type;
                    switch eventType
                        case 'DV_Maneuver'
                            value = event.maneuverValue;
                            value = value(j);
                        case 'Coast'
                            value = event.coastToValue;
                    end
                    
                    normalized = (value - lb)/spaceWidth;
                    
                    if(normalized <= 0.01 || normalized >= 0.99)
                        bndWarns(end+1) = i;
                    end
                end
            end
        else
            continue;
        end
    end
    
    if(~isempty(bndWarns))
        bndWarns = unique(bndWarns);
        addToExecutionWarnings(['Variables are near optimization bounds on some events (Events: ', makeEventsStr(bndWarns), ')';], -1, -1, celBodyData);
    end
end

function str = makeEventsStr(bndWarns)
    eventNums = unique(bndWarns);
    str = '';
    for(i=1:length(eventNums))
        if(i==length(eventNums))
            endChar = '';
        else
            endChar = ', ';
        end
        
        str = [str, num2str(eventNums(i)),endChar];
    end
end
