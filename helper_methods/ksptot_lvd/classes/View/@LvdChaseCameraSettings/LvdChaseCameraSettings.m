classdef LvdChaseCameraSettings < matlab.mixin.SetGet
    %LvdChaseCameraSettings Fixed azimuth/elevation/range offset from the
    %vehicle used by the Chase camera mode of the LVD 3-D view.

    properties
        azDeg(1,1) double = 45;
        elDeg(1,1) double = 20;
        rangeKm(1,1) double {mustBePositive} = 50;
        viewAngleDeg(1,1) double = 10;   %NaN = leave the axes' view angle alone
    end

    methods
        function obj = LvdChaseCameraSettings()

        end

        function pose = getPose(obj, vehPos)
            %getPose Camera pose for a vehicle at vehPos (view frame, km).
            pose = LvdCameraMath.chasePose(vehPos, obj.azDeg, obj.elDeg, obj.rangeKm, obj.viewAngleDeg);
        end

        function setFromCamera(obj, hAx, vehPos)
            %setFromCamera Reproduces the axes' current camera position as an
            %offset from vehPos.
            arguments
                obj(1,1) LvdChaseCameraSettings
                hAx
                vehPos(3,1) double
            end
            [az, el, r] = LvdCameraMath.cartesianToSpherical(reshape(hAx.CameraPosition,1,3) - vehPos');
            obj.azDeg = az;
            obj.elDeg = el;
            obj.rangeKm = max(r, 1e-6);
            obj.viewAngleDeg = hAx.CameraViewAngle;
        end
    end

    methods(Static)
        function obj = loadobj(obj)
            if(isstruct(obj))
                s = obj;
                obj = LvdChaseCameraSettings();
                props = properties(obj);
                for(i=1:numel(props)) %#ok<*NO4LP>
                    if(isfield(s, props{i}))
                        try
                            obj.(props{i}) = s.(props{i});
                        catch
                        end
                    end
                end
            end
        end
    end
end
