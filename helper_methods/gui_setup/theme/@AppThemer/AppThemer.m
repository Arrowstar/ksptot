classdef AppThemer < matlab.mixin.SetGet
    %AppThemer Summary of this class goes here
    %   Detailed explanation goes here

    properties
        themes(1,:) AppColorTheme

        selTheme AppColorTheme
    end

    methods
        function obj = AppThemer()
            obj.themes = AppThemer.createDefaultThemes();
            obj.selTheme = obj.themes(1);
        end

        function [listboxStr, themes, selectedTheme] = getListrboxStr(obj)
            listboxStr = [obj.themes.name];
            themes = obj.themes;
            selectedTheme = obj.selTheme;
        end

        function addTheme(obj, theme)
            obj.themes(end+1) = theme;
        end

        function deleteTheme(obj, theme)
            indOfRemTheme = find(obj.themes == theme);

            obj.themes(obj.themes == theme) = [];

            if(theme == obj.selTheme)
                numThemesLeft = numel(obj.themes);

                if(indOfRemTheme > numThemesLeft)
                    obj.selTheme = obj.themes(end);
                else
                    obj.selTheme = obj.themes(indOfRemTheme);
                end
            end
        end

        function themeAllOpenApps(obj)
            hFigs = findall(groot, 'Type', 'figure');
            for(i=1:numel(hFigs))
                hFig = hFigs(i);
                if(isprop(hFig, 'RunningAppInstance'))
                    apps = hFig.RunningAppInstance;
                    for(j=1:numel(apps))
                        app = apps(j);
                        obj.themeApp(app);
                    end
                end
            end
        end

        function themeApp(obj, app)
            arguments
                obj(1,1) AppThemer
                app(1,1) matlab.apps.AppBase
            end

            figPropStrs=properties(app);

            for(i=1:length(figPropStrs)) %#ok<*NO4LP> 
                prop = app.(figPropStrs{i});
            
                obj.themeWidget(prop, obj.selTheme);
            end
        end

        function themeWidget(obj, prop, theme)
            arguments
                obj(1,1) AppThemer
                prop(1,1)
                theme(1,1) AppColorTheme
            end

            switch class(prop)
                case 'matlab.ui.Figure'
                    AppThemer.themeUiFigure(prop, theme.bgColor);
        
                case 'matlab.ui.container.Panel'
                    AppThemer.themeUiPanel(prop, theme.bgColor, theme.fontColor, theme.borderColor);
        
                case 'matlab.ui.container.GridLayout'
                    AppThemer.themeGridLayout(prop, theme.bgColor);

                case 'matlab.ui.container.TabGroup'
                    % AppThemer.themeTabGroup(prop, theme.bgColor);
                    % %doesn't work yet, can't do tab background colors

                case 'matlab.ui.container.Tab'
                    % AppThemer.themeTab(prop, theme.bgColor,
                    % theme.fontColor); %doesn't work yet, can't do tab
                    % background colors

                case 'matlab.ui.control.CheckBox'
                    AppThemer.themeCheckbox(prop, theme.fontColor)

                case 'matlab.ui.control.UIAxes'
                    AppThemer.themeAxes(prop, theme.axesBgColor, theme.axesGridColor, theme.fontColor);
        
                case 'matlab.ui.control.Button'
                    AppThemer.themeButton(prop, theme.buttonBgColor, theme.buttonFontColor);
        
                case 'matlab.ui.control.EditField'
                    AppThemer.themeEditField(prop, theme.editTextBgColor, theme.editTextFontColor);
        
                case 'matlab.ui.control.TextArea'
                    AppThemer.themeTextArea(prop, theme.editTextBgColor, theme.editTextFontColor);
        
                case 'matlab.ui.control.Label'
                    AppThemer.themeLabels(prop, theme.bgColor, theme.fontColor);
        
                case 'matlab.ui.control.DropDown'
                    AppThemer.themeDropdown(prop, theme.dropDownBgColor, theme.dropDownFontColor);
        
                case 'matlab.ui.container.ButtonGroup'
                    AppThemer.themeButtonGroup(prop, theme.bgColor, theme.fontColor);
        
                case 'matlab.ui.control.RadioButton'
                    AppThemer.themeRadioButton(prop, theme.fontColor);
    
                case 'matlab.ui.control.Slider'
                    AppThemer.themeSlider(prop, theme.sliderFontColor);

                case 'matlab.ui.control.Spinner'
                    AppThemer.themeSpinner(prop, theme.editTextBgColor, theme.editTextFontColor);

                case 'matlab.ui.control.ListBox'
                    AppThemer.themeListbox(prop, theme.listboxBgColor, theme.listboxFontColor)

                case 'matlab.ui.control.Table'
                    AppThemer.themeTable(prop, theme.bgColor, theme.fontColor);

                case 'matlab.ui.container.Toolbar'
                    AppThemer.themeToolbar(prop, theme.bgColor)
            end
        end
    end

    methods(Static)
        function themes = createDefaultThemes()
            themes(1) = AppThemer.createDefaultLightTheme();
            themes(2) = AppThemer.createDefaultDarkTheme();
        end
        
        function theme = createDefaultLightTheme()
            theme = AppColorTheme('Default Light Theme', [0.94,0.94,0.94], [0.00,0.00,0.00], [0.96,0.96,0.96], [0.00,0.00,0.00], [0.94,0.94,0.94], [0.00,0.00,0.00], [1,1,1], [0.00,0.00,0.00], [1,1,1], [0.00,0.00,0.00], [0.49,0.49,0.49], [0.00,0.00,0.00], [1,1,1], [0,0,0]);
        end

        function theme = createDefaultDarkTheme()
            theme = AppColorTheme('Default Dark Theme', [33,33,33]/255, [0.9,0.9,0.9], [66,66,66]/255, [0.9,0.9,0.9], [66,66,66]/255, [0.9,0.9,0.9], [66,66,66]/255, [0.9,0.9,0.9], [66,66,66]/255, [0.9,0.9,0.9], [0.49,0.49,0.49], [0.9,0.9,0.9], [66,66,66]/255, [0.9,0.9,0.9]);
        end
    end

    methods(Static, Access=private)
        function themeUiFigure(hFig, bgColor)
            arguments
                hFig(1,1) matlab.ui.Figure
                bgColor(1,3) double
            end
        
            hFig.Color = bgColor;
        end
        
        function themeUiPanel(hPanel, bgColor, fontColor, borderColor)
            arguments
                hPanel(1,1) matlab.ui.container.Panel
                bgColor(1,3) double
                fontColor(1,3) double
                borderColor(1,3) double
            end
        
            hPanel.BackgroundColor = bgColor;
            hPanel.ForegroundColor = fontColor;
            hPanel.BorderColor = borderColor;
        end
        
        function themeGridLayout(gridLayout, bgColor)
            arguments
                gridLayout(1,1) matlab.ui.container.GridLayout
                bgColor(1,3) double
            end
        
            gridLayout.BackgroundColor = bgColor;
        end

        function themeTabGroup(tabGroup, bgColor)
            arguments
                tabGroup(1,1) matlab.ui.container.TabGroup
                bgColor(1,3) double
            end
        
            set(tabGroup, 'defaultUitabForegroundColor', bgColor);
        end

        function themeTab(tab, bgColor, fontColor)
            arguments
                tab(1,1) matlab.ui.container.Tab
                bgColor(1,3) double
                fontColor(1,3) double
            end
        
            tab.BackgroundColor = bgColor;
            tab.ForegroundColor = fontColor;
        end
        
        function themeButton(hButton, bgColor, fontColor)
            arguments
                hButton(1,1) matlab.ui.control.Button
                bgColor(1,3) double
                fontColor(1,3) double
            end
        
            hButton.BackgroundColor = bgColor;
            hButton.FontColor = fontColor;
        end
        
        function themeEditField(hEditField, bgColor, fontColor)
            arguments
                hEditField(1,1) matlab.ui.control.EditField
                bgColor(1,3) double
                fontColor(1,3) double
            end
        
            hEditField.BackgroundColor = bgColor;
            hEditField.FontColor = fontColor;
        end
        
        function themeTextArea(hTextArea, bgColor, fontColor)
            arguments
                hTextArea(1,1) matlab.ui.control.TextArea
                bgColor(1,3) double
                fontColor(1,3) double
            end
        
            hTextArea.BackgroundColor = bgColor;
            hTextArea.FontColor = fontColor;
        end
        
        function themeLabels(hLabel, bgColor, fontColor)
            arguments
                hLabel(1,1)matlab.ui.control.Label
                bgColor(1,3) double
                fontColor(1,3) double
            end
        
            %basically if it's a "unit" label then leave it alone.
            if(ischar(hLabel.BackgroundColor) && strcmpi(hLabel.BackgroundColor,'none'))
                hLabel.BackgroundColor = bgColor;
                hLabel.FontColor = fontColor;
            else
                if(all(hLabel.BackgroundColor ~= [0.6, 1, 0.6]))
                    hLabel.BackgroundColor = bgColor;
                    hLabel.FontColor = fontColor;
                end
            end
        end
        
        function themeDropdown(hDropdown, bgColor, fontColor)
            arguments
                hDropdown(1,1) matlab.ui.control.DropDown
                bgColor(1,3) double
                fontColor(1,3) double
            end
        
            hDropdown.FontColor = fontColor;
            hDropdown.BackgroundColor = bgColor;
        end
        
        function themeButtonGroup(hButtonGrp, bgColor, fontColor)
            arguments
                hButtonGrp(1,1) matlab.ui.container.ButtonGroup
                bgColor(1,3) double
                fontColor(1,3) double
            end
        
            hButtonGrp.ForegroundColor = fontColor;
            hButtonGrp.BackgroundColor = bgColor;
        end
        
        function themeRadioButton(hRadioButton, fontColor)
            arguments
                hRadioButton(1,1) matlab.ui.control.RadioButton
                fontColor(1,3) double
            end
        
            hRadioButton.FontColor = fontColor;
        end
        
        function themeSlider(hSlider, fontColor)
            arguments
                hSlider(1,1) matlab.ui.control.Slider
                fontColor(1,3) double
            end
        
            hSlider.FontColor = fontColor;
        end

        function themeSpinner(hSpinner, bgColor, fontColor)
            arguments
                hSpinner(1,1) matlab.ui.control.Spinner
                bgColor(1,3) double
                fontColor(1,3) double
            end
        
            hSpinner.BackgroundColor = bgColor;
            hSpinner.FontColor = fontColor;
        end
        
        function themeListbox(hListbox, bgColor, fontColor)
            arguments
                hListbox(1,1) matlab.ui.control.ListBox
                bgColor(1,3) double
                fontColor(1,3) double
            end
        
            hListbox.BackgroundColor = bgColor;
            hListbox.FontColor = fontColor;
        end

        function themeTable(hTable, bgColor, fontColor)
            arguments
                hTable(1,1) matlab.ui.control.Table
                bgColor(1,3) double
                fontColor(1,3) double
            end
        
            hTable.BackgroundColor = bgColor;   
            hTable.ForegroundColor = fontColor;
        end

        function themeToolbar(hToolbar, bgColor)
            arguments
                hToolbar(1,1) matlab.ui.container.Toolbar
                bgColor(1,3) double
            end

            hToolbar.BackgroundColor = bgColor;  
        end

        function themeAxes(hAx, bgColor, gridColor, fontColor)
            arguments
                hAx (1,1) matlab.ui.control.UIAxes
                bgColor(1,3) double
                gridColor(1,3) double
                fontColor(1,3) double
            end

            hAx.Color = bgColor;
            hAx.GridColor = gridColor;
            hAx.MinorGridColor = gridColor;
            hAx.XColor = fontColor;
            hAx.YColor = fontColor;
            hAx.ZColor = fontColor;
            hAx.Title.Color = fontColor;

		    colorbar = hAx.Colorbar;
            if(not(isempty(colorbar)))
                colorbar.Color = fontColor;
            end
        end

        function themeCheckbox(hCheckbox, fontColor)
            arguments
                hCheckbox(1,1) matlab.ui.control.CheckBox
                fontColor(1,3) double
            end

            hCheckbox.FontColor = fontColor;
        end
    end
end