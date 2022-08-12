classdef(Abstract) AbstractSolarRadiationPressureModel < matlab.mixin.SetGet & matlab.mixin.Copyable
    %AbstractSolarRadiationPressureModel Summary of this class goes here
    %   Detailed explanation goes here

    properties(Constant)
        c(1,1) double = 299792458; %m/s, speed of light
    end

    properties(Constant, Abstract)
        enum(1,1) SolarRadPressModelEnum
    end

    methods
        fSR = getSolarRadiationForce(obj, elemSet, steeringModel)
    end
end