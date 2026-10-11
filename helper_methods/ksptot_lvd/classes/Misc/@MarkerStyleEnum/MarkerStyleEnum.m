classdef MarkerStyleEnum
    %MarkerStyleEnum Marker style enumeration (value class).
    %
    %   Value semantics (not a handle): see LineSpecEnum.  Previously
    %   derived from matlab.mixin.SetGet, a mutable global singleton.
    
    enumeration
        Plus('Plus Sign', '+')
        Circle('Circle', 'o')
        Asterisk('Asterisk', '*')
        Cross('Cross', 'x')
        Square('Square', 's')
        Diamond('Diamond', 'd')
        UpTriangle('Upward-pointing triangle', '^')
        DownTriangle('Downward-pointing triangle', 'v')
        RightTriangle('Right-pointing triangle', '>')
        LeftTriangle('Left-pointing triangle', '<')
        Pentagram('Pentagram', 'p')
        Hexagram('Hexagram', 'h')
        None('No Marker', 'none');
    end
    
    properties(SetAccess = immutable)
        name char = '';
        shape char = '';
    end
    
    methods
        function obj = MarkerStyleEnum(name, shape)
            obj.name = name;
            obj.shape = shape;
        end
    end
    
    methods(Static)
        function [listBoxStr, m] = getListboxStr()
            m = enumeration('MarkerStyleEnum');
            listBoxStr = {m.name};
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('MarkerStyleEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('MarkerStyleEnum');
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
    end
end