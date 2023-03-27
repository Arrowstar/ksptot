function applySelectedThemeToApp(app)
    arguments
        app(1,1) matlab.apps.AppBase
    end

    global GLOBAL_AppThemer %#ok<GVMIS>

    if(isa(GLOBAL_AppThemer, 'AppThemer'))
        GLOBAL_AppThemer.themeApp(app);
    end
end