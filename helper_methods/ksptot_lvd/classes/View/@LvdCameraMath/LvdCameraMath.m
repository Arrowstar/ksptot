classdef LvdCameraMath
    %LvdCameraMath Pure, stateless camera geometry used by the LVD 3-D view
    %chase camera, camera scripts and vehicle mesh renderer.
    %
    %   A camera "pose" is a struct with fields
    %       position  (1x3) camera location, view-frame km
    %       target    (1x3) point the camera looks at, view-frame km
    %       up        (1x3) camera up vector (unit)
    %       viewAngle (1x1) field of view, degrees (NaN = leave unchanged)
    %
    %   Vehicle-relative offsets are spherical about a centre point in the
    %   view frame: azimuth is measured from +X toward +Y, elevation from the
    %   XY plane toward +Z, range is in km.  Nothing here depends on any
    %   toolbox.

    methods(Static)
        function pose = makePose(position, target, up, viewAngle)
            pose = struct('position', reshape(position,1,3), ...
                          'target',   reshape(target,1,3), ...
                          'up',       reshape(up,1,3), ...
                          'viewAngle', viewAngle);
        end

        function pos = sphericalOffset(center, azDeg, elDeg, rangeKm)
            %sphericalOffset Point at (az, el, range) from center.
            center = reshape(center,1,3);
            az = deg2rad(azDeg);
            el = deg2rad(elDeg);
            pos = center + rangeKm * [cos(el)*cos(az), cos(el)*sin(az), sin(el)];
        end

        function [azDeg, elDeg, rangeKm] = cartesianToSpherical(d)
            %cartesianToSpherical Inverse of sphericalOffset for the offset
            %vector d = pos - center.
            d = reshape(d,1,3);
            rangeKm = norm(d);
            if(rangeKm <= 0)
                azDeg = 0;
                elDeg = 0;
                return;
            end
            azDeg = rad2deg(atan2(d(2), d(1)));
            elDeg = rad2deg(asin(max(-1, min(1, d(3)/rangeKm))));
        end

        function up = defaultUpForSightLine(sightDir)
            %defaultUpForSightLine View-frame +Z, unless the sight line is
            %within about 2.5 degrees of vertical, in which case +Y.
            sightDir = reshape(sightDir,1,3);
            n = norm(sightDir);
            up = [0 0 1];
            if(n > 0)
                cosAng = abs(sightDir(3)) / n;
                if(cosAng > cosd(2.5))
                    up = [0 1 0];
                end
            end
        end

        function v = slerp(a, b, s)
            %slerp Spherical interpolation between two direction vectors.
            %Both are normalized first; the result is a unit vector.
            a = reshape(a,1,3);
            b = reshape(b,1,3);
            na = norm(a);
            nb = norm(b);
            if(na == 0 || nb == 0)
                if(na == 0 && nb == 0)
                    v = [0 0 1];
                elseif(na == 0)
                    v = b/nb;
                else
                    v = a/na;
                end
                return;
            end
            a = a/na;
            b = b/nb;

            c = max(-1, min(1, dot(a,b)));
            omega = acos(c);

            if(omega < 1e-9)
                v = a;
            elseif(pi - omega < 1e-9)
                %antiparallel: rotate a about any perpendicular axis
                perp = cross(a, [1 0 0]);
                if(norm(perp) < 1e-6)
                    perp = cross(a, [0 1 0]);
                end
                perp = perp/norm(perp);
                ang = s*pi;
                v = a*cos(ang) + perp*sin(ang);
            else
                v = (sin((1-s)*omega)*a + sin(s*omega)*b) / sin(omega);
            end
            v = v/norm(v);
        end

        function sOut = ease(s, easing)
            %ease Shapes a blend fraction in [0,1].
            arguments
                s(1,1) double
                easing(1,1) LvdCameraEasingEnum = LvdCameraEasingEnum.Linear
            end
            s = max(0, min(1, s));
            switch(easing)
                case LvdCameraEasingEnum.Linear
                    sOut = s;
                case LvdCameraEasingEnum.SmoothStep
                    sOut = 3*s^2 - 2*s^3;
                otherwise
                    error('LvdCameraMath:badEasing', 'Unknown easing "%s".', char(easing));
            end
        end

        function ang = blendAngleDeg(a, b, s)
            %blendAngleDeg Interpolates two angles along the shortest arc.
            delta = rad2deg(angleNegPiToPi(deg2rad(b - a)));
            ang = a + s*delta;
        end

        function pose = chasePose(vehPos, azDeg, elDeg, rangeKm, viewAngleDeg)
            %chasePose Camera at a spherical offset from the vehicle, looking
            %at the vehicle.  Returns [] when the vehicle position is unknown.
            if(isempty(vehPos) || any(not(isfinite(vehPos))))
                pose = [];
                return;
            end
            vehPos = reshape(vehPos,1,3);
            position = LvdCameraMath.sphericalOffset(vehPos, azDeg, elDeg, rangeKm);
            up = LvdCameraMath.defaultUpForSightLine(vehPos - position);
            pose = LvdCameraMath.makePose(position, vehPos, up, viewAngleDeg);
        end

        function pose = trackPose(anchorPos, targetPos, viewAngleDeg)
            %trackPose Camera fixed at anchorPos, looking at targetPos (the
            %vehicle).  The inverse framing of chasePose: the position is
            %given, the target tracks.  Returns [] when either point is
            %unknown/non-finite or the two coincide (no sight line).
            if(isempty(anchorPos) || isempty(targetPos) || ...
               any(not(isfinite(anchorPos(:)))) || any(not(isfinite(targetPos(:)))))
                pose = [];
                return;
            end
            anchorPos = reshape(anchorPos,1,3);
            targetPos = reshape(targetPos,1,3);
            sightDir = targetPos - anchorPos;
            if(norm(sightDir) <= 0)
                pose = [];
                return;
            end
            up = LvdCameraMath.defaultUpForSightLine(sightDir);
            pose = LvdCameraMath.makePose(anchorPos, targetPos, up, viewAngleDeg);
        end

        function pose = blendPoses(pA, pB, s)
            %blendPoses Lerps position and target, slerps up, lerps view angle.
            position = (1-s)*pA.position + s*pB.position;
            target = (1-s)*pA.target + s*pB.target;
            up = LvdCameraMath.slerp(pA.up, pB.up, s);

            vaA = pA.viewAngle;
            vaB = pB.viewAngle;
            if(isnan(vaA) && isnan(vaB))
                viewAngle = NaN;
            elseif(isnan(vaA))
                viewAngle = vaB;
            elseif(isnan(vaB))
                viewAngle = vaA;
            else
                viewAngle = (1-s)*vaA + s*vaB;
            end

            pose = LvdCameraMath.makePose(position, target, up, viewAngle);
        end

        function R = orthonormalizeDcm(dcm)
            %orthonormalizeDcm Nearest proper rotation matrix (Frobenius) to
            %an approximately orthonormal 3x3 matrix, via SVD.
            if(any(not(isfinite(dcm(:)))))
                R = eye(3);
                return;
            end
            [U, ~, W] = svd(dcm);
            R = U*W';
            if(det(R) < 0)
                U(:,3) = -U(:,3);
                R = U*W';
            end
        end

        function applyPoseToAxes(pose, hAx)
            %applyPoseToAxes Writes a pose onto an axes' camera properties.
            if(isempty(pose))
                return;
            end
            hAx.CameraPositionMode = 'manual';
            hAx.CameraTargetMode = 'manual';
            hAx.CameraUpVectorMode = 'manual';
            %position first, target last: the LVD main window listens on
            %CameraPosition and (in toolbar dolly mode) moves the target to
            %keep the camera distance, so the target write must be the final
            %word for the target to land where the pose says
            hAx.CameraPosition = pose.position;
            hAx.CameraTarget = pose.target;
            hAx.CameraUpVector = pose.up;
            if(not(isnan(pose.viewAngle)) && pose.viewAngle > 0 && pose.viewAngle < 180)
                hAx.CameraViewAngleMode = 'manual';
                hAx.CameraViewAngle = pose.viewAngle;
            end
        end

        function pose = poseFromAxes(hAx)
            %poseFromAxes Reads the current camera of an axes as a pose.
            pose = LvdCameraMath.makePose(hAx.CameraPosition, hAx.CameraTarget, hAx.CameraUpVector, hAx.CameraViewAngle);
        end
    end
end
