function cullArriveDepartCombosPerCB(mainGUIHandle)
%cullArriveDepartCombosPerCB Summary of this function goes here
%   Detailed explanation goes here
       
    %Set up CB/Arrive/Depart combo boxes
    [cbBodyNames, arriveDepartNames] = genCBArriveDepartComboBoxStrs(mainGUIHandle);

    %Strings for CB combo boxes
    cbComboString = char(cap1stLetter(cbBodyNames));
    hCentralBodyCombo = findobj(mainGUIHandle,'Tag','centralBodyCombo');
    set(hCentralBodyCombo,'String',cbComboString);

    %Strings for Depart/Arrival combo boxes
    departArriveComboString = char(cap1stLetter(arriveDepartNames));
    
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
    set(hDepartBodyCombo,'Value',dBValue);
    set(hDepartBodyCombo,'String',departArriveComboString);

    hArriveBodyCombo = findobj(mainGUIHandle,'Tag','arrivalBodyCombo');
    set(hArriveBodyCombo,'Value',aBValue);
    set(hArriveBodyCombo,'String',departArriveComboString);
end

