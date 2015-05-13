function script = ma_updateOptimScript(x, script, variables)
    i = 1;
    for(varC = variables) %#ok<*NO4LP>
        var = varC{1};
        event = script{var.eventNum};
        
        xSubset = x(i:i+length(var.x0)-1);
        event = ma_updateOptimEvent(xSubset, event);
        
        script{var.eventNum} = event;
        
        i = i + length(var.x0);
    end
end