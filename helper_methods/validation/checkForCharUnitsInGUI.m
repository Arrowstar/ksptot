function checkForCharUnitsInGUI(hGUI)
%checkForCharUnitsInGUI Summary of this function goes here
%   Detailed explanation goes here
    child_handles = allchild(hGUI);
    for(i=1:length(child_handles))
        hChild = child_handles(i);
        try
            unit = get(hChild,'Units');
            if(~strcmpi(unit,'pixels') && ~strcompi(unit,'data'))
                tag = get(hChild,'Tag');
                disp(['Unit of ', tag, ' is set to ', unit, '!']);
            end
        catch ME
            
        end
        checkForCharUnitsInGUI(hChild);
    end
end

