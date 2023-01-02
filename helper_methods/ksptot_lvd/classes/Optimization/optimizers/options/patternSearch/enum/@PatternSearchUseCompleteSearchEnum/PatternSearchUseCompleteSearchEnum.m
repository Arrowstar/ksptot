classdef PatternSearchUseCompleteSearchEnum < matlab.mixin.SetGet
    %PatternSearchUseCompleteSearchEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        UseCompleteSearch('Use Complete Search',true)
        DoNotUseCompletePoll('Do Not Use Complete Search',false);
    end
    
    properties
        name char = '';
        optionVal(1,1) logical = true
    end
    
    methods
        function obj = PatternSearchUseCompleteSearchEnum(name, optionVal)
            obj.name = name;
            obj.optionVal = optionVal;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('PatternSearchUseCompleteSearchEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('PatternSearchUseCompleteSearchEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('PatternSearchUseCompleteSearchEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end