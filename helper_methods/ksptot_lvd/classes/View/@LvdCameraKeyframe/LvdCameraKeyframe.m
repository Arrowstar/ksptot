classdef LvdCameraKeyframe < matlab.mixin.SetGet
    %LvdCameraKeyframe One entry of an LvdCameraScript: a camera pose that
    %is reached at a time and held for a duration.
    %
    %   Time anchoring (anchorType):
    %       AbsoluteTime - absTime is the UT in seconds.
    %       EventStart   - first logged time of `event` plus timeOffset.
    %       EventEnd     - last logged time of `event` plus timeOffset.
    %   When an event anchor cannot be resolved (no event, or the event has
    %   not been propagated) the keyframe falls back to absTime + timeOffset.
    %
    %   Pose reference (refType):
    %       SceneFixed          - camPosition / camTarget / camUpVector in the
    %                             view frame (km).
    %       VehicleRelative     - azDeg / elDeg / rangeKm about the vehicle,
    %                             looking at the vehicle.
    %       FixedAnchorTracking - the camera sits at `anchor` (an embedded
    %                             LvdFixedAnchorCameraSettings) and tracks the
    %                             vehicle.  `viewAngleDeg` remains the FOV.
    %
    %   `easing` shapes the transition from this keyframe to the NEXT one.

    properties
        name(1,:) char = 'Keyframe';

        anchorType(1,1) LvdCameraKeyframeAnchorEnum = LvdCameraKeyframeAnchorEnum.AbsoluteTime;
        absTime(1,1) double = 0;          %sec UT
        event LaunchVehicleEvent          %may be empty
        timeOffset(1,1) double = 0;       %sec, added for event anchors
        holdDuration(1,1) double {mustBeNonnegative} = 0;

        refType(1,1) LvdCameraKeyframeRefEnum = LvdCameraKeyframeRefEnum.SceneFixed;
        easing(1,1) LvdCameraEasingEnum = LvdCameraEasingEnum.SmoothStep;

        %scene-fixed pose (view frame, km)
        camPosition(1,3) double = [1e4 1e4 1e4];
        camTarget(1,3) double = [0 0 0];
        camUpVector(1,3) double = [0 0 1];

        %vehicle-relative pose
        azDeg(1,1) double = 45;
        elDeg(1,1) double = 20;
        rangeKm(1,1) double {mustBePositive} = 50;

        %fixed-anchor tracking pose.  Declared with no default expression so
        %every keyframe gets its OWN anchor (a default handle expression would
        %be created once and shared across all instances); the constructor and
        %loadobj create it.  copy() deep-copies it.
        anchor LvdFixedAnchorCameraSettings

        viewAngleDeg(1,1) double = 10;    %NaN = leave the axes' view angle alone
    end

    methods
        function obj = LvdCameraKeyframe()
            obj.anchor = LvdFixedAnchorCameraSettings();
        end

        function [t, resolved] = resolveTime(obj, stateLog)
            %resolveTime The keyframe's time in seconds UT.  `resolved` is
            %false when an event anchor fell back to absTime.
            arguments
                obj(1,1) LvdCameraKeyframe
                stateLog = []
            end

            resolved = true;
            switch(obj.anchorType)
                case LvdCameraKeyframeAnchorEnum.AbsoluteTime
                    t = obj.absTime;
                    return;

                case {LvdCameraKeyframeAnchorEnum.EventStart, LvdCameraKeyframeAnchorEnum.EventEnd}
                    entries = obj.getEventEntries(stateLog);
                    if(isempty(entries))
                        t = obj.absTime + obj.timeOffset;
                        resolved = false;
                        return;
                    end

                    if(obj.anchorType == LvdCameraKeyframeAnchorEnum.EventStart)
                        t = entries(1).time + obj.timeOffset;
                    else
                        t = entries(end).time + obj.timeOffset;
                    end

                otherwise
                    error('LvdCameraKeyframe:badAnchor', 'Unknown keyframe anchor type.');
            end
        end

        function tf = usesEvent(obj, evt)
            tf = obj.anchorType ~= LvdCameraKeyframeAnchorEnum.AbsoluteTime && ...
                 not(isempty(obj.event)) && isvalid(obj.event) && obj.event == evt;
        end

        function convertToAbsoluteTime(obj, stateLog)
            %convertToAbsoluteTime Freezes an event-anchored keyframe at its
            %currently resolved time so a deleted event leaves no dangling
            %reference.
            arguments
                obj(1,1) LvdCameraKeyframe
                stateLog = []
            end
            if(obj.anchorType == LvdCameraKeyframeAnchorEnum.AbsoluteTime)
                return;
            end
            t = obj.resolveTime(stateLog);
            obj.anchorType = LvdCameraKeyframeAnchorEnum.AbsoluteTime;
            obj.absTime = t;
            obj.timeOffset = 0;
            obj.event = LaunchVehicleEvent.empty(1,0);
        end

        function pose = getPoseAtVehiclePosition(obj, vehPos, time, viewFrame)
            %getPoseAtVehiclePosition The concrete camera pose.  vehPos is
            %used by vehicle-relative and fixed-anchor tracking keyframes; pass
            %NaN(3,1) when it is unknown (the pose is then empty).  time and
            %viewFrame are only used by fixed-anchor tracking keyframes (to
            %resolve the anchor into the view frame); a fixed-anchor keyframe
            %returns [] when viewFrame is empty.
            arguments
                obj(1,1) LvdCameraKeyframe
                vehPos
                time(1,1) double = NaN
                viewFrame = []
            end
            switch(obj.refType)
                case LvdCameraKeyframeRefEnum.SceneFixed
                    pose = LvdCameraMath.makePose(obj.camPosition, obj.camTarget, obj.camUpVector, obj.viewAngleDeg);

                case LvdCameraKeyframeRefEnum.VehicleRelative
                    pose = LvdCameraMath.chasePose(vehPos, obj.azDeg, obj.elDeg, obj.rangeKm, obj.viewAngleDeg);

                case LvdCameraKeyframeRefEnum.FixedAnchorTracking
                    if(isempty(viewFrame))
                        pose = [];
                        return;
                    end
                    anchorPos = obj.anchor.getAnchorPosAtTime(time, viewFrame);
                    pose = LvdCameraMath.trackPose(anchorPos, vehPos, obj.viewAngleDeg);

                otherwise
                    error('LvdCameraKeyframe:badRefType', 'Unknown keyframe reference type.');
            end
        end

        function str = getAnchorStr(obj, script)
            %getAnchorStr Human readable anchor description.
            arguments
                obj(1,1) LvdCameraKeyframe
                script = []
            end
            switch(obj.anchorType)
                case LvdCameraKeyframeAnchorEnum.AbsoluteTime
                    str = sprintf('UT %.3f s', obj.absTime);
                otherwise
                    if(obj.anchorType == LvdCameraKeyframeAnchorEnum.EventStart)
                        what = 'start';
                    else
                        what = 'end';
                    end
                    evtStr = obj.getEventDescription(script);
                    str = sprintf('%s of %s %+.3f s', what, evtStr, obj.timeOffset);
            end
        end

        function str = getListboxStr(obj, script)
            arguments
                obj(1,1) LvdCameraKeyframe
                script = []
            end
            str = sprintf('%s (%s, %s, hold %.1f s)', obj.name, obj.getAnchorStr(script), obj.refType.name, obj.holdDuration);
        end

        function newObj = copy(obj)
            newObj = LvdCameraKeyframe();
            props = properties(obj);
            for(i=1:numel(props)) %#ok<*NO4LP>
                if(strcmp(props{i}, 'anchor'))
                    continue;   %owned handle - deep-copied below
                end
                newObj.(props{i}) = obj.(props{i});
            end
            %the anchor is an owned handle; deep-copy so editing the copy's
            %anchor does not mutate the original keyframe's anchor.
            if(not(isempty(obj.anchor)))
                newObj.anchor = obj.anchor.copy();
            end
        end
    end

    methods(Access = private)
        function entries = getEventEntries(obj, stateLog)
            entries = [];
            if(isempty(obj.event) || not(isvalid(obj.event)) || isempty(stateLog))
                return;
            end

            try
                entries = stateLog.getAllStateLogEntriesForEvent(obj.event);
            catch
                entries = [];
                return;
            end

            if(isempty(entries))
                return;
            end

            switch(obj.event.plotMethod)
                case EventPlottingMethodEnum.PlotContinuous
                    %nothing
                case EventPlottingMethodEnum.SkipFirstState
                    entries = entries(2:end);
                case EventPlottingMethodEnum.DoNotPlot
                    entries = [];
                otherwise
                    %unknown: treat as continuous
            end
        end

        function str = getEventDescription(obj, script)
            if(isempty(obj.event) || not(isvalid(obj.event)))
                str = '<no event>';
                return;
            end
            num = [];
            if(not(isempty(script)))
                try
                    num = script.getNumOfEvent(obj.event);
                catch
                    num = [];
                end
            end
            if(isempty(num))
                try
                    num = obj.event.getEventNum();
                catch
                    num = [];
                end
            end
            if(isempty(num))
                str = sprintf('"%s"', obj.event.name);
            else
                str = sprintf('Event %u', num);
            end
        end
    end

    methods(Static)
        function kf = fromSceneCamera(hAx, time)
            %fromSceneCamera A scene-fixed keyframe capturing the axes' camera.
            arguments
                hAx
                time(1,1) double = 0
            end
            kf = LvdCameraKeyframe();
            kf.absTime = time;
            kf.refType = LvdCameraKeyframeRefEnum.SceneFixed;
            kf.camPosition = reshape(hAx.CameraPosition,1,3);
            kf.camTarget = reshape(hAx.CameraTarget,1,3);
            kf.camUpVector = reshape(hAx.CameraUpVector,1,3);
            kf.viewAngleDeg = hAx.CameraViewAngle;
        end

        function kf = fromCameraRelativeToVehicle(hAx, vehPos, time)
            %fromCameraRelativeToVehicle A vehicle-relative keyframe whose
            %az/el/range reproduce the axes' current camera position.
            arguments
                hAx
                vehPos(3,1) double
                time(1,1) double = 0
            end
            kf = LvdCameraKeyframe();
            kf.absTime = time;
            kf.refType = LvdCameraKeyframeRefEnum.VehicleRelative;
            [az, el, r] = LvdCameraMath.cartesianToSpherical(reshape(hAx.CameraPosition,1,3) - vehPos');
            kf.azDeg = az;
            kf.elDeg = el;
            kf.rangeKm = max(r, 1e-6);
            kf.viewAngleDeg = hAx.CameraViewAngle;
        end

        function obj = loadobj(obj)
            if(isstruct(obj))
                s = obj;
                obj = LvdCameraKeyframe();
                props = properties(obj);
                for(i=1:numel(props))
                    if(isfield(s, props{i}))
                        try
                            obj.(props{i}) = s.(props{i});
                        catch
                        end
                    end
                end
            end
            %back-compat: saves predating the anchor property (or an old object
            %loaded with the added property empty) get a fresh anchor.
            if(isempty(obj.anchor))
                obj.anchor = LvdFixedAnchorCameraSettings();
            end
        end
    end
end
