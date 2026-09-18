classdef VehicleMeshSettingsTest < KsptotTestCase
    %VehicleMeshSettingsTest LvdVehicleMeshSettings (F8): the mesh -> body
    %transform (rotation offset, scale, translation), file import/reload,
    %fit-to-length, and the vehicle mesh renderer that places the mesh at
    %the interpolated vehicle position and attitude.

    methods(Test)

        %% --------------------------------------------------- transform math

        function bodyFrameVerticesApplyRotationScaleThenTranslation(testCase)
            m = LvdVehicleMeshSettings();
            m.vertices = [1 0 0; 0 1 0; 0 0 1];
            m.faces = [1 2 3];
            m.scale = 2;
            m.rotOffsetEulerDeg = [90 0 0];    % yaw +90: mesh +X -> body +Y
            m.transOffsetKm = [10 20 30];

            Vb = m.getBodyFrameVertices();
            testCase.verifyVectorEqual(Vb(1,:), [0 2 0] + [10 20 30], 1e-12, 'mesh +X maps to body +Y, scaled 2, translated');
            testCase.verifyVectorEqual(Vb(2,:), [-2 0 0] + [10 20 30], 1e-12, 'mesh +Y maps to body -X');
            testCase.verifyVectorEqual(Vb(3,:), [0 0 2] + [10 20 30], 1e-12, 'mesh +Z unchanged by yaw');
        end

        function pitchAndRollFollowIntrinsicZyxOrder(testCase)
            m = LvdVehicleMeshSettings();
            m.vertices = [1 0 0];
            m.faces = [1 1 1];

            m.rotOffsetEulerDeg = [0 90 0];    % pitch +90 about Y: +X -> -Z
            testCase.verifyVectorEqual(m.getBodyFrameVertices(), [0 0 -1], 1e-12, 'pitch');

            m.rotOffsetEulerDeg = [0 0 90];    % roll about X leaves +X alone
            testCase.verifyVectorEqual(m.getBodyFrameVertices(), [1 0 0], 1e-12, 'roll');

            m.vertices = [0 1 0];
            testCase.verifyVectorEqual(m.getBodyFrameVertices(), [0 0 1], 1e-12, 'roll +90 about X: +Y -> +Z');

            %R = Rz(yaw)*Ry(pitch)*Rx(roll) exactly as eul2rotmARH ZYX
            m.rotOffsetEulerDeg = [30 -40 55];
            Rexp = eul2rotmARH(deg2rad([30 -40 55]), 'ZYX');
            testCase.verifyEqual(m.getRotationMatrix(), Rexp, 'AbsTol', 1e-14);
        end

        function homogeneousTransformMatchesVertexTransform(testCase)
            m = LvdVehicleMeshSettings();
            rng(3);
            m.vertices = rand(20,3) - 0.5;
            m.faces = [1 2 3];
            m.scale = 0.001;
            m.rotOffsetEulerDeg = [12 -34 56];
            m.transOffsetKm = [0.1 -0.2 0.3];

            M = m.getBodyFromMeshTransform();
            testCase.verifySize(M, [4 4]);
            testCase.verifyEqual(M(4,:), [0 0 0 1]);

            Vh = (M * [m.vertices, ones(20,1)]')';
            testCase.verifyEqual(Vh(:,1:3), m.getBodyFrameVertices(), 'AbsTol', 1e-14);

            %scale and rotation blocks are separable
            testCase.verifyEqual(M(1:3,1:3)' * M(1:3,1:3), (m.scale^2)*eye(3), 'AbsTol', 1e-14);
        end

        function boundsAndRadiusReflectTheBodyFrameMesh(testCase)
            m = LvdVehicleMeshSettings();
            [m.vertices, m.faces] = ksptotWriteTestMeshInMemory();
            m.scale = 3;
            m.transOffsetKm = [1 0 0];

            [mn, mx] = m.getBodyFrameBounds();
            testCase.verifyEqual(mn, [1 0 0], 'AbsTol', 1e-12);
            testCase.verifyEqual(mx, [4 3 3], 'AbsTol', 1e-12);
            testCase.verifyEqual(m.getBoundingRadiusKm(), norm([4 3 3]), 'AbsTol', 1e-12);
        end

        function defaultDisplayLengthIsTwoPercentOfTheBodyRadius(testCase)
            testCase.verifyEqual(LvdVehicleMeshSettings.defaultDisplayLengthKm(600), 12, 'AbsTol', 1e-12, 'Kerbin: 12 km');
            testCase.verifyEqual(LvdVehicleMeshSettings.defaultDisplayLengthKm(6371), 127.42, 'AbsTol', 1e-9, 'Earth');
            testCase.verifyEqual(LvdVehicleMeshSettings.defaultDisplayLengthKm(NaN), 10, 'Unknown body falls back to 10 km');
            testCase.verifyEqual(LvdVehicleMeshSettings.defaultDisplayLengthKm(0), 10);
            testCase.verifyEqual(LvdVehicleMeshSettings.defaultDisplayLengthKm(0.01), 1e-3, 'AbsTol', 1e-15, 'Never below 1 m');
        end

        function fitLongestDimensionSetsTheScale(testCase)
            m = LvdVehicleMeshSettings();
            m.vertices = [0 0 0; 4 0 0; 0 2 0; 0 0 1];   % 4 x 2 x 1 box
            m.faces = [1 2 3];

            m.fitLongestDimensionTo(0.02);
            testCase.verifyEqual(m.scale, 0.005, 'AbsTol', 1e-15, 'longest edge (4 units) becomes 0.02 km');

            %the fit accounts for the rotation offset: after a 90 deg pitch
            %the 4-unit edge lies along Z and is still the longest
            m.rotOffsetEulerDeg = [0 90 0];
            m.fitLongestDimensionTo(1);
            testCase.verifyEqual(m.scale, 0.25, 'AbsTol', 1e-15);
            [mn, mx] = m.getBodyFrameBounds();
            testCase.verifyEqual(max(mx - mn), 1, 'AbsTol', 1e-12);
        end

        %% --------------------------------------------------------- file I/O

        function loadFromFileEmbedsTheMeshAndEnablesIt(testCase)
            path = [tempname(), '.stl'];
            cleanup = onCleanup(@() deleteIfExists(path)); %#ok<NASGU>
            ksptotWriteTestMesh('stl-binary', path);

            m = LvdVehicleMeshSettings();
            testCase.verifyFalse(m.hasMesh());
            testCase.verifyFalse(m.isRenderable());

            info = m.loadFromFile(path);
            testCase.verifyTrue(m.hasMesh());
            testCase.verifyTrue(m.enabled);
            testCase.verifyTrue(m.isRenderable());
            testCase.verifyEqual(m.sourcePath, string(path));
            testCase.verifySize(m.vertices, [8 3]);
            testCase.verifySize(m.faces, [12 3]);
            testCase.verifyEqual(info.numFaces, 12);
            testCase.verifySubstring(m.getSummaryStr(), '12 faces');

            m.enabled = false;
            testCase.verifyTrue(m.hasMesh(), 'Disabling keeps the geometry');
            testCase.verifyFalse(m.isRenderable());
        end

        function reloadFromFileRequiresASource(testCase)
            m = LvdVehicleMeshSettings();
            testCase.verifyError(@() m.reloadFromFile(), 'LvdVehicleMeshSettings:noSource');

            path = [tempname(), '.obj'];
            cleanup = onCleanup(@() deleteIfExists(path)); %#ok<NASGU>
            ksptotWriteTestMesh('obj', path);
            m.loadFromFile(path);

            %rewrite the file with a single triangle and reload
            fid = fopen(path, 'w');
            fprintf(fid, 'v 0 0 0\nv 1 0 0\nv 0 1 0\nf 1 2 3\n');
            fclose(fid);
            m.reloadFromFile();
            testCase.verifySize(m.faces, [1 3], 'Reload picks up the changed file');

            delete(path);
            testCase.verifyError(@() m.reloadFromFile(), 'LvdVehicleMeshSettings:noSource');
        end

        function clearMeshResetsEverythingGeometric(testCase)
            m = LvdVehicleMeshSettings();
            [m.vertices, m.faces] = ksptotWriteTestMeshInMemory();
            m.sourcePath = "somewhere.stl";
            m.enabled = true;
            m.scale = 5;

            m.clearMesh();
            testCase.verifyFalse(m.hasMesh());
            testCase.verifyFalse(m.enabled);
            testCase.verifyEqual(m.sourcePath, "");
            testCase.verifyEqual(m.scale, 5, 'Transform settings survive a clear');
            testCase.verifyEqual(m.getSummaryStr(), 'No mesh loaded.');
            testCase.verifyEmpty(m.getBodyFrameVertices());
        end

        function copyIsIndependentAndLoadobjAcceptsStructs(testCase)
            m = LvdVehicleMeshSettings();
            [m.vertices, m.faces] = ksptotWriteTestMeshInMemory();
            m.faceColor = [1 0 0];
            c = m.copy();
            testCase.verifyNotSameHandle(c, m);
            testCase.verifyEqual(c.faceColor, [1 0 0]);
            c.faceColor = [0 1 0];
            testCase.verifyEqual(m.faceColor, [1 0 0]);

            s = struct('enabled', true, 'scale', 2, 'unknownField', 7);
            fromStruct = LvdVehicleMeshSettings.loadobj(s);
            testCase.verifyClass(fromStruct, 'LvdVehicleMeshSettings');
            testCase.verifyEqual(fromStruct.scale, 2);
            testCase.verifyTrue(fromStruct.enabled);
            testCase.verifyEqual(fromStruct.faceAlpha, 1, 'Missing fields keep their defaults');
        end

        function invalidValuesAreRejected(testCase)
            m = LvdVehicleMeshSettings();
            testCase.verifyError(@() set(m, 'scale', 0), ?MException);
            testCase.verifyError(@() set(m, 'faceAlpha', 1.5), ?MException);
            testCase.verifyError(@() m.fitLongestDimensionTo(-1), ?MException);
        end

        %% --------------------------------------------------------- renderer

        function rendererPlacesTheMeshAtTheInterpolatedPose(testCase)
            hFig = figure('Visible', 'off');
            cleanup = onCleanup(@() delete(hFig)); %#ok<NASGU>
            hAx = axes(hFig);

            [m, posVel, att, R] = testCase.rendererFixture();
            data = LaunchVehicleViewProfileVehicleMeshData(posVel, att, m);

            data.plotVehicleMeshAtTime(25, hAx);
            patches = findobj(hAx, 'Tag', 'LvdVehicleMesh');
            testCase.verifyNumElements(patches, 1, 'One patch per trajectory segment');
            testCase.verifyEqual(patches.Vertices, m.getBodyFrameVertices(), 'AbsTol', 1e-12, 'Patch holds body-frame vertices');
            testCase.verifyEqual(patches.Faces, m.faces);

            xform = patches.Parent;
            testCase.verifyClass(xform, 'matlab.graphics.primitive.Transform');
            testCase.verifyEqual(xform.Tag, 'LvdVehicleMeshXform');
            M = xform.Matrix;
            %straight line from [100 0 0] at t=0 to [200 0 0] at t=100
            testCase.verifyVectorEqual(M(1:3,4), [125; 0; 0], 1e-9, 'Translation is the interpolated position');
            testCase.verifyEqual(M(1:3,1:3), R, 'AbsTol', 1e-9, 'Rotation block is the body->view DCM');
            testCase.verifyEqual(M(1:3,1:3)'*M(1:3,1:3), eye(3), 'AbsTol', 1e-12);

            %a second call updates in place
            data.plotVehicleMeshAtTime(75, hAx);
            testCase.verifyNumElements(findobj(hAx, 'Tag', 'LvdVehicleMesh'), 1, 'No new patch on update');
            testCase.verifyVectorEqual(xform.Matrix(1:3,4), [175; 0; 0], 1e-9);
            testCase.verifyEqual(xform.Visible, matlab.lang.OnOffSwitchState.on);
        end

        function rendererHidesOutOfRangeAndDisabledMeshes(testCase)
            hFig = figure('Visible', 'off');
            cleanup = onCleanup(@() delete(hFig)); %#ok<NASGU>
            hAx = axes(hFig);

            [m, posVel, att] = testCase.rendererFixture();
            data = LaunchVehicleViewProfileVehicleMeshData(posVel, att, m);

            data.plotVehicleMeshAtTime(50, hAx);
            xform = findobj(hAx, 'Tag', 'LvdVehicleMeshXform');
            testCase.assertNumElements(xform, 1);

            data.plotVehicleMeshAtTime(1e6, hAx);   % beyond the trajectory
            testCase.verifyEqual(xform.Visible, matlab.lang.OnOffSwitchState.off, 'Out-of-range time hides the mesh');

            data.plotVehicleMeshAtTime(50, hAx);
            testCase.verifyEqual(xform.Visible, matlab.lang.OnOffSwitchState.on);

            m.enabled = false;
            data.plotVehicleMeshAtTime(50, hAx);
            testCase.verifyEqual(xform.Visible, matlab.lang.OnOffSwitchState.off, 'Disabling hides the mesh');

            %a fresh renderer with a disabled mesh never creates graphics
            hAx2 = axes(hFig);
            data2 = LaunchVehicleViewProfileVehicleMeshData(posVel, att, m);
            data2.plotVehicleMeshAtTime(50, hAx2);
            testCase.verifyEmpty(findobj(hAx2, 'Tag', 'LvdVehicleMesh'));
        end

        function rendererRefreshAppearancePushesNewSettings(testCase)
            hFig = figure('Visible', 'off');
            cleanup = onCleanup(@() delete(hFig)); %#ok<NASGU>
            hAx = axes(hFig);

            [m, posVel, att] = testCase.rendererFixture();
            data = LaunchVehicleViewProfileVehicleMeshData(posVel, att, m);
            data.plotVehicleMeshAtTime(50, hAx);
            p = findobj(hAx, 'Tag', 'LvdVehicleMesh');

            m.faceColor = [1 0 0];
            m.faceAlpha = 0.5;
            m.showEdges = true;
            m.edgeColor = [0 0 1];
            m.scale = 10;
            data.refreshAppearance();

            testCase.verifyEqual(p.FaceColor, [1 0 0]);
            testCase.verifyEqual(p.FaceAlpha, 0.5);
            testCase.verifyEqual(p.EdgeColor, [0 0 1]);
            testCase.verifyEqual(p.Vertices, m.getBodyFrameVertices(), 'AbsTol', 1e-12, 'New scale is pushed to the vertices');

            m.showEdges = false;
            data.refreshAppearance();
            testCase.verifyEqual(p.EdgeColor, 'none');
        end
    end

    methods(Access = private)
        function [m, posVel, att, R] = rendererFixture(testCase)
            m = LvdVehicleMeshSettings();
            [m.vertices, m.faces] = ksptotWriteTestMeshInMemory();
            m.scale = 0.01;
            m.enabled = true;

            times = [0 50 100];
            rVects = [100 0 0; 150 0 0; 200 0 0];
            vVects = ones(3,3);
            posVel = LaunchVehicleViewPosVelInterp(testCase.kerbinFrame);
            posVel.addData(times, rVects, vVects);

            R = eul2rotmARH(deg2rad([20 -30 40]), 'ZYX');
            att = LaunchVehicleViewProfileAttitudeData();
            att.addData(times, repmat(R, 1, 1, 3));
        end
    end
end

function [V, F] = ksptotWriteTestMeshInMemory()
    %the cube geometry without touching the disk
    tmp = [tempname(), '.obj'];
    [V, F] = ksptotWriteTestMesh('obj-tri', tmp);
    if(isfile(tmp))
        delete(tmp);
    end
end

function deleteIfExists(filePath)
    if(isfile(filePath))
        delete(filePath);
    end
end
