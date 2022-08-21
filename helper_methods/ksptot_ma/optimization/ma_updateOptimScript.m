function script = ma_updateOptimScript(x, script, variables)
    if(any(isnan(x)))
        error(sprintf('Recieved NaN from optimizer algorithm when attempting to update script with new variable values.  Generally this means the algorithm has failed in some way.\n\nPlease try a different optimizer algorithm via the menu:\n\nScript -> Execution Settings -> Optimizer Algorithm.'));
    end

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