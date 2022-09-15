classdef ViewGridTypeEnum < matlab.mixin.SetGet
    %ViewGridTypeEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Major('Major Grid Lines','on')
        Minor('Major and Minor Grid Lines','minor')
        Off('No Grid Lines','off')
    end
    
    properties
        name(1,:) char = '';
        gridStr(1,:) char = '';
    end
    
    methods
        function obj = ViewGridTypeEnum(name, gridStr)
            obj.name = name;
            obj.gridStr = gridStr;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('ViewGridTypeEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('ViewGridTypeEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('ViewGridTypeEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end