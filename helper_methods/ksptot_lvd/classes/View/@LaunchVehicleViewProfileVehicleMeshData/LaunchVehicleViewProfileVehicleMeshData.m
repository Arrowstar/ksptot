classdef LaunchVehicleViewProfileVehicleMeshData < matlab.mixin.SetGet
    %LaunchVehicleViewProfileVehicleMeshData Draws the view profile's
    %vehicle mesh at the interpolated vehicle position and attitude.
    %
    %   Modelled on LaunchVehicleViewProfileBodyAxesData: one hgtransform
    %   per trajectory segment, created on first use and updated in place
    %   on every time-slider / playback frame.  The patch holds the mesh in
    %   the vehicle body frame (km); the transform carries the body->view
    %   rotation and the vehicle position.

    properties
        vehPosVelData LaunchVehicleViewPosVelInterp
        vehAttData LaunchVehicleViewProfileAttitudeData
        meshSettings LvdVehicleMeshSettings

        xforms(1,:) cell = {};
        patches(1,:) cell = {};
    end

    properties(Constant)
        PatchTag = 'LvdVehicleMesh';
        XformTag = 'LvdVehicleMeshXform';
    end

    methods
        function obj = LaunchVehicleViewProfileVehicleMeshData(vehPosVelData, vehAttData, meshSettings)
            obj.vehPosVelData = vehPosVelData;
            obj.vehAttData = vehAttData;
            obj.meshSettings = meshSettings;
        end

        function plotVehicleMeshAtTime(obj, time, hAx)
            if(isempty(obj.meshSettings) || not(obj.meshSettings.isRenderable()) || ...
               isempty(obj.vehPosVelData) || isempty(obj.vehAttData))
                obj.hideAll();
                return;
            end

            [rVect, ~] = obj.vehPosVelData.getPositionVelocityAtTime(time);
            dcmAll = obj.vehAttData.getDCMatTime(time);
            numPoses = min(width(rVect), size(dcmAll,3));

            for(i=1:numPoses) %#ok<*NO4LP>
                pos = rVect(:,i);
                R = LvdCameraMath.orthonormalizeDcm(dcmAll(:,:,i));

                if(numel(obj.xforms) < i)
                    obj.xforms{i} = [];
                    obj.patches{i} = [];
                end

                if(isempty(obj.xforms{i}) || not(isvalid(obj.xforms{i})))
                    obj.createGraphics(i, hAx);
                end

                set(obj.xforms{i}, 'Matrix', [R, pos(:); 0 0 0 1]);
                obj.xforms{i}.Visible = 'on';
            end

            for(i=numPoses+1:numel(obj.xforms))
                if(not(isempty(obj.xforms{i})) && isvalid(obj.xforms{i}))
                    obj.xforms{i}.Visible = 'off';
                end
            end
        end

        function refreshAppearance(obj)
            %refreshAppearance Pushes the current mesh settings (colour,
            %alpha, edges, lighting, transformed vertices) to existing
            %patches without a full replot.
            for(i=1:numel(obj.patches))
                p = obj.patches{i};
                if(not(isempty(p)) && isvalid(p))
                    obj.applyAppearance(p);
                end
            end
        end

        function xforms = getTransforms(obj)
            xforms = obj.xforms;
        end

        function hideAll(obj)
            for(i=1:numel(obj.xforms))
                if(not(isempty(obj.xforms{i})) && isvalid(obj.xforms{i}))
                    obj.xforms{i}.Visible = 'off';
                end
            end
        end

        function deleteGraphics(obj)
            for(i=1:numel(obj.xforms))
                if(not(isempty(obj.xforms{i})) && isvalid(obj.xforms{i}))
                    delete(obj.xforms{i});
                end
            end
            obj.xforms = {};
            obj.patches = {};
        end
    end

    methods(Access = private)
        function createGraphics(obj, i, hAx)
            xform = hgtransform('Parent', hAx, 'Tag', obj.XformTag);
            p = patch('Parent', xform, ...
                      'Faces', obj.meshSettings.faces, ...
                      'Vertices', obj.meshSettings.getBodyFrameVertices(), ...
                      'Tag', obj.PatchTag, ...
                      'HitTest', 'off', ...
                      'PickableParts', 'none');
            obj.applyAppearance(p);
            obj.xforms{i} = xform;
            obj.patches{i} = p;
        end

        function applyAppearance(obj, p)
            ms = obj.meshSettings;
            p.Faces = ms.faces;
            p.Vertices = ms.getBodyFrameVertices();
            p.FaceColor = ms.faceColor;
            p.FaceAlpha = ms.faceAlpha;
            if(ms.showEdges)
                p.EdgeColor = ms.edgeColor;
            else
                p.EdgeColor = 'none';
            end
            if(ms.useLighting)
                p.FaceLighting = 'gouraud';
                p.AmbientStrength = 0.4;
                p.DiffuseStrength = 0.8;
                p.SpecularStrength = 0.2;
            else
                p.FaceLighting = 'none';
            end
        end
    end
end
