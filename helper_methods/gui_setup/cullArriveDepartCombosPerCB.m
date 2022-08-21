function cullArriveDepartCombosPerCB(mainGUIHandle)
%cullArriveDepartCombosPerCB Summary of this function goes here
%   Detailed explanation goes here
       
    %Set up CB/Arrive/Depart combo boxes
    [cbBodyNames, arriveDepartNames] = genCBArriveDepartComboBoxStrs(mainGUIHandle);

    %Strings for CB combo boxes
    cbBodyNames = cap1stLetter(cbBodyNames);
    cbComboString = char(cbBodyNames);
    hCentralBodyCombo = findobj(mainGUIHandle,'Tag','centralBodyCombo');
    
    try
        set(hCentralBodyCombo,'String',cbComboString);
    catch
        hCentralBodyCombo.Items = cbBodyNames;
    end

    %Strings for Depart/Arrival combo boxes
    arriveDepartNames = cap1stLetter(arriveDepartNames);
    departArriveComboString = char(arriveDepartNames);
    
    if(size(departArriveComboString,1)>5)
        dBValue = 3;
        aBValue = 4;
    elseif(size(departArriveComboString,1)>=2)
        dBValue = 1;
        aBValue = 2;
    else
        dBValue = 1;
        aBValue = 1;
    end

    hDepartBodyCombo = findobj(mainGUIHandle,'Tag','departBodyCombo');
    try
        set(hDepartBodyCombo,'Value',dBValue);
        set(hDepartBodyCombo,'String',departArriveComboString);
    catch
        hDepartBodyCombo.Items = arriveDepartNames;
        if(numel(arriveDepartNames) > 0)
            hDepartBodyCombo.Value = arriveDepartNames{dBValue};
        end
    end

    hArriveBodyCombo = findobj(mainGUIHandle,'Tag','arrivalBodyCombo');    
    try
        set(hArriveBodyCombo,'Value',aBValue);
        set(hArriveBodyCombo,'String',departArriveComboString);
    catch
        hArriveBodyCombo.Items = arriveDepartNames;
        if(numel(arriveDepartNames) > 0)
            hArriveBodyCombo.Value = arriveDepartNames{aBValue};
        end
    end
end