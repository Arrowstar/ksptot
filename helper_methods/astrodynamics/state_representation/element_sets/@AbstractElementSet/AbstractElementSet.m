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

        txt = getDisplayText(obj, num)
        
        %obj is vector of elements, toFrame is scaler
        function convertedElemSet = convertToFrame(obj, toFrame, overwriteElemSetValues)
            if(nargin < 3 || isempty(overwriteElemSetValues)), overwriteElemSetValues = false; end

            persistent cache;
            if(isempty(cache))
                cache.obj = CartesianElementSet.empty(0,1);
                cache.toFrame = AbstractReferenceFrame.empty(0,1);
                cache.res = CartesianElementSet.empty(0,1);
                cache.maxSize = 10;
                cache.ptr = 1;
            end

            isScalarObj = isscalar(obj);
            if(isScalarObj && ~overwriteElemSetValues)
                cObj = cache.obj;
                cToFrame = cache.toFrame;
                for i=1:length(cObj)
                    if(cObj(i) == obj && cToFrame(i) == toFrame)
                        convertedElemSet = cache.res(i);
                        return;
                    end
                end
            end

            num = numel(obj);
            if(num > 1)
                obj = obj(:)';
            end

            if(isScalarObj)
                frameToUse = obj.frame;
                allFramesSame = true;
            else
                frames = [obj.frame];
                frameToUse = frames(1);
                allFramesSame = all(frameToUse == frames);
            end

            if(allFramesSame && isscalar(toFrame) && frameToUse == toFrame)
                if(overwriteElemSetValues)
                    convertedElemSet = obj;
                else
                    convertedElemSet = copy(obj);
                end
                
                % Fall through to cache if needed
            else
                if(isa(obj, 'CartesianElementSet'))
                    convertCartElemSet = obj;
                else
                    convertCartElemSet = convertToCartesianElementSet(obj);
                end

                if(num == 1)
                    rVect1 = convertCartElemSet.rVect;
                    vVect1 = convertCartElemSet.vVect;
                    times = convertCartElemSet.time;
                else
                    rVect1 = [convertCartElemSet.rVect];
                    vVect1 = [convertCartElemSet.vVect];
                    times = [convertCartElemSet.time];
                end

                %get offsets from frame 1 to frame 2
                if(allFramesSame)  %are all the input frames the same?
                    if(isscalar(times) && numel(frameToUse.timeCache) > 0 && frameToUse.timeCache(1) == times) %#ok<BDSCI>
                        posOffsetOrigin12 = frameToUse.posOffsetOriginCache(:,1);
                        velOffsetOrigin12 = frameToUse.velOffsetOriginCache(:,1);
                        angVelWrtOrigin12 = frameToUse.angVelWrtOriginCache(:,1);
                        R_FrameToUse_to_GlobalInertial = frameToUse.rotMatToInertialCache(:,:,1); %F1 to GI
                    else
                        [posOffsetOrigin12, velOffsetOrigin12, angVelWrtOrigin12, R_FrameToUse_to_GlobalInertial] = frameToUse.getOffsetsWrtInertialOrigin(times, convertCartElemSet);

                        if(isscalar(times))
                            frameToUse.timeCache = times;
                            frameToUse.posOffsetOriginCache = posOffsetOrigin12;
                            frameToUse.velOffsetOriginCache = velOffsetOrigin12;
                            frameToUse.angVelWrtOriginCache = angVelWrtOrigin12;
                            frameToUse.rotMatToInertialCache = R_FrameToUse_to_GlobalInertial;                        
                        end
                    end
                else
                    posOffsetOrigin12 = NaN(3,num);
                    velOffsetOrigin12 = NaN(3,num);
                    angVelWrtOrigin12 = NaN(3,num);
                    R_FrameToUse_to_GlobalInertial = NaN(3,3,num);
                    for(i=1:num) %#ok<*NO4LP> 
                        [posOffsetOrigin12(:,i), velOffsetOrigin12(:,i), angVelWrtOrigin12(:,i), R_FrameToUse_to_GlobalInertial(:,:,i)] = obj(i).frame.getOffsetsWrtInertialOrigin(obj(i).time, convertCartElemSet(i));
                    end
                end

                if(numel(rVect1) == 3)
                    rVect2 = posOffsetOrigin12 + (R_FrameToUse_to_GlobalInertial * rVect1);
                    vVect2 = velOffsetOrigin12 +  R_FrameToUse_to_GlobalInertial * (vVect1 + cross(angVelWrtOrigin12, rVect1));
                else
                    rVect2 = posOffsetOrigin12 + squeeze(pagemtimes(R_FrameToUse_to_GlobalInertial, permute(rVect1, [1 3 2])));
                    vVect2 = velOffsetOrigin12 + squeeze(pagemtimes(R_FrameToUse_to_GlobalInertial, (permute(vVect1 + cross(angVelWrtOrigin12, rVect1), [1 3 2]))));
                end

                %get offsets from frame 3 to frame 2
                if(isscalar(times) && numel(toFrame.timeCache) > 0 && toFrame.timeCache(1) == times) %#ok<BDSCI>
                    posOffsetOrigin32 = toFrame.posOffsetOriginCache(:,1);
                    velOffsetOrigin32 = toFrame.velOffsetOriginCache(:,1);
                    angVelWrtOrigin32 = toFrame.angVelWrtOriginCache(:,1);
                    R_ToFrame_To_GlobalInertial = toFrame.rotMatToInertialCache(:,:,1); %VF to GI
                else
                    [posOffsetOrigin32, velOffsetOrigin32, angVelWrtOrigin32, R_ToFrame_To_GlobalInertial] = toFrame.getOffsetsWrtInertialOrigin(times, convertCartElemSet);

                    if(isscalar(times))
                        toFrame.timeCache = times;
                        toFrame.posOffsetOriginCache = posOffsetOrigin32;
                        toFrame.velOffsetOriginCache = velOffsetOrigin32;
                        toFrame.angVelWrtOriginCache = angVelWrtOrigin32;
                        toFrame.rotMatToInertialCache = R_ToFrame_To_GlobalInertial;                        
                    end
                end

                if(size(R_ToFrame_To_GlobalInertial,3) == 1)
                    R_GlobalInertial_to_ToFrame = R_ToFrame_To_GlobalInertial';
                    rVect3 = R_GlobalInertial_to_ToFrame * (rVect2 - posOffsetOrigin32);
                    vVect3 = R_GlobalInertial_to_ToFrame * (vVect2 - velOffsetOrigin32) - cross(angVelWrtOrigin32, rVect3);
                else
                    R_GlobalInertial_to_ToFrame = permute(R_ToFrame_To_GlobalInertial, [2 1 3]);
                    rVect3 = squeeze(pagemtimes(R_GlobalInertial_to_ToFrame, permute(rVect2 - posOffsetOrigin32, [1 3 2])));
                    vVect3 = squeeze(pagemtimes(R_GlobalInertial_to_ToFrame, permute(vVect2 - velOffsetOrigin32, [1 3 2]))) - cross(angVelWrtOrigin32, rVect3);
                end

                createObjOfArrayVal = false;
                if(isScalarObj && obj.createObjOfArray == true && obj.typeEnum == ElementSetEnum.CartesianElements)
                    createObjOfArrayVal = true;
                end

                if(overwriteElemSetValues == false)
                    convertedElemSet = CartesianElementSet(times, rVect3, vVect3, toFrame, createObjOfArrayVal);
                else
                    if(num == 1)
                        convertedElemSet = convertCartElemSet; % Use the input object directly
                        convertedElemSet.time = times;
                        convertedElemSet.rVect = rVect3;
                        convertedElemSet.vVect = vVect3;
                        convertedElemSet.frame = toFrame;
                        convertedElemSet.createObjOfArray = createObjOfArrayVal;
                    else
                        convertedElemSet = CartesianElementSet(times, rVect3, vVect3, toFrame, createObjOfArrayVal);   
                    end
                end

                if(obj(1).typeEnum ~= ElementSetEnum.CartesianElements)
                    enum = obj(1).typeEnum;
                    switch enum
                        case ElementSetEnum.KeplerianElements
                            convertedElemSet = convertToKeplerianElementSet(convertedElemSet);
                        case ElementSetEnum.GeographicElements
                            convertedElemSet = convertToGeographicElementSet(convertedElemSet);
                        case ElementSetEnum.UniversalElements
                            convertedElemSet = convertToUniversalElementSet(convertedElemSet);
                        otherwise
                            error('Unknown element set: %s', string(enum));
                    end
                end
            end

            if(isScalarObj && ~overwriteElemSetValues)
                cache.obj(cache.ptr) = obj;
                cache.toFrame(cache.ptr) = toFrame;
                cache.res(cache.ptr) = convertedElemSet;
                
                cache.ptr = cache.ptr + 1;
                if(cache.ptr > cache.maxSize)
                    cache.ptr = 1;
                end
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