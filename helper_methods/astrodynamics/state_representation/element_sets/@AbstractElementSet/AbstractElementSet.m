classdef (Abstract) AbstractElementSet < matlab.mixin.SetGet & matlab.mixin.CustomDisplay
    %AbstractElementSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        time(1,1) double %UT sec
        frame AbstractReferenceFrame
    end
    
    properties(Abstract, Constant)
        typeEnum
    end
    
    methods
        cartElemSet = convertToCartesianElementSet(obj)
        
        kepElemSet = convertToKeplerianElementSet(obj)
        
        geoElemSet = convertToGeographicElementSet(obj)
        
        univElemSet = convertToUniversalElementSet(obj)
        
        elemVect = getElementVector(obj)
        
        function convertedElemSet = convertToFrame(obj, toFrame)
            if(obj.frame == toFrame)
                convertedElemSet = obj;
                return;
            end
            
            cartElemSet = obj.convertToCartesianElementSet();
            rVect1 = cartElemSet.rVect;
            vVect1 = cartElemSet.vVect;
            
            [posOffsetOrigin12, velOffsetOrigin12, angVelWrtOrigin12, rotMatToInertial12] = obj.frame.getOffsetsWrtInertialOrigin(obj.time);
            rVect2 = posOffsetOrigin12 + rotMatToInertial12*rVect1;
            vVect2 = velOffsetOrigin12 + rotMatToInertial12*(vVect1 + crossARH(angVelWrtOrigin12, rVect1));
            
            [posOffsetOrigin32, velOffsetOrigin32, angVelWrtOrigin32, rotMatToInertial32] = toFrame.getOffsetsWrtInertialOrigin(obj.time);
            rVect3 = rotMatToInertial32'*(rVect2 - posOffsetOrigin32);
            vVect3 = rotMatToInertial32'*(vVect2 - velOffsetOrigin32) - crossARH(angVelWrtOrigin32, rVect3);
            
            convertCartElemSet = CartesianElementSet(obj.time, rVect3, vVect3, toFrame);
            
            if(isa(obj, 'CartesianElementSet'))
                convertedElemSet = convertCartElemSet;
                
            elseif(isa(obj, 'KeplerianElementSet'))
                convertedElemSet = convertCartElemSet.convertToKeplerianElementSet();
                
            elseif(isa(obj, 'GeographicElementSet'))
                convertedElemSet = convertCartElemSet.convertToGeographicElementSet();
                
            elseif(isa(obj,'UniversalElementSet'))
                convertedElemSet = convertCartElemSet.convertToUniversalElementSet();
            else
                error('Unknown element set: %s', class(obj));
            end
        end
    end
    
    methods(Static)
        elemSet = getDefaultElements();
    end
end