classdef LineSpecEnum < matlab.mixin.SetGet
    %LineSpecEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        SolidLine('Solid Line', '-')
        DashedLine('Dashed Line', '--')
        DottedLine('Dotted Line', ':')
        DashedDotLine('Dashed-dot Line', '-.')
    end
    
    properties
        name(1,:) char = '';
        linespec(1,:) char = '';
    end
    
    methods
        function obj = LineSpecEnum(name, linespec)
            obj.name = name;
            obj.linespec = linespec;
        end
    end
    
    methods(Static)
        function listBoxStr = getListboxStr()
            m = enumeration('LineSpecEnum');
            listBoxStr = {m.name};
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('LineSpecEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end