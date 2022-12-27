function appOptions = getAppOptionsFromFile()
    doesAppOptionsFileExist = exist('appOptions.ini','file');
    if(doesAppOptionsFileExist)
        [appOptionsFromINI,~,~] = inifile('appOptions.ini','readall');
        appOptionsFromINI = addMissingAppOptionsRows(appOptionsFromINI);
    else
        appOptionsFromINI = createDefaultKsptotOptions();
        inifile('appOptions.ini','write',appOptionsFromINI);
    end
    appOptions = processINIBodyInfo(appOptionsFromINI, false, 'appOptions'); %turns out this function works for other ini files too lol!    
end