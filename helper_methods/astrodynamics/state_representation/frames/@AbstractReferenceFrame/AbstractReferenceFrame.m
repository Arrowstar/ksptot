classdef (Abstract) AbstractReferenceFrame < matlab.mixin.SetGet & matlab.mixin.Heterogeneous & matlab.mixin.CustomDisplay
    %AbstractReferenceFrame Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Abstract, Constant)
        typeEnum
    end
    
    properties(Transient)
        timeCache
        posOffsetOriginCache
        velOffsetOriginCache
        angVelWrtOriginCache
        rotMatToInertialCache
    end
    
    methods        
        [posOffsetOrigin, velOffsetOrigin, angVelWrtOrigin, rotMatToInertial] = getOffsetsWrtInertialOrigin(obj, time, vehElemSet)
        
        bodyInfo = getOriginBody(obj)
        
        setOriginBody(obj, newBodyInfo)
        
        nameStr = getNameStr(obj)
        
        editFrameDialogUI(obj, context)
        
        function [posOffsetOrigin, velOffsetOrigin, angVelWrtOrigin, rotMatToInertial] = getOffsetsFromCache(obj, times, vehElemSet)
            posOffsetOrigin = NaN(3,numel(times));
            velOffsetOrigin = NaN(3,numel(times));
            angVelWrtOrigin = NaN(3,numel(times));
            rotMatToInertial = NaN(3,3,numel(times));
            
            for(i=1:length(times))
                time = times(i);
                
                bool = time == obj.timeCache;
                if(any(bool))
                    posOffsetOrigin(:,i) = obj.posOffsetOriginCache(:,bool);
                    velOffsetOrigin(:,i) = obj.velOffsetOriginCache(:,bool);
                    angVelWrtOrigin(:,i) = obj.angVelWrtOriginCache(:,bool);
                    rotMatToInertial(:,:,i) = obj.rotMatToInertialCache(:,:,bool);
                else
                    [posOffsetOrigin(:,i), velOffsetOrigin(:,i), angVelWrtOrigin(:,i), rotMatToInertial(:,:,i)] = obj.getOffsetsWrtInertialOrigin(time, vehElemSet);
 
                    obj.timeCache = horzcat(obj.timeCache, time);
                    obj.posOffsetOriginCache = horzcat(obj.posOffsetOriginCache, posOffsetOrigin(:,i));
                    obj.velOffsetOriginCache = horzcat(obj.velOffsetOriginCache, velOffsetOrigin(:,i));
                    obj.angVelWrtOriginCache = horzcat(obj.angVelWrtOriginCache, angVelWrtOrigin(:,i));
                    obj.rotMatToInertialCache = cat(3,obj.rotMatToInertialCache, rotMatToInertial(:,:,i));
                end
            end
        end
    end
    
    methods(Access=protected)        
        function displayScalarObject(obj)
            fprintf('%s\n',obj.getNameStr());
        end        
    end
end