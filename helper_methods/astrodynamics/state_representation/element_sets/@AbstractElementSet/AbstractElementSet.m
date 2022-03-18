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
            num = length(obj);
            if(num > 1)
                obj = obj(:)';
            end
                        
            if(isa(obj, 'CartesianElementSet'))
                convertCartElemSet = obj;
            else
                convertCartElemSet = convertToCartesianElementSet(obj);
            end
            
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
%                 [posOffsetOrigin12, velOffsetOrigin12, angVelWrtOrigin12, rotMatToInertial12] = frameToUse.getOffsetsFromCache(times, convertCartElemSet);
                
                if(numel(times) == 1 && numel(frameToUse.timeCache) > 0 && frameToUse.timeCache(1) == times) %#ok<BDSCI>
                    posOffsetOrigin12 = frameToUse.posOffsetOriginCache(:,1);
                    velOffsetOrigin12 = frameToUse.velOffsetOriginCache(:,1);
                    angVelWrtOrigin12 = frameToUse.angVelWrtOriginCache(:,1);
                    rotMatToInertial12 = frameToUse.rotMatToInertialCache(:,:,1);
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

            rVect2 = posOffsetOrigin12 + squeeze(pagemtimes(rotMatToInertial12, permute(rVect1, [1 3 2])));
            vVect2 = velOffsetOrigin12 + squeeze(pagemtimes(rotMatToInertial12, (permute(vVect1 + cross(angVelWrtOrigin12, rVect1), [1 3 2]))));
            
%             [posOffsetOrigin32, velOffsetOrigin32, angVelWrtOrigin32, rotMatToInertial32] = toFrame.getOffsetsFromCache(times, convertCartElemSet);
            
            if(numel(times) == 1 && numel(toFrame.timeCache) > 0 && toFrame.timeCache(1) == times) %#ok<BDSCI>
                posOffsetOrigin32 = toFrame.posOffsetOriginCache(:,1);
                velOffsetOrigin32 = toFrame.velOffsetOriginCache(:,1);
                angVelWrtOrigin32 = toFrame.angVelWrtOriginCache(:,1);
                rotMatToInertial32 = toFrame.rotMatToInertialCache(:,:,1);
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
            
            rotMatToInertial32_Transpose = permute(rotMatToInertial32, [2 1 3]);
            rVect3 = squeeze(pagemtimes(rotMatToInertial32_Transpose, permute(rVect2 - posOffsetOrigin32, [1 3 2])));
            vVect3 = squeeze(pagemtimes(rotMatToInertial32_Transpose, permute(vVect2 - velOffsetOrigin32, [1 3 2]))) - cross(angVelWrtOrigin32, rVect3);
            
            createObjOfArrayVal = false;
            if(numel(obj) == 1 && obj.createObjOfArray == true && obj.typeEnum == ElementSetEnum.CartesianElements)
                createObjOfArrayVal = true;
            end
            
            if(num == 1)
                convertCartElemSet.time = times;
                convertCartElemSet.rVect = rVect3;
                convertCartElemSet.vVect = vVect3;
                convertCartElemSet.frame = toFrame;
                convertCartElemSet.createObjOfArray = createObjOfArrayVal;
            else
                convertCartElemSet = CartesianElementSet(times, rVect3, vVect3, toFrame, createObjOfArrayVal);   
            end
            
            ce = ElementSetEnum.CartesianElements;
            ke = ElementSetEnum.KeplerianElements;
            ge = ElementSetEnum.GeographicElements;
            ue = ElementSetEnum.UniversalElements;
            
            enum = obj(1).typeEnum;
            
            switch enum
                case ce
                    convertedElemSet = convertCartElemSet;
                    
                case ke
                    convertedElemSet = convertToKeplerianElementSet(convertCartElemSet);
                    
                case ge
                    convertedElemSet = convertToGeographicElementSet(convertCartElemSet);
                    
                case ue
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