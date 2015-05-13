function ma_updateScriptListbox(hScriptListbox, script)
%updateScriptListbox Summary of this function goes here
%   Detailed explanation goes here

    listboxStr = {};
    for(i=1:length(script))
        event = script{i};
        optSym = '';
        if(isstruct(event) && isfield(event,'vars'))
            vars = event.vars;
            if(any(vars(1,:)==1))
                optSym = '*';
            end
        end

        eventStr = [num2str(i), ' - ', optSym, upper(event.type), ' - ', event.name];
        listboxStr{i} = eventStr;
    end
    
    value = get(hScriptListbox, 'value');
    if(value > length(listboxStr))
        value = length(listboxStr);
    end
    set(hScriptListbox, 'value', value);
    set(hScriptListbox, 'String', listboxStr);
end

