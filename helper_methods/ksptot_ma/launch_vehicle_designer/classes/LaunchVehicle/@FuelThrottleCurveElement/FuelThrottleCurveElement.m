classdef FuelThrottleCurveElement < matlab.mixin.SetGet & matlab.mixin.Copyable
    %FuelThrottleCurveElement Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fuelRemainPct(1,1) double
        throttleModifier(1,1) double
    end
    
    methods
        function obj = FuelThrottleCurveElement(fuelRemainPct, throttleModifier)
            obj.fuelRemainPct = fuelRemainPct;
            obj.throttleModifier = throttleModifier;
        end
    end
end