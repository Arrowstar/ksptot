function checkForNonZeroOptimVars(script, celBodyData)
%checkForNonZeroOptimVars Summary of this function goes here
%   Detailed explanation goes here

    activeOptVarExists = false;
    for(i=1:length(script)) %#ok<*NO4LP>
        event = script{i};
        if(isfield(event,'vars'))
            vars = event.vars;
            for(j=1:size(vars,2))
                var = vars(:,j);
                
                if(var(1) == 1)
                    activeOptVarExists = true;
                    break;
                end
            end
        end
    end

    if(activeOptVarExists == false && length(script)>1)
        addToExecutionWarnings('No optimization variables enabled on script.', -1, -1, celBodyData);
    end
end

