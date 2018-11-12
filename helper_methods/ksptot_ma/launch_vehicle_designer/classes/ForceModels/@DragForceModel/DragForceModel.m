classdef DragForceModel < AbstractForceModel
    %DragForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        function obj = DragForceModel()

        end
        
        function forceVect = getForce(obj, ut, rVect, vVect, mass, bodyInfo, CdA, ~, ~, ~, ~, ~)
            [~, forceVect] = getDragAccel(bodyInfo, ut, rVect, vVect, CdA, mass, 'Stock');
        end
    end
end