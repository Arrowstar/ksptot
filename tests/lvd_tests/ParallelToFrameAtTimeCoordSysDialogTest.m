classdef ParallelToFrameAtTimeCoordSysDialogTest < KsptotTestCase
    %ParallelToFrameAtTimeCoordSysDialogTest Full round-trip UI tests for
    %the parallel-to-frame-at-time coordinate system editor (Phase 5:
    %geometry).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/geometry/coordsys/lvd_EditParallelToFrameAtTimeCoordSysGUI_App.mlapp
    %   backing class: ParallelToFrameAtTimeCoordSystem
    %   (opens via ParallelToFrameAtTimeCoordSystem.openEditDialog).
    %
    % CTOR (verified against ParallelToFrameAtTimeCoordSystem.openEditDialog
    % and the dialog OpeningFcn: coordSys = varargin{1},
    % lvdData = varargin{2}, output = varargin{3}):
    %   app = lvd_EditParallelToFrameAtTimeCoordSysGUI_App(coordSys, lvdData, out)
    %
    % NOTE: the dialog figure carries the shared tag
    % handles.lvd_EditFixedInFrameVectorGUI and the epoch lives on the App
    % Designer field app.TimeText.  The date-time context menu is never
    % opened.  saveAndClose only assigns name/epoch/frame and closes: no
    % propagation or optimizer run is involved.
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows the stored name, epoch and frame type; Save & Close
    %   writes the name and epoch and keeps the frame; blank and
    %   non-numeric epochs are rejected, as is a blank name; Cancel and
    %   window-X preserve the model; the frame type dropdown offers every
    %   reference frame type.

    properties(Access=private)
        fixture UiwaitInterceptorFixture
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredNameEpochAndFrameType(testCase)
            [cs, lvdData] = testCase.coordSysFixture();
            app = testCase.openDialog(cs, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(get(handles.coordSysNameText, 'String'), 'timed cs');
            testCase.verifyEqual(str2double(app.TimeText.Value), 100, 'AbsTol', 1e-12, ...
                'The stored epoch must be shown.');
            testCase.verifyEqual(get(handles.refFrameTypeCombo, 'Value'), ...
                ReferenceFrameEnum.getIndForName('Body-Centered Inertial'));
        end

        function frameTypeComboOffersEveryReferenceFrameType(testCase)
            [cs, lvdData] = testCase.coordSysFixture();
            app = testCase.openDialog(cs, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            strs = cellstr(get(handles.refFrameTypeCombo, 'String'));
            testCase.verifyEqual(numel(strs), numel(enumeration('ReferenceFrameEnum')), ...
                'Every reference frame type must be offered.');
        end

        function saveAndCloseWritesNameAndEpochWithoutPropagating(testCase)
            [cs, lvdData] = testCase.coordSysFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(cs, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditFixedInFrameVectorGUI;

            set(handles.coordSysNameText, 'String', 'Renamed Timed');
            app.TimeText.Value = '450.5';
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(cs.getName(), 'Renamed Timed');
            testCase.verifyEqual(cs.time, 450.5, 'AbsTol', 1e-12, ...
                'The edited epoch must be written back.');
            testCase.verifyTrue(cs.frame == testCase.kerbinFrame, ...
                'Save must keep the selected frame when the type is untouched.');
        end

        function blankAndNonNumericEpochsAreRejected(testCase)
            [cs, lvdData] = testCase.coordSysFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(cs, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditFixedInFrameVectorGUI;

            app.TimeText.Value = '';
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank epoch must not save.');
            testCase.verifyTrue(isvalid(fig), 'Failed validation must leave the dialog open.');
            testCase.verifyEqual(cs.time, 100, 'Rejected input must leave the model alone.');
            testCase.closeAlerts();

            app.TimeText.Value = 'not-a-time';
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A non-numeric epoch must not save.');
            testCase.verifyTrue(isvalid(fig), 'Failed validation must leave the dialog open.');
            testCase.verifyEqual(cs.time, 100, 'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function blankNameIsRejected(testCase)
            [cs, lvdData] = testCase.coordSysFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(cs, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.coordSysNameText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank coordinate system name must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditFixedInFrameVectorGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(cs.getName(), 'timed cs', ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [cs, lvdData] = testCase.coordSysFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(cs, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditFixedInFrameVectorGUI;

            set(handles.coordSysNameText, 'String', 'discarded');
            app.TimeText.Value = '999';
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(cs.getName(), 'timed cs', 'Cancel must leave the model alone.');
            testCase.verifyEqual(cs.time, 100, 'Cancel must leave the epoch alone.');
        end

        function windowXPreservesModel(testCase)
            [cs, lvdData] = testCase.coordSysFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(cs, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditFixedInFrameVectorGUI;

            app.TimeText.Value = '999';
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Window X must not report success.');
            testCase.verifyEqual(cs.time, 100, 'Window X must leave the epoch alone.');
        end
    end

    methods(Access=private)
        function [cs, lvdData] = coordSysFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            cs = ParallelToFrameAtTimeCoordSystem(testCase.kerbinFrame, 100, 'timed cs', lvdData);
        end

        function app = openDialog(testCase, cs, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditParallelToFrameAtTimeCoordSysGUI_App(cs, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() ParallelToFrameAtTimeCoordSysDialogTest.deleteIfValid(app));
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
