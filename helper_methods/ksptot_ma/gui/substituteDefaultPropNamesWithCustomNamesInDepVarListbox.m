function substituteDefaultPropNamesWithCustomNamesInDepVarListbox(hDepVarListbox, propNames)
    vars = get(hDepVarListbox,'String');
%     propNames = maData.spacecraft.propellant.names;
    defaultNames = {'Liquid Fuel/Ox Mass','Monopropellant Mass','Xenon Mass'};
    propNames = sort(propNames);
    
    for(i=1:length(vars)) %#ok<*NO4LP>
        for(j=1:length(defaultNames))
            vars{i} = strrep(vars{i}, defaultNames{j}, [propNames{j}, ' Mass']);
        end
    end
    set(hDepVarListbox,'String',vars);
end