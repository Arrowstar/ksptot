classdef AdamNlOptAutoScaleEnum < matlab.mixin.SetGet
    %AdamNlOptAutoScaleEnum Automatic problem scaling strategy used by AdamNLOpt.

    enumeration
        Gradient('gradient', 'Gradient Based')
        Curvature('curvature', 'Curvature Based')
        Bounds('bounds', 'Bounds Based')
        None('none', 'No Scaling')
    end

    properties
        optionStr char = ''
        name char = '';
    end

    methods
        function obj = AdamNlOptAutoScaleEnum(optionStr, name)
            obj.optionStr = optionStr;
            obj.name = name;
        end
    end

    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('AdamNlOptAutoScaleEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end

        function [ind, enum] = getIndForName(name)
            m = enumeration('AdamNlOptAutoScaleEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('AdamNlOptAutoScaleEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end
