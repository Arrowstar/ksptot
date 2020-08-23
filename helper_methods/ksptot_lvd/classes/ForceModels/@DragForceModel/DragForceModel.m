classdef DragForceModel < AbstractForceModel
    %DragForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        function obj = DragForceModel()

        end
        
        function [forceVect,tankMdots, ecStgDots] = getForce(obj, ut, rVect, vVect, mass, bodyInfo, aero, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~)
            celBodyData = bodyInfo.celBodyData;
            CdA = aero.getArea() * aero.getDragCoeff(ut, rVect, vVect, bodyInfo, mass, celBodyData); 
            
            [~, forceVect] = getDragAccel(bodyInfo, ut, rVect, vVect, CdA, mass, 'Stock', struct());
            
            tankMdots = [];
            ecStgDots = [];
        end
    end
end