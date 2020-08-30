classdef DragForceModel < AbstractForceModel
    %DragForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        function obj = DragForceModel()

        end
        
        function [forceVect,tankMdots, ecStgDots] = getForce(obj, ut, rVect, vVect, mass, bodyInfo, aero, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~)
            if(norm(rVect) - (bodyInfo.radius + bodyInfo.atmohgt) > 0)
                forceVect = [0;0;0];
            else
                celBodyData = bodyInfo.celBodyData;
                CdA = aero.getArea() * aero.getDragCoeff(ut, rVect, vVect, bodyInfo, mass, celBodyData); 

                [~, forceVect] = getDragAccel(bodyInfo, ut, rVect, vVect, CdA, mass, 'Stock', struct());
            end
            
            tankMdots = [];
            ecStgDots = [];
        end
    end
end