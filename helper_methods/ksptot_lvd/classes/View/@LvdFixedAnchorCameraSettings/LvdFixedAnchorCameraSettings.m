classdef LvdFixedAnchorCameraSettings < matlab.mixin.SetGet
    %LvdFixedAnchorCameraSettings Anchor for the FixedAnchor camera mode of
    %the LVD 3-D view: the camera sits at a fixed point and tracks the
    %vehicle.  The anchor is one of a fixed XYZ coordinate (in a chosen
    %reference frame), a ground object, or a geometric point.  All anchors
    %resolve to a view-frame position at each time, so a body-fixed anchor
    %frame rotates with the planet (a true launch-pad camera) while an
    %inertial one stays put.

    properties
        anchorType(1,1) LvdCameraAnchorTypeEnum = LvdCameraAnchorTypeEnum.FixedXYZ;

        %FixedXYZ anchor: coordinate (km) expressed in anchorFrame.  An empty
        %anchorFrame means "use the view frame" (resolves to the coordinate
        %verbatim in the display frame).
        fixedPosition(1,3) double = [0 0 0];
        anchorFrame AbstractReferenceFrame

        %GroundObject / GeometricPoint anchors (references into lvdData; may
        %be empty or, after a delete, orphaned - both degrade gracefully).
        groundObject LaunchVehicleGroundObject
        geometricPoint AbstractGeometricPoint

        viewAngleDeg(1,1) double = NaN;   %NaN = leave the axes' view angle alone
    end

    methods
        function obj = LvdFixedAnchorCameraSettings()

        end

        function pos = getAnchorPosAtTime(obj, time, viewFrame)
            %getAnchorPosAtTime The anchor's position (3x1, view-frame km) at
            %`time`, or [] when it cannot be resolved (missing/orphaned
            %reference, or a time outside a ground object's waypoint range).
            pos = [];
            try
                switch(obj.anchorType)
                    case LvdCameraAnchorTypeEnum.FixedXYZ
                        fr = obj.anchorFrame;
                        if(isempty(fr) || not(all(isvalid(fr))))
                            fr = viewFrame;
                        end
                        ces = CartesianElementSet(time, obj.fixedPosition(:), [0;0;0], fr).convertToFrame(viewFrame);
                        pos = ces.rVect;

                    case LvdCameraAnchorTypeEnum.GroundObject
                        if(isempty(obj.groundObject) || not(all(isvalid(obj.groundObject))))
                            return;
                        end
                        ge = obj.groundObject.getStateAtTime(time);
                        if(isempty(ge))
                            return;
                        end
                        ces = ge.convertToCartesianElementSet().convertToFrame(viewFrame);
                        pos = ces.rVect;

                    case LvdCameraAnchorTypeEnum.GeometricPoint
                        if(isempty(obj.geometricPoint) || not(all(isvalid(obj.geometricPoint))))
                            return;
                        end
                        ces = obj.geometricPoint.getPositionAtTime(time, [], viewFrame);
                        if(isempty(ces))
                            return;
                        end
                        pos = ces.rVect;
                end
            catch
                pos = [];
            end
            if(not(isempty(pos)) && any(not(isfinite(pos(:)))))
                pos = [];
            end
        end

        function pose = getPose(obj, time, viewFrame, vehPos)
            %getPose Camera pose at `time`: fixed at the anchor, looking at
            %the vehicle.  [] when the anchor or the vehicle is unknown.
            anchorPos = obj.getAnchorPosAtTime(time, viewFrame);
            pose = LvdCameraMath.trackPose(anchorPos, vehPos, obj.viewAngleDeg);
        end

        function setFixedPositionFromCamera(obj, hAx, time, viewFrame)
            %setFixedPositionFromCamera Stores the axes' current camera
            %position as the fixed XYZ anchor, expressed in anchorFrame
            %(identity when anchorFrame is empty/the view frame), and switches
            %the anchor type to FixedXYZ.
            arguments
                obj(1,1) LvdFixedAnchorCameraSettings
                hAx
                time(1,1) double
                viewFrame(1,1) AbstractReferenceFrame
            end
            camPosView = LvdSceneNormalizer.unscalePos(reshape(hAx.CameraPosition,1,3), hAx);
            fr = obj.anchorFrame;
            if(isempty(fr) || not(all(isvalid(fr))))
                fr = viewFrame;
            end
            ces = CartesianElementSet(time, camPosView(:), [0;0;0], viewFrame).convertToFrame(fr);
            obj.fixedPosition = reshape(ces.rVect,1,3);
            obj.anchorType = LvdCameraAnchorTypeEnum.FixedXYZ;
        end

        function newObj = copy(obj)
            %copy Deep copy of the settings.  The value properties (anchor
            %type, fixed coordinate, view angle) are copied by value; the
            %anchorFrame / groundObject / geometricPoint handles are copied by
            %REFERENCE (they point into the mission model - lvdData - which we
            %reference but do not own, so both the original and the copy refer
            %to the same frame/object/point).
            newObj = LvdFixedAnchorCameraSettings();
            newObj.anchorType = obj.anchorType;
            newObj.fixedPosition = obj.fixedPosition;
            newObj.anchorFrame = obj.anchorFrame;
            newObj.groundObject = obj.groundObject;
            newObj.geometricPoint = obj.geometricPoint;
            newObj.viewAngleDeg = obj.viewAngleDeg;
        end

        function str = getSummaryStr(obj)
            %getSummaryStr Short description of the anchor for the state line.
            switch(obj.anchorType)
                case LvdCameraAnchorTypeEnum.FixedXYZ
                    str = sprintf('Fixed at [%.6g %.6g %.6g] km', obj.fixedPosition);
                case LvdCameraAnchorTypeEnum.GroundObject
                    if(isempty(obj.groundObject) || not(all(isvalid(obj.groundObject))))
                        str = 'Ground Object (none)';
                    else
                        str = sprintf('Ground Object: %s', obj.groundObject.name);
                    end
                case LvdCameraAnchorTypeEnum.GeometricPoint
                    if(isempty(obj.geometricPoint) || not(all(isvalid(obj.geometricPoint))))
                        str = 'Geometric Point (none)';
                    else
                        str = sprintf('Geometric Point: %s', obj.geometricPoint.getName());
                    end
                otherwise
                    str = '';
            end
        end
    end

    methods(Static)
        function obj = loadobj(obj)
            if(isstruct(obj))
                s = obj;
                obj = LvdFixedAnchorCameraSettings();
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
