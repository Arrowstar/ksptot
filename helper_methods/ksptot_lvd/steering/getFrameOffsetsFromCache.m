function [posOffsetOrigin, velOffsetOrigin, angVelWrtOrigin, rotMatToInertial] = getFrameOffsetsFromCache(frame, ut)
%GETFRAMEOFFSETSFROMCACHE Frame offsets with single-slot time caching.
%   Returns the frame's offsets/rotation w.r.t. the global inertial origin
%   at ut, reusing the frame's single-slot time cache when the requested
%   time matches the cached one (mirrors AbstractElementSet.convertToFrame
%   cache semantics exactly) and recomputing otherwise.

    if(numel(frame.timeCache) > 0 && frame.timeCache(1) == ut)
        posOffsetOrigin = frame.posOffsetOriginCache(:,1);
        velOffsetOrigin = frame.velOffsetOriginCache(:,1);
        angVelWrtOrigin = frame.angVelWrtOriginCache(:,1);
        rotMatToInertial = frame.rotMatToInertialCache(:,:,1);
    else
        [posOffsetOrigin, velOffsetOrigin, angVelWrtOrigin, rotMatToInertial] = frame.getOffsetsWrtInertialOrigin(ut, [], []);

        frame.timeCache = ut;
        frame.posOffsetOriginCache = posOffsetOrigin;
        frame.velOffsetOriginCache = velOffsetOrigin;
        frame.angVelWrtOriginCache = angVelWrtOrigin;
        frame.rotMatToInertialCache = rotMatToInertial;
    end
end