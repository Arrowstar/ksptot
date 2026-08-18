classdef AdamNlOptGlobalizationEnum < matlab.mixin.SetGet
    %AdamNlOptGlobalizationEnum Step acceptance strategy used by AdamNLOpt.

    enumeration
        Filter('filter', 'Filter')
        Merit('merit', 'Merit Function')
    end

    properties
        optionStr char = ''
        name char = '';
    end

    methods
        function obj = AdamNlOptGlobalizationEnum(optionStr, name)
            obj.optionStr = optionStr;
            obj.name = name;
        end
    end

    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('AdamNlOptGlobalizationEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end

        function [ind, enum] = getIndForName(name)
            m = enumeration('AdamNlOptGlobalizationEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('AdamNlOptGlobalizationEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end
