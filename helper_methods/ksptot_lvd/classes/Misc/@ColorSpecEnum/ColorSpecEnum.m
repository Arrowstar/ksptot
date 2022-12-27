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
    end
    
    methods
        function obj = ColorSpecEnum(name,color)
            obj.name = name;
            obj.color = color;
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
    end
end