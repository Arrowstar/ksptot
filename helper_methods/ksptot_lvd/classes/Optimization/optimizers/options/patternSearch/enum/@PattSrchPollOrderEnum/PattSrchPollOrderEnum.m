classdef PattSrchPollOrderEnum < matlab.mixin.SetGet
    %PattSrchPollOrderEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Random('Random', 'Random');
        Success('Success', 'Success');
        Consecutive('Consecutive', 'Consecutive');
    end
    
    properties
        optionStr char = ''
        name char = '';
    end
    
    methods
        function obj = PattSrchPollOrderEnum(optionStr, name)
            obj.optionStr = optionStr;
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('PattSrchPollOrderEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('PattSrchPollOrderEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('PattSrchPollOrderEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end