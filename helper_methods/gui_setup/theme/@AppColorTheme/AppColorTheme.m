classdef AppColorTheme < matlab.mixin.SetGet
    %AppColorTheme Summary of this class goes here
    %   Detailed explanation goes here

    properties
        name(1,1) string = 'Untitled App Theme'
        desc(1,1) string = "";

        bgColor(1,3) double = [33,33,33]/255;
        fontColor(1,3) double = [0.9,0.9,0.9];
        borderColor(1,3) double = [0.7,1,1];
        borderWidth(1,1) double = 1;

        buttonBgColor(1,3) double = [66,66,66]/255;
        buttonFontColor(1,3) double = [0.9,0.9,0.9];

        editTextBgColor(1,3) double = [33,33,33]/255;
        editTextFontColor(1,3) double = [0.9,0.9,0.9];

        dropDownBgColor(1,3) double = [66,66,66]/255;
        dropDownFontColor(1,3) double = [0.9,0.9,0.9];

        listboxBgColor(1,3) double = [33,33,33]/255;
        listboxFontColor(1,3) double = [0.9,0.9,0.9];

        sliderFontColor(1,3) double = [0.9,0.9,0.9];

        tableBgColor1(1,3) double = [33,33,33]/255;
        tableBgColor2(1,3) double = [66,66,66]/255;
        tableFontColor(1,3) double = [0.9,0.9,0.9];
        
        axesBgColor(1,3) double = [0.9, 0.9, 0.9];
        axesGridColor(1,3) double  = [0.9, 0.9, 0.9];
    end

    methods
        function obj = AppColorTheme(name, bgColor, fontColor, buttonBgColor, buttonFontColor, dropDownBgColor, dropDownFontColor, editTextBgColor, editTextFontColor, listboxBgColor, listboxFontColor, borderColor, sliderFontColor, axesBgColor, axesGridColor, tableBgColor1, tableBgColor2, tableFontColor)
            obj.name = name;

            obj.bgColor = bgColor;
            obj.fontColor = fontColor;
            obj.borderColor = borderColor;

            obj.buttonBgColor = buttonBgColor;
            obj.buttonFontColor = buttonFontColor;

            obj.dropDownBgColor = dropDownBgColor;
            obj.dropDownFontColor = dropDownFontColor;

            obj.editTextBgColor = editTextBgColor;
            obj.editTextFontColor = editTextFontColor;

            obj.listboxBgColor = listboxBgColor;
            obj.listboxFontColor = listboxFontColor;

            obj.sliderFontColor = sliderFontColor;
            
            obj.axesBgColor = axesBgColor;
            obj.axesGridColor = axesGridColor;

            obj.tableBgColor1 = tableBgColor1;
            obj.tableBgColor2 = tableBgColor2;
            obj.tableFontColor = tableFontColor;
        end
    end
end