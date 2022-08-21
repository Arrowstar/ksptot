function ma_updateScriptListbox(hScriptListbox, script)
%updateScriptListbox Summary of this function goes here
%   Detailed explanation goes here

    listboxStr = {};
    for(i=1:length(script)) %#ok<*NO4LP>
        event = script{i};
        optSym = '';
        if(isstruct(event))
            if(isfield(event,'vars'))
                vars = event.vars;
                
                if(any(vars(1,:)==1))
                    optSym = '*';
                end
            elseif(isfield(event,'launch') && ~isempty(event.launch) && isfield(event.launch,'vars'))
                vars = event.launch.vars;
                
                if(any(vars(1,:)==1))
                    optSym = '*';
                end
            end
        end

        eventStr = [num2str(i), ' - ', optSym, upper(event.type), ' - ', event.name];
        listboxStr{i} = eventStr; %#ok<AGROW>
    end
    
    value = get(hScriptListbox, 'value');
    if(value > length(listboxStr))
        value = length(listboxStr);
    elseif(isempty(value))
        value = 1;
    end
    set(hScriptListbox, 'value', value);
    set(hScriptListbox, 'String', listboxStr);
end

