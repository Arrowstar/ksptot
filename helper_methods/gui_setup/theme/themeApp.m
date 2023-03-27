function themeApp(app)
    arguments
        app(1,1) matlab.apps.AppBase
    end

    figPropStrs=properties(app);
    
    bgColor = [33,33,33]/255;
    fontColor = [0.9,0.9,0.9];
    buttonBgColor = [66,66,66]/255;
    buttonFontColor = [0.9,0.9,0.9];
    textBgColor = [66,66,66]/255;
    textFontColor = [0.9,0.9,0.9];
    
    for(i=1:length(figPropStrs)) %#ok<*NO4LP> 
        prop = app.(figPropStrs{i});
    
        switch class(prop)
            case 'matlab.ui.Figure'
                themeUiFigure(prop, bgColor);
    
            case 'matlab.ui.container.Panel'
                themeUiPanel(prop, bgColor, fontColor);
    
            case 'matlab.ui.container.GridLayout'
                themeGridLayout(prop, bgColor);
    
            case 'matlab.ui.control.UIAxes'
                themeAxes(prop, fontColor);
    
            case 'matlab.ui.control.Button'
                themeButton(prop, buttonBgColor, buttonFontColor);
    
            case 'matlab.ui.control.EditField'
                themeEditField(prop, textBgColor, textFontColor);
    
            case 'matlab.ui.control.TextArea'
                themeTextArea(prop, textBgColor, textFontColor);
    
            case 'matlab.ui.control.Label'
                themeLabels(prop, bgColor, fontColor);
    
            case 'matlab.ui.control.DropDown'
                themeDropdown(prop, textBgColor, textFontColor);
    
            case 'matlab.ui.container.ButtonGroup'
                themeButtonGroup(prop, bgColor, fontColor);
    
            case 'matlab.ui.control.RadioButton'
                themeRadioButton(prop, textFontColor);

            case 'matlab.ui.control.Slider'
                themeSlider(prop, fontColor);

            case 'matlab.ui.control.ListBox'
                themeListbox(prop, textBgColor, textFontColor)

            case 'matlab.ui.control.Table'
                themeTable(prop, bgColor);
        end
    end
end

function themeUiFigure(hFig, bgColor)
    arguments
        hFig(1,1) matlab.ui.Figure
        bgColor(1,3) double
    end

    hFig.Color = bgColor;
end

function themeUiPanel(hPanel, bgColor, fontColor)
    arguments
        hPanel(1,1) matlab.ui.container.Panel
        bgColor(1,3) double
        fontColor(1,3) double
    end

    hPanel.BackgroundColor = bgColor;
    hPanel.ForegroundColor = fontColor;
end

function themeGridLayout(gridLayout, bgColor)
    arguments
        gridLayout(1,1) matlab.ui.container.GridLayout
        bgColor(1,3) double
    end

    gridLayout.BackgroundColor = bgColor;
end

function themeAxes(hAx, fontColor)
    arguments
        hAx(1,1) matlab.ui.control.UIAxes
        fontColor(1,3) double
    end

    hAx.Color = [1,1,1];
    hAx.XColor = fontColor;
    hAx.YColor = fontColor;
    hAx.ZColor = fontColor;
   
    colorbar = hAx.Colorbar;
    if(not(isempty(colorbar)))
        colorbar.Color = fontColor;
    end
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

function themeListbox(hListbox, bgColor, fontColor)
    arguments
        hListbox(1,1) matlab.ui.control.ListBox
        bgColor(1,3) double
        fontColor(1,3) double
    end

    hListbox.BackgroundColor = bgColor;
    hListbox.FontColor = fontColor;
end


function themeTable(hTable, bgColor)
    arguments
        hTable(1,1) matlab.ui.control.Table
        bgColor(1,3) double
    end

    hTable.BackgroundColor = bgColor;               
end