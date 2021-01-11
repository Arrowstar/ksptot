classdef FixedVectorInFrame < AbstractGeometricVector
    %FixedVectorInFrame Provides the vector from point 1 to point 2.
    %   Detailed explanation goes here
    
    properties
        cartElem(1,1) CartesianElementSet 
    end
    
    methods        
        function obj = FixedVectorInFrame(vect, frame) 
            obj.cartElem = CartesianElementSet(0, vect(:), [0;0;0], frame);
        end
        
        function vect = getVectorAtTime(obj, time, inFrame)
            obj.cartElem.time = time;
            newCartElem = obj.cartElem.convertToFrame(inFrame);
            vect = newCartElem.rVect;
        end
    end
end