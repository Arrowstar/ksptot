classdef LiftCoefficientModelEnum < matlab.mixin.SetGet
    %LiftCoefficientModelEnum Summary of this class goes here
    %   Detailed explanation goes here

    enumeration
        KSPCylinder('KSP Cylinder',"Models the vehicle as a circular cylinder with constant radius and height whose long axis is the body X axis.  Uses the KSP 'lifting body' lift coefficient curves in physics.cfg.");
    end

    properties
        name(1,:) char
        desc(1,1) string
    end

    methods
        function obj = LiftCoefficientModelEnum(name, desc)
            obj.name = name;
            obj.desc = desc;
        end
    end

    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('LiftCoefficientModelEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
            m = m(I);
        end
    end
end