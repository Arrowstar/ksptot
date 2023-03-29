classdef ThemeAppliedToAppEventData < event.EventData
    %ThemeAppliedToAppEventData Summary of this class goes here
    %   Detailed explanation goes here

    properties
        app matlab.apps.AppBase
        theme AppColorTheme
    end

    methods
        function obj = ThemeAppliedToAppEventData(app, theme)
            obj.app = app;
            obj.theme = theme;
        end
    end
end