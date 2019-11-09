classdef PatternSearchUseParallelEnum < matlab.mixin.SetGet
    %PatternSearchUseParallelEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        UseParallel('Compute Functions in Parallel',true)
        DoNotUseParallel('Compute Functions in Serial',false);
    end
    
    properties
        name char = '';
        optionVal(1,1) logical = true
    end
    
    methods
        function obj = PatternSearchUseParallelEnum(name, optionVal)
            obj.name = name;
            obj.optionVal = optionVal;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('PatternSearchUseParallelEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('PatternSearchUseParallelEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('PatternSearchUseParallelEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end