classdef AdamNlOptDisplayEnum < matlab.mixin.SetGet
    %AdamNlOptDisplayEnum Console output verbosity used by AdamNLOpt.

    enumeration
        Iterative('iter', 'Iterative')
        IterativeDebug('iter-debug', 'Iterative (Debug)')
        Final('final', 'Final Only')
        Off('off', 'Off')
    end

    properties
        optionStr char = ''
        name char = '';
    end

    methods
        function obj = AdamNlOptDisplayEnum(optionStr, name)
            obj.optionStr = optionStr;
            obj.name = name;
        end
    end

    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('AdamNlOptDisplayEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end

        function [ind, enum] = getIndForName(name)
            m = enumeration('AdamNlOptDisplayEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('AdamNlOptDisplayEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end
