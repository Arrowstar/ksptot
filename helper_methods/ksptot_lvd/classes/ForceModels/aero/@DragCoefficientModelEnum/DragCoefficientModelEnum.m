classdef DragCoefficientModelEnum < matlab.mixin.SetGet
    %DragCoefficientModelEnum Summary of this class goes here
    %   Detailed explanation goes here

    enumeration
        Constant('Constant',"Models the drag coefficient (Cd*A) as a constant value.");
        OneDim('One Dimensional', "Models the drag coefficient (Cd*A) as a function of a single user-selectable parameter.")
        TwoDimWindTunnel('Kerbal Wind Tunnel', "Uses 'drag force' flight envelope data output from the KSP Addon 'Kerbal Wind Tunnel' to model drag coefficient.")
    end

    properties
        name(1,:) char
        desc(1,1) string
    end

    methods
        function obj = DragCoefficientModelEnum(name, desc)
            obj.name = name;
            obj.desc = desc;
        end
    end

    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('DragCoefficientModelEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
            m = m(I);
        end
    end
end