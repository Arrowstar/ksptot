classdef LineSpecEnum
    %LineSpecEnum Line style enumeration (value class).
    %
    %   Value semantics (not a handle): copying an enum member copies its
    %   payload, so a statement like ev.colorLineSpec.lineSpec.linespec
    %   = '--' can never restyle every event sharing that member.  All
    %   writers reassign wholesale (ev.colorLineSpec.lineSpec = ...).
    %   Previously derived from matlab.mixin.SetGet, which made each
    %   member a mutable global singleton (Bug 4).
    
    enumeration
        SolidLine('Solid Line', '-')
        DashedLine('Dashed Line', '--')
        DottedLine('Dotted Line', ':')
        DashedDotLine('Dashed-dot Line', '-.')
    end
    
    properties(SetAccess = immutable)
        name char = '';
        linespec char = '';
    end
    
    methods
        function obj = LineSpecEnum(name, linespec)
            obj.name = name;
            obj.linespec = linespec;

            [A,~,~]=imread('square_gradient.png', 'BackgroundColor',[1,1,1]);
        end
    end
    
    methods(Static)
        function [listBoxStr, m] = getListboxStr()
            m = enumeration('LineSpecEnum');
            listBoxStr = {m.name};
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('LineSpecEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('LineSpecEnum');
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
    end
end