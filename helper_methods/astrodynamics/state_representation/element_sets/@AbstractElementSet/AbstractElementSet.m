classdef (Abstract) AbstractElementSet < matlab.mixin.SetGet & matlab.mixin.CustomDisplay & matlab.mixin.Copyable
    %AbstractElementSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        time%(1,1) double %UT sec
        frame  = AbstractReferenceFrame.empty(1,0);
        createObjOfArray = false;
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
        
        %obj is vector of elements, toFrame is scaler
        function convertedElemSet = convertToFrame(obj, toFrame)            
            obj = obj(:)';
            num = length(obj);
            
            convertCartElemSet = convertToCartesianElementSet(obj);
            rVect1 = [convertCartElemSet.rVect];
            vVect1 = [convertCartElemSet.vVect];
            
            if(numel(obj) == 1)
                framesBool = true;
                frameToUse = obj.frame;
            else
                frames = [obj.frame];
                framesBool = frames(1) == frames;
                frameToUse = frames(1);
            end
            times = [obj.time];
                       
            if(all(framesBool))
                if(numel(times) == 1 && frameToUse.timeCache == times) %#ok<BDSCI>
                    posOffsetOrigin12 = frameToUse.posOffsetOriginCache;
                    velOffsetOrigin12 = frameToUse.velOffsetOriginCache;
                    angVelWrtOrigin12 = frameToUse.angVelWrtOriginCache;
                    rotMatToInertial12 = frameToUse.rotMatToInertialCache;
                else
                    [posOffsetOrigin12, velOffsetOrigin12, angVelWrtOrigin12, rotMatToInertial12] = getOffsetsWrtInertialOrigin(frameToUse, times, convertCartElemSet);
                    
                    if(numel(times) == 1)
                        frameToUse.timeCache = times;
                        frameToUse.posOffsetOriginCache = posOffsetOrigin12;
                        frameToUse.velOffsetOriginCache = velOffsetOrigin12;
                        frameToUse.angVelWrtOriginCache = angVelWrtOrigin12;
                        frameToUse.rotMatToInertialCache = rotMatToInertial12;                        
                    end
                end
            else
                posOffsetOrigin12 = NaN(3,num);
                velOffsetOrigin12 = NaN(3,num);
                angVelWrtOrigin12 = NaN(3,num);
                rotMatToInertial12 = NaN(3,3,num);
                for(i=1:num)
                    [posOffsetOrigin12(:,i), velOffsetOrigin12(:,i), angVelWrtOrigin12(:,i), rotMatToInertial12(:,:,i)] = obj(i).frame.getOffsetsWrtInertialOrigin(obj(i).time, convertCartElemSet(i));
                end
            end

            rVect2 = posOffsetOrigin12 + squeeze(mtimesx(rotMatToInertial12, permute(rVect1, [1 3 2])));
            vVect2 = velOffsetOrigin12 + squeeze(mtimesx(rotMatToInertial12, (permute(vVect1 + cross(angVelWrtOrigin12, rVect1), [1 3 2]))));
            
            if(numel(times) == 1 && toFrame.timeCache == times) %#ok<BDSCI>
                posOffsetOrigin32 = toFrame.posOffsetOriginCache;
                velOffsetOrigin32 = toFrame.velOffsetOriginCache;
                angVelWrtOrigin32 = toFrame.angVelWrtOriginCache;
                rotMatToInertial32 = toFrame.rotMatToInertialCache;
            else
                [posOffsetOrigin32, velOffsetOrigin32, angVelWrtOrigin32, rotMatToInertial32] = getOffsetsWrtInertialOrigin(toFrame, times, convertCartElemSet);
                
                if(numel(times) == 1)
                    toFrame.timeCache = times;
                    toFrame.posOffsetOriginCache = posOffsetOrigin32;
                    toFrame.velOffsetOriginCache = velOffsetOrigin32;
                    toFrame.angVelWrtOriginCache = angVelWrtOrigin32;
                    toFrame.rotMatToInertialCache = rotMatToInertial32;                        
                end
            end
            
            rVect3 = squeeze(mtimesx(permute(rotMatToInertial32, [2 1 3]), permute(rVect2 - posOffsetOrigin32, [1 3 2])));
            vVect3 = squeeze(mtimesx(permute(rotMatToInertial32, [2 1 3]), permute(vVect2 - velOffsetOrigin32, [1 3 2]))) - cross(angVelWrtOrigin32, rVect3);
            
            createObjOfArrayVal = false;
            if(numel(obj) == 1 && obj.createObjOfArray == true && obj.typeEnum == ElementSetEnum.CartesianElements) %#ok<BDSCI>
                createObjOfArrayVal = true;
            end
            
            convertCartElemSet = CartesianElementSet(times, rVect3, vVect3, toFrame, createObjOfArrayVal);            
            
            switch obj(1).typeEnum
                case ElementSetEnum.CartesianElements
                    convertedElemSet = convertCartElemSet;
                    
                case ElementSetEnum.KeplerianElements
                    convertedElemSet = convertToKeplerianElementSet(convertCartElemSet);
                    
                case ElementSetEnum.GeographicElements
                    convertedElemSet = convertToGeographicElementSet(convertCartElemSet);
                    
                case ElementSetEnum.UniversalElements
                    convertedElemSet = convertToUniversalElementSet(convertCartElemSet);
                    
                otherwise
                    error('Unknown element set: %s', string(obj(1).typeEnum));
            end
        end
        
        function gmu = getOriginBodyGM(obj)
            gmu = obj.frame.getOriginBody().gm;
        end
    end
    
    methods(Static)
        elemSet = getDefaultElements();
    end
end