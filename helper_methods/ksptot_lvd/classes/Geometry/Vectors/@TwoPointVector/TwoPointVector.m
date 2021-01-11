classdef TwoPointVector < AbstractGeometricVector
    %TwoPointVector Provides the vector from point 1 to point 2.
    %   Detailed explanation goes here
    
    properties
        point1(1,1) AbstractGeometricPoint
        point2(1,1) AbstractGeometricPoint
    end
    
    methods        
        function obj = TwoPointVector(point1, point2) 
            obj.point1 = point1;
            obj.point2 = point2;
        end
        
        function vect = getVectorAtTime(obj, time, inFrame)
            point1CartElem = obj.point1.getPositionAtTime(time, inFrame);
            rVect1 = point1CartElem.rVect;
            
            point2CartElem = obj.point2.getPositionAtTime(time, inFrame);
            rVect2 = point2CartElem.rVect;
            
            vect = rVect2(:) - rVect1(:);
        end
    end
end