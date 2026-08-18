classdef AdamNlOptReturnIterateEnum < matlab.mixin.SetGet
    %AdamNlOptReturnIterateEnum Which iterate AdamNLOpt returns when it exits on a limit.

    enumeration
        Last('last', 'Last Iterate')
        BestKKT('bestKKT', 'Best KKT Iterate')
    end

    properties
        optionStr char = ''
        name char = '';
    end

    methods
        function obj = AdamNlOptReturnIterateEnum(optionStr, name)
            obj.optionStr = optionStr;
            obj.name = name;
        end
    end

    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('AdamNlOptReturnIterateEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end

        function [ind, enum] = getIndForName(name)
            m = enumeration('AdamNlOptReturnIterateEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('AdamNlOptReturnIterateEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end
