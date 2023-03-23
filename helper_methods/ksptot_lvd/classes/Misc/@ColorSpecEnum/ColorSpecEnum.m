classdef ColorSpecEnum < matlab.mixin.SetGet
    %ColorSpecEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Red('Red',[1 0 0])
        Magenta('Magenta',[178,0,255]/255)
        Orange('Orange', [255,131,0]/255)
        Yellow('Yellow', [255,216,0]/255)
        Green('Green', [76,220,0]/255)
        Cyan('Cyan',[0,210,255]/255)
        Blue('Blue',[0 0 1])
        Black('Black',[0 0 0])
        White('White',[1 1 1])
        Pink('Pink',[255,0,220]/255)
        Brown('Brown',[139,69,19]/255)
        DarkGrey('Dark Grey',[0.15 0.15 0.15]);
        Grey('Grey',[0.5, 0.5, 0.5])
        LightGrey('Light Grey',[223 223 223]/255);
        BrightGreen('Bright Green', [102, 255, 0]/255);
    end
    
    properties
        name char = '';
        color(1,3) double;

        iconBaseTemplateFile(1,:) char = 'square_gradient.png';
        iconImageHSV double
        iconImageRBG double
    end
    
    methods
        function obj = ColorSpecEnum(name,color)
            obj.name = name;
            obj.color = color;

            [A,~,~]=imread(obj.iconBaseTemplateFile, 'BackgroundColor',[1,1,1]);
            RGB = double(A)/255;
            obj.iconImageHSV = rgb2hsv(RGB);
            obj.iconImageRBG = obj.getIconForColorSpecEnum();
        end

        function RGB_color = getIconForColorSpecEnum(obj)
            arguments
                obj(1,1) ColorSpecEnum
            end

            chsv = rgb2hsv(obj.color);
        
            HSV_color = obj.iconImageHSV;
            HSV_color_1 = HSV_color(:,:,1);
            HSV_color_3 = HSV_color(:,:,3);
            HSV_color_1(HSV_color_3 ~= 1) = chsv(1);
            HSV_color(:,:,1) = HSV_color_1;
            RGB_color = hsv2rgb(HSV_color);
        end

        function lbBgColorRgb = getListboxBackgroundColor(obj)
            hsv = rgb2hsv(obj.color);

            if(hsv(3) > 0.5)
                lbBgColorRgb = hsv2rgb([0,0,0.4]);
            else
                lbBgColorRgb = hsv2rgb([0,0,0.6]);
            end
        end
    end
    
    methods(Static)
        function [listBoxStr, m] = getListboxStr()
            m = enumeration('ColorSpecEnum');
            listBoxStr = {m.name};
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('ColorSpecEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('ColorSpecEnum');
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end

        function bgColorRgb = getBestGreyBackgroundColor(colorEnums)
            arguments
                colorEnums ColorSpecEnum
            end

            cRGB = vertcat(colorEnums(:).color);
            cHSV = rgb2hsv(cRGB);

            origValues = cHSV(:,3);
            values = unique(sort([0;origValues;1]));
            valueDiffs = diff(values);
            [~,I] = max(valueDiffs);

            if(I == 1 && not(ismember(0,origValues)))
                useThisValue = 0;
            elseif(I == numel(valueDiffs) && not(ismember(1,origValues)))
                useThisValue = 1;
            else
                useThisValue = mean([values(I), values(I+1)]);
            end
            
            bgColorRgb = hsv2rgb([0,0,useThisValue]);
        end
    end
end