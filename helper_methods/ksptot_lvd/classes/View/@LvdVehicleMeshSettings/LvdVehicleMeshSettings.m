classdef LvdVehicleMeshSettings < matlab.mixin.SetGet
    %LvdVehicleMeshSettings A 3-D mesh drawn at the vehicle's position and
    %attitude in the LVD 3-D view, plus the transform that aligns the mesh
    %file's axes with the vehicle body axes.
    %
    %   The mesh geometry (vertices in the file's units, triangle faces) is
    %   embedded here so the mission .mat is self-contained; sourcePath
    %   records where it came from for reloadFromFile.
    %
    %   Mesh -> body transform, applied in this order:
    %       1. rotate by rotOffsetEulerDeg = [yaw pitch roll] about the mesh
    %          Z, Y, X axes (intrinsic ZYX, R = Rz*Ry*Rx)
    %       2. scale uniformly by `scale` (km per mesh unit)
    %       3. translate by transOffsetKm (body frame)
    %   i.e. p_body = scale * R * p_mesh + transOffsetKm.

    properties
        enabled(1,1) logical = false;
        sourcePath(1,1) string = "";
        vertices(:,3) double = zeros(0,3);   %mesh units, mesh frame
        faces(:,3) double = zeros(0,3);      %one-based triangle indices

        scale(1,1) double {mustBePositive} = 1;          %km per mesh unit
        rotOffsetEulerDeg(1,3) double = [0 0 0];          %yaw, pitch, roll (deg)
        transOffsetKm(1,3) double = [0 0 0];              %body frame, km

        faceColor(1,3) double = [0.8 0.8 0.8];
        faceAlpha(1,1) double {mustBeInRange(faceAlpha,0,1)} = 1;
        edgeColor(1,3) double = [0.2 0.2 0.2];
        showEdges(1,1) logical = false;
        useLighting(1,1) logical = true;
    end

    methods
        function obj = LvdVehicleMeshSettings()

        end

        function info = loadFromFile(obj, filePath)
            %loadFromFile Replaces the embedded mesh with the file's contents
            %and enables rendering.
            [V, F, info] = lvd_readMeshFile(char(filePath));
            obj.vertices = V;
            obj.faces = F;
            obj.sourcePath = string(filePath);
            obj.enabled = true;
        end

        function info = reloadFromFile(obj)
            %reloadFromFile Re-reads the embedded mesh from sourcePath.
            if(strlength(obj.sourcePath) == 0)
                error('LvdVehicleMeshSettings:noSource', 'No mesh file has been imported yet.');
            end
            if(not(isfile(obj.sourcePath)))
                error('LvdVehicleMeshSettings:noSource', 'The mesh source file no longer exists: %s', obj.sourcePath);
            end
            info = obj.loadFromFile(obj.sourcePath);
        end

        function clearMesh(obj)
            obj.vertices = zeros(0,3);
            obj.faces = zeros(0,3);
            obj.sourcePath = "";
            obj.enabled = false;
        end

        function tf = hasMesh(obj)
            tf = not(isempty(obj.faces)) && not(isempty(obj.vertices));
        end

        function tf = isRenderable(obj)
            tf = obj.enabled && obj.hasMesh();
        end

        function R = getRotationMatrix(obj)
            %getRotationMatrix Mesh -> body rotation from the Euler offsets.
            R = eul2rotmARH(deg2rad(obj.rotOffsetEulerDeg), 'ZYX');
        end

        function M = getBodyFromMeshTransform(obj)
            %getBodyFromMeshTransform 4x4 homogeneous mesh -> body transform.
            R = obj.getRotationMatrix();
            M = [obj.scale*R, obj.transOffsetKm(:); 0 0 0 1];
        end

        function Vb = getBodyFrameVertices(obj)
            %getBodyFrameVertices Vertices in the vehicle body frame, km (N x 3).
            if(not(obj.hasMesh()))
                Vb = zeros(0,3);
                return;
            end
            M = obj.getBodyFromMeshTransform();
            Vh = [obj.vertices, ones(size(obj.vertices,1),1)] * M';
            Vb = Vh(:,1:3);
        end

        function [minXYZ, maxXYZ] = getBodyFrameBounds(obj)
            Vb = obj.getBodyFrameVertices();
            if(isempty(Vb))
                minXYZ = [0 0 0];
                maxXYZ = [0 0 0];
            else
                minXYZ = min(Vb, [], 1);
                maxXYZ = max(Vb, [], 1);
            end
        end

        function r = getBoundingRadiusKm(obj)
            Vb = obj.getBodyFrameVertices();
            if(isempty(Vb))
                r = 0;
            else
                r = max(vecnorm(Vb, 2, 2));
            end
        end

        function fitLongestDimensionTo(obj, lengthKm)
            %fitLongestDimensionTo Sets scale so the mesh's longest bounding
            %box edge (in mesh units, after the rotation offset) is lengthKm.
            arguments
                obj(1,1) LvdVehicleMeshSettings
                lengthKm(1,1) double {mustBePositive}
            end
            if(not(obj.hasMesh()))
                return;
            end
            Vr = obj.vertices * obj.getRotationMatrix()';
            extent = max(Vr, [], 1) - min(Vr, [], 1);
            longest = max(extent);
            if(longest > 0)
                obj.scale = lengthKm / longest;
            end
        end

        function str = getSummaryStr(obj)
            if(not(obj.hasMesh()))
                str = 'No mesh loaded.';
                return;
            end
            [~, name, ext] = fileparts(char(obj.sourcePath));
            [mn, mx] = obj.getBodyFrameBounds();
            str = sprintf('%s%s: %u vertices, %u faces; body-frame extent %.4g x %.4g x %.4g km', ...
                          name, ext, size(obj.vertices,1), size(obj.faces,1), mx(1)-mn(1), mx(2)-mn(2), mx(3)-mn(3));
        end

        function newObj = copy(obj)
            newObj = LvdVehicleMeshSettings();
            props = properties(obj);
            for(i=1:numel(props)) %#ok<*NO4LP>
                newObj.(props{i}) = obj.(props{i});
            end
        end
    end

    methods(Static)
        function lengthKm = defaultDisplayLengthKm(bodyRadiusKm)
            %defaultDisplayLengthKm A longest-side length that renders in a
            %scene spanning the central body: 2% of the body radius.
            %
            %   The 3-D view's depth buffer covers the whole scene (thousands
            %   of km), so a true-scale vehicle a few tens of metres long
            %   collapses into the near clipping plane and cannot be drawn;
            %   the mesh is therefore shown at a display size by default.
            arguments
                bodyRadiusKm(1,1) double
            end
            if(not(isfinite(bodyRadiusKm)) || bodyRadiusKm <= 0)
                lengthKm = 10;
            else
                lengthKm = max(1e-3, 0.02 * bodyRadiusKm);
            end
        end

        function obj = loadobj(obj)
            if(isstruct(obj))
                s = obj;
                obj = LvdVehicleMeshSettings();
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
        end
    end
end
