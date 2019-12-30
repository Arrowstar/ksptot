classdef EventPlottingMethodEnum < matlab.mixin.SetGet
    %EventPlottingMethodEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        PlotContinuous('Plot Continuous');
        SkipFirstState('Skip First State');
        DoNotPlot('Do Not Plot');
    end
    
    properties
        name
    end
    
    methods
        function obj = EventPlottingMethodEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('EventPlottingMethodEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('EventPlottingMethodEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('EventPlottingMethodEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end