classdef SqpTerminationCondEnum < matlab.mixin.SetGet
    %SqpTerminationCondEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Schittkowski("Schittkowski's Criteria",-1)
        Grace("Grace's Criteria",1)
        Standard("Standard Criteria",0)
        Slowed("Slowed Criteria",2)
    end
    
    properties
        name char = '';
        optionVal(1,1) double = -1
    end
    
    methods
        function obj = SqpTerminationCondEnum(name, optionVal)
            obj.name = name;
            obj.optionVal = optionVal;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('FminconUseParallelEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('FminconUseParallelEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('FminconUseParallelEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end