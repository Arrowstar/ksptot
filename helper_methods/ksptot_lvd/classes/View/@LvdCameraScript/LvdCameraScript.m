classdef LvdCameraScript < matlab.mixin.SetGet
    %LvdCameraScript An ordered set of camera keyframes evaluated against
    %time to drive the LVD 3-D view camera.
    %
    %   Each keyframe k occupies [tStart(k), tStart(k) + holdDuration(k)];
    %   between the end of one hold and the start of the next keyframe the
    %   pose is blended with the earlier keyframe's easing.  Before the
    %   first keyframe and after the last one the pose is clamped.

    properties
        keyframes(1,:) LvdCameraKeyframe = LvdCameraKeyframe.empty(1,0);
    end

    methods
        function obj = LvdCameraScript()

        end

        %% ------------------------------------------------------- editing
        function addKeyframe(obj, kf)
            arguments
                obj(1,1) LvdCameraScript
                kf(1,1) LvdCameraKeyframe
            end
            obj.keyframes(end+1) = kf;
        end

        function insertKeyframe(obj, kf, ind)
            arguments
                obj(1,1) LvdCameraScript
                kf(1,1) LvdCameraKeyframe
                ind(1,1) double
            end
            n = numel(obj.keyframes);
            ind = max(1, min(n+1, round(ind)));
            obj.keyframes = [obj.keyframes(1:ind-1), kf, obj.keyframes(ind:end)];
        end

        function removeKeyframe(obj, kfOrInd)
            if(isa(kfOrInd, 'LvdCameraKeyframe'))
                obj.keyframes(obj.keyframes == kfOrInd) = [];
            else
                ind = round(kfOrInd);
                if(ind >= 1 && ind <= numel(obj.keyframes))
                    obj.keyframes(ind) = [];
                end
            end
        end

        function moveKeyframeUp(obj, ind)
            if(ind > 1 && ind <= numel(obj.keyframes))
                obj.keyframes([ind-1, ind]) = obj.keyframes([ind, ind-1]);
            end
        end

        function moveKeyframeDown(obj, ind)
            if(ind >= 1 && ind < numel(obj.keyframes))
                obj.keyframes([ind, ind+1]) = obj.keyframes([ind+1, ind]);
            end
        end

        function n = getNumKeyframes(obj)
            n = numel(obj.keyframes);
        end

        function tf = usesEvent(obj, evt)
            tf = false;
            for(i=1:numel(obj.keyframes)) %#ok<*NO4LP>
                if(obj.keyframes(i).usesEvent(evt))
                    tf = true;
                    return;
                end
            end
        end

        function removeEventReferences(obj, evt, stateLog)
            %removeEventReferences Converts every keyframe anchored to evt
            %to an absolute time so the event can be deleted safely.
            arguments
                obj(1,1) LvdCameraScript
                evt
                stateLog = []
            end
            for(i=1:numel(obj.keyframes))
                if(obj.keyframes(i).usesEvent(evt))
                    obj.keyframes(i).convertToAbsoluteTime(stateLog);
                end
            end
        end

        function strs = getListboxStrs(obj, script)
            arguments
                obj(1,1) LvdCameraScript
                script = []
            end
            strs = cell(1, numel(obj.keyframes));
            for(i=1:numel(obj.keyframes))
                strs{i} = sprintf('%u. %s', i, obj.keyframes(i).getListboxStr(script));
            end
        end

        %% ---------------------------------------------------- evaluation
        function [tStart, tEnd, order] = resolveSchedule(obj, timeResolverFcn)
            %resolveSchedule Keyframe start/end times sorted by start time.
            %   timeResolverFcn(kf) -> time (sec).  `order` maps the sorted
            %   position back to the keyframe index.
            n = numel(obj.keyframes);
            tRaw = zeros(1, n);
            for(i=1:n)
                tRaw(i) = timeResolverFcn(obj.keyframes(i));
            end
            [tStart, order] = sort(tRaw);   %sort is stable for equal keys
            tEnd = tStart + [obj.keyframes(order).holdDuration];
        end

        function pose = evaluate(obj, time, timeResolverFcn, vehPosFcn, defaultVA, viewFrame)
            %evaluate The camera pose at `time`.
            %   timeResolverFcn(kf) -> keyframe time (sec)
            %   vehPosFcn(t)        -> vehicle position, 3x1 view-frame km
            %                          (NaN(3,1) when unknown)
            %   defaultVA           -> view angle used for NaN keyframes
            %   viewFrame           -> the display reference frame, used to
            %                          resolve fixed-anchor tracking keyframes
            %                          ([] leaves such keyframes unresolvable).
            %   Returns [] when the script is empty or the pose cannot be
            %   formed (vehicle-relative keyframe with no vehicle position, or
            %   a fixed-anchor keyframe with no view frame).
            arguments
                obj(1,1) LvdCameraScript
                time(1,1) double
                timeResolverFcn(1,1) function_handle
                vehPosFcn(1,1) function_handle
                defaultVA(1,1) double = NaN
                viewFrame = []
            end

            n = numel(obj.keyframes);
            if(n == 0)
                pose = [];
                return;
            end

            [tStart, tEnd, order] = obj.resolveSchedule(timeResolverFcn);
            kfs = obj.keyframes(order);
            vehPos = [];   %lazily evaluated once
            poseOf = @(k) obj.concretePose(kfs(k), time, vehPosFcn, defaultVA, viewFrame);

            if(time <= tStart(1))
                pose = poseOf(1);
                return;
            end
            if(time >= tEnd(end))
                pose = poseOf(n);
                return;
            end

            k = find(tStart <= time, 1, 'last');
            if(time <= tEnd(k) || k == n)
                pose = poseOf(k);
                return;
            end

            %transition from k to k+1
            denom = tStart(k+1) - tEnd(k);
            if(denom <= 0)
                s = 1;
            else
                s = (time - tEnd(k)) / denom;
            end
            s = LvdCameraMath.ease(s, kfs(k).easing);

            kfA = kfs(k);
            kfB = kfs(k+1);
            if(kfA.refType == LvdCameraKeyframeRefEnum.VehicleRelative && ...
               kfB.refType == LvdCameraKeyframeRefEnum.VehicleRelative)
                %stay on the sphere around the vehicle during the blend
                az = LvdCameraMath.blendAngleDeg(kfA.azDeg, kfB.azDeg, s);
                el = (1-s)*kfA.elDeg + s*kfB.elDeg;
                r  = (1-s)*kfA.rangeKm + s*kfB.rangeKm;
                va = LvdCameraScript.blendViewAngle(kfA.viewAngleDeg, kfB.viewAngleDeg, s, defaultVA);
                if(isempty(vehPos))
                    vehPos = vehPosFcn(time);
                end
                pose = LvdCameraMath.chasePose(vehPos, az, el, r, va);
            else
                pA = poseOf(k);
                pB = poseOf(k+1);
                if(isempty(pA) || isempty(pB))
                    pose = [];
                    return;
                end
                pose = LvdCameraMath.blendPoses(pA, pB, s);
            end
        end
    end

    methods(Access = private)
        function pose = concretePose(~, kf, time, vehPosFcn, defaultVA, viewFrame)
            arguments
                ~
                kf(1,1) LvdCameraKeyframe
                time(1,1) double
                vehPosFcn(1,1) function_handle
                defaultVA(1,1) double = NaN
                viewFrame = []
            end
            %vehicle-relative AND fixed-anchor tracking keyframes need the
            %vehicle position (the latter as the look-at target).
            if(kf.refType == LvdCameraKeyframeRefEnum.VehicleRelative || ...
               kf.refType == LvdCameraKeyframeRefEnum.FixedAnchorTracking)
                vehPos = vehPosFcn(time);
            else
                vehPos = NaN(3,1);
            end
            pose = kf.getPoseAtVehiclePosition(vehPos, time, viewFrame);
            if(not(isempty(pose)) && isnan(pose.viewAngle))
                pose.viewAngle = defaultVA;
            end
        end
    end

    methods(Static)
        function va = blendViewAngle(vaA, vaB, s, defaultVA)
            if(isnan(vaA)); vaA = defaultVA; end
            if(isnan(vaB)); vaB = defaultVA; end
            if(isnan(vaA) && isnan(vaB))
                va = NaN;
            elseif(isnan(vaA))
                va = vaB;
            elseif(isnan(vaB))
                va = vaA;
            else
                va = (1-s)*vaA + s*vaB;
            end
        end

        function obj = loadobj(obj)
            if(isstruct(obj))
                s = obj;
                obj = LvdCameraScript();
                if(isfield(s, 'keyframes'))
                    try
                        obj.keyframes = s.keyframes;
                    catch
                    end
                end
            end
        end
    end
end
