classdef DragForceModel < AbstractForceModel
    %AbstractForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        area(1,1) double = 0 %m^2
        dragCoeff(1,1) double = 2.2 %ND
    end
    
    methods
        function obj = GravityForceModel(area, dragCoeff)
            obj.area = area;
            obj.dragCoeff = dragCoeff;
        end
        
        function forceVect = getForce(obj, stateLogEntry)
            [ut, rVect, vVect, mass, bodyInfo] = obj.getParamsFromStateLogEntry(stateLogEntry);
            
            cdA = obj.area * obj.dragCoeff;
            [~, forceVect] = getDragAccel(bodyInfo, ut, rVect, vVect, cdA, mass, 'Stock');
        end
    end
end