classdef LaunchVehicleEngine < matlab.mixin.SetGet
    %LaunchVehicleEngine Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        vacThrust@double = 0     %kN
        vacIsp@double =  0       %sec
        seaLvlThrust@double = 0  %kN
        seaLvlIsp@double = 0     %sec
    end
    
    properties(Constant)
        vacPress = 0;            %kPa
        seaLvlPress = 101.325;   %kPa
    end
    
    methods
        function obj = LaunchVehicleEngine()
            
        end
        
        function [thrust, isp] = getThrustIspForPressure(obj, presskPa)
            x = presskPa;
            x1 = obj.seaLvlPress;
            x2 = obj.vacPress;
            
            y1 = obj.seaLvlThrust;
            y2 = obj.vacThrust;
            thrust = y1 + ((x-x1)*(y2-y1))/(x2-x1);
            
            y1 = obj.seaLvlIsp;
            y2 = obj.vacIsp;
            isp = y1 + ((x-x1)*(y2-y1))/(x2-x1);
        end
    end
end