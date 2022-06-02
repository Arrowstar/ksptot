function checkEventVariablesAndBounds(script, celBodyData)
%checkEventVariablesAndBounds Summary of this function goes here
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
                        case 'NBodyCoast'
                            value = event.coastToValue;
                        case 'Set_State'
                            if(strcmpi(event.subType,'estLaunch'))
                                value = event.launch.launchValue;
                                value = value(j);
                            else
                                epoch = event.epoch;
                                rVect = event.rVect;
                                vVect = event.vVect;
                                gmu = event.centralBody.gm;

                                [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(rVect,vVect,gmu, true);

                                value = [epoch, sma, ecc, inc, raan, arg, tru];
                                value = value(j);
                            end
                        otherwise
                            error(['Invalid event type for checking event bounds: ', event.type]);
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
