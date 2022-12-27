classdef SolarRadPressModelEnum < matlab.mixin.SetGet
    %SolarRadPressModelEnum Summary of this class goes here
    %   Detailed explanation goes here

    enumeration
        Spherical('Spherical Model',"Models solar radiation pressure as if it was acting on a spherical spacecraft.");
        SolarSail('Solar Sail Model', "Models solar radiation pressure as if it was principally acting on a large solar sail which is fixed in the spacecraft body frame.")
    end

    properties
        name(1,:) char
        desc(1,1) string
    end

    methods
        function obj = SolarRadPressModelEnum(name, desc)
            obj.name = name;
            obj.desc = desc;
        end
    end

    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('SolarRadPressModelEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
            m = m(I);
        end
    end
end