classdef SolarRadPressForceModel < AbstractForceModel
    %SolarRadPressForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = SolarRadPressForceModel()

        end
        
        function [forceVect,tankMdots, ecStgDots] = getForce(obj, ut, rVect, vVect, ~, bodyInfo, ~, ~, steeringModel, ~, ~, ~, ~, ~, ~, ~, ~, ~, srp)
            forceVect = srp.getSolarRadiationForce(ut, rVect, vVect, bodyInfo, steeringModel);
            
            tankMdots = [];
            ecStgDots = [];
        end
    end
end