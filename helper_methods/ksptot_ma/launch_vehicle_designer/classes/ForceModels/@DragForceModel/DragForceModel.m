classdef DragForceModel < AbstractForceModel
    %DragForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        function obj = DragForceModel()

        end
        
        function forceVect = getForce(obj, ut, rVect, vVect, mass, bodyInfo, CdA, ~, ~, ~, ~, ~)
%             [ut, rVect, vVect, mass, bodyInfo, CdA] = obj.getParamsFromStateLogEntry(stateLogEntry);

            [~, forceVect] = getDragAccel(bodyInfo, ut, rVect, vVect, CdA, mass, 'Stock');
        end
    end
end