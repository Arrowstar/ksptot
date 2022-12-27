classdef FigureRendererEnum < matlab.mixin.SetGet
    %FigureRendererEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        OpenGL('OpenGL','opengl');
        Painters('Painters','painters');
    end
    
    properties
        name char = '';
        renderer char = '';
    end
    
    methods
        function obj = FigureRendererEnum(name,renderer)
            obj.name = name;
            obj.renderer = renderer;
        end
    end
    
    methods(Static)
        function listBoxStr = getListboxStr()
            m = enumeration('FigureRendererEnum');
            listBoxStr = {m.name};
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('FigureRendererEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('FigureRendererEnum');
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
    end
end