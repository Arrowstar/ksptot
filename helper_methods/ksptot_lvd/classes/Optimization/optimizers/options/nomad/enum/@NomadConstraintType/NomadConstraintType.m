classdef NomadConstraintType < matlab.mixin.SetGet
    %NomadConstraintType Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        PB('PB', 'Progressive Barrier')
        EB('EB', 'Extreme Barrier')
        PEB('PEB', 'Hybrid Constraint (PB/EB)')
        F('F', 'Filter')
    end
    
    properties
        optionStr char = ''
        name char = '';
    end
    
    methods
        function obj = NomadConstraintType(optionStr, name)
            obj.optionStr = optionStr;
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('NomadConstraintType');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('NomadConstraintType');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('NomadConstraintType');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end