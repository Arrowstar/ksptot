classdef NomadStopIfFeasibleEnum < matlab.mixin.SetGet
    %NomadStopIfFeasibleEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        StopIfFeasible('Stop If Feasible', 1)
        DoNotStopIfFeasible('Do Not Stop On Feasible Solution', 0)
    end
    
    properties
        optVal(1,1) double 
        name char = '';
    end
    
    methods
        function obj = NomadStopIfFeasibleEnum(name, optVal)
            obj.name = name;
            obj.optVal = optVal;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('NomadStopIfFeasibleEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('NomadStopIfFeasibleEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('NomadStopIfFeasibleEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end