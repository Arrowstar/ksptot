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
            
            [posOffsetOrigin23, velOffsetOrigin23, angVelWrtOrigin23, rotMatToInertial23] = toFrame.getOffsetsWrtInertialOrigin(obj.time);
            rVect3 = rotMatToInertial23'*(rVect2 - posOffsetOrigin23);
            vVect3 = rotMatToInertial23'*(vVect2 - velOffsetOrigin23) - crossARH(angVelWrtOrigin23, rVect3);
            
            convertCartElemSet = CartesianElementSet(obj.time, rVect3, vVect3, toFrame);
            
            if(isa(obj, 'CartesianElementSet'))
                convertedElemSet = convertCartElemSet;
                
            elseif(isa(obj, 'KeplerianElementSet'))
                convertedElemSet = convertCartElemSet.convertToKeplerianElementSet();
                
            elseif(isa(obj, 'GeographicElementSet'))
                convertedElemSet = convertCartElemSet.convertToGeographicElementSet();
                
            else
                error('Unknown element set frame type: %s', class(toFrame));
            end
        end
    end
    
    methods(Static)
        elemSet = getDefaultElements();
    end
end