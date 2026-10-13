classdef AlignedConstrainedCoordSysDialogTest < KsptotTestCase
    %AlignedConstrainedCoordSysDialogTest Full round-trip UI tests for the
    %aligned/constrained coordinate system editor (Phase 5: geometry).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/geometry/coordsys/lvd_EditAlignedConstrainedCoordSysGUI_App.mlapp
    %   backing class: AlignedConstrainedCoordSystem
    %   (opens via AlignedConstrainedCoordSystem.openEditDialog).
    %
    % CTOR (verified against AlignedConstrainedCoordSystem.openEditDialog
    % and the dialog OpeningFcn: coordsys = varargin{1},
    % lvdData = varargin{2}, output = varargin{3}):
    %   app = lvd_EditAlignedConstrainedCoordSysGUI_App(coordsys, lvdData, out)
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  GUIDE controls are read
    %   through the handles struct from convertToGUIDECallbackArguments.
    %
    % COVERED
    %   Open shows the stored name/aligned-vector/constrained-vector/axes;
    %   Save & Close writes the name, both vectors and both axes back; a
    %   shared aligned/constrained vector, identical axes and opposite
    %   (same-base-axis) axes are rejected and leave the model alone, as is
    %   a blank name; Cancel and window-X preserve the model; both vector
    %   dropdowns mirror the geometric vector set.

    properties(Access=private)
        fixture UiwaitInterceptorFixture
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredVectorsAxesAndName(testCase)
            [cs, lvdData, v1, v2] = testCase.coordSysFixture();
            cs.setName('My Axes');
            i1 = lvdData.geometry.vectors.getIndsForVectors(v1);
            i2 = lvdData.geometry.vectors.getIndsForVectors(v2);

            app = testCase.openDialog(cs, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(get(handles.coordSysNameText, 'String'), 'My Axes');
            testCase.verifyEqual(get(handles.aVectorCombo, 'Value'), i1);
            testCase.verifyEqual(get(handles.cVectorCombo, 'Value'), i2);
            testCase.verifyEqual(get(handles.alignedVectAxisCombo, 'Value'), ...
                AlignedConstrainedCoordSysAxesEnum.getIndForName('+X'));
            testCase.verifyEqual(get(handles.constrainedVectAxisCombo, 'Value'), ...
                AlignedConstrainedCoordSysAxesEnum.getIndForName('+Z'));
        end

        function vectorCombosOfferEveryGeometricVector(testCase)
            [cs, lvdData, ~, ~] = testCase.coordSysFixture();
            app = testCase.openDialog(cs, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            n = lvdData.geometry.vectors.getNumVectors();
            testCase.verifyGreaterThanOrEqual(n, 2, 'The fixture must offer at least two vectors.');
            testCase.verifyEqual(numel(cellstr(get(handles.aVectorCombo, 'String'))), n, ...
                'Every geometric vector must be offered as the aligned vector.');
            testCase.verifyEqual(numel(cellstr(get(handles.cVectorCombo, 'String'))), n, ...
                'Every geometric vector must be offered as the constrained vector.');
            testCase.verifyEqual(numel(cellstr(get(handles.alignedVectAxisCombo, 'String'))), 6, ...
                'All six aligned/constrained axes must be offered.');
        end

        function saveAndCloseWritesVectorsAxesAndName(testCase)
            [cs, lvdData, v1, v2] = testCase.coordSysFixture();
            i1 = lvdData.geometry.vectors.getIndsForVectors(v1);
            i2 = lvdData.geometry.vectors.getIndsForVectors(v2);
            indY = AlignedConstrainedCoordSysAxesEnum.getIndForName('+Y');
            indNegZ = AlignedConstrainedCoordSysAxesEnum.getIndForName('-Z');

            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(cs, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditAlignedConstrainedCoordSysGUI;

            set(handles.coordSysNameText, 'String', 'Renamed Sys');
            set(handles.aVectorCombo, 'Value', i2);
            set(handles.cVectorCombo, 'Value', i1);
            set(handles.alignedVectAxisCombo, 'Value', indY);
            set(handles.constrainedVectAxisCombo, 'Value', indNegZ);
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(cs.getName(), 'Renamed Sys');
            testCase.verifyTrue(cs.aVector == v2, 'The aligned vector selection must be written back.');
            testCase.verifyTrue(cs.cVector == v1, 'The constrained vector selection must be written back.');
            testCase.verifyEqual(cs.aVectorAxis, AlignedConstrainedCoordSysAxesEnum.PosY);
            testCase.verifyEqual(cs.cVectorAxis, AlignedConstrainedCoordSysAxesEnum.NegZ);
        end

        function sharedVectorIsRejected(testCase)
            [cs, lvdData, v1, ~] = testCase.coordSysFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(cs, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.cVectorCombo, 'Value', get(handles.aVectorCombo, 'Value'));
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A shared aligned/constrained vector must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditAlignedConstrainedCoordSysGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyTrue(cs.aVector == v1, 'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function sameAndOppositeAxesAreRejected(testCase)
            [cs, lvdData, ~, ~] = testCase.coordSysFixture();
            indNegX = AlignedConstrainedCoordSysAxesEnum.getIndForName('-X');
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(cs, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditAlignedConstrainedCoordSysGUI;

            % Identical axes (aligned +X, constrained +X).
            set(handles.constrainedVectAxisCombo, 'Value', get(handles.alignedVectAxisCombo, 'Value'));
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'Identical axes must not save.');
            testCase.verifyTrue(isvalid(fig), 'Failed validation must leave the dialog open.');
            testCase.verifyEqual(cs.cVectorAxis, AlignedConstrainedCoordSysAxesEnum.PosZ, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();

            % Opposite axes share a base axis (aligned +X, constrained -X).
            set(handles.constrainedVectAxisCombo, 'Value', indNegX);
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'Opposite axes must not save.');
            testCase.verifyTrue(isvalid(fig), 'Failed validation must leave the dialog open.');
            testCase.verifyEqual(cs.cVectorAxis, AlignedConstrainedCoordSysAxesEnum.PosZ, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function blankNameIsRejected(testCase)
            [cs, lvdData, ~, ~] = testCase.coordSysFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(cs, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.coordSysNameText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank coordinate system name must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditAlignedConstrainedCoordSysGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(cs.getName(), 'test coord sys', ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [cs, lvdData, v1, v2] = testCase.coordSysFixture();
            i2 = lvdData.geometry.vectors.getIndsForVectors(v2);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(cs, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditAlignedConstrainedCoordSysGUI;

            set(handles.coordSysNameText, 'String', 'discarded');
            set(handles.aVectorCombo, 'Value', i2);
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(cs.getName(), 'test coord sys', 'Cancel must leave the model alone.');
            testCase.verifyTrue(cs.aVector == v1, 'Cancel must leave the model alone.');
        end

        function windowXPreservesModel(testCase)
            [cs, lvdData, ~, ~] = testCase.coordSysFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(cs, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditAlignedConstrainedCoordSysGUI;

            set(handles.coordSysNameText, 'String', 'discarded');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Window X must not report success.');
            testCase.verifyEqual(cs.getName(), 'test coord sys', 'Window X must leave the model alone.');
        end
    end

    methods(Access=private)
        function [cs, lvdData, v1, v2] = coordSysFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            frame = testCase.kerbinFrame;
            v1 = FixedVectorInFrame([1; 0; 0], frame, 'align vector', lvdData);
            v2 = FixedVectorInFrame([0; 1; 0], frame, 'constrain vector', lvdData);
            lvdData.geometry.vectors.addVector(v1);
            lvdData.geometry.vectors.addVector(v2);
            cs = AlignedConstrainedCoordSystem(v1, AlignedConstrainedCoordSysAxesEnum.PosX, ...
                v2, AlignedConstrainedCoordSysAxesEnum.PosZ, 'test coord sys', lvdData);
        end

        function app = openDialog(testCase, cs, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditAlignedConstrainedCoordSysGUI_App(cs, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() AlignedConstrainedCoordSysDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Coordinate System')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
            drawnow;
        end
    end

    methods(Static, Access=private)
        function deleteIfValid(app)
            if ~isempty(app) && isvalid(app)
                delete(app);
            end
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Coordinate System')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
