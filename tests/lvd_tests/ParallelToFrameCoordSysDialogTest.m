classdef ParallelToFrameCoordSysDialogTest < KsptotTestCase
    %ParallelToFrameCoordSysDialogTest Full round-trip UI tests for the
    %parallel-to-frame coordinate system editor (Phase 5: geometry).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/geometry/coordsys/lvd_EditParallelToFrameCoordSysGUI_App.mlapp
    %   backing class: ParallelToFrameCoordSystem
    %   (opens via ParallelToFrameCoordSystem.openEditDialog).
    %
    % CTOR (verified against ParallelToFrameCoordSystem.openEditDialog and
    % the dialog OpeningFcn: coordSys = varargin{1}, lvdData = varargin{2},
    % output = varargin{3}):
    %   app = lvd_EditParallelToFrameCoordSysGUI_App(coordSys, lvdData, out)
    %
    % NOTE: the dialog figure carries the shared tag
    % handles.lvd_EditFixedInFrameVectorGUI (not a parallel-specific tag).
    % The frame-options button opens a nested frame editor and the frame
    % type combo swaps the working frame through its own callback; neither
    % is driven here (no propagation or nested dialogs).  Save therefore
    % writes the name and keeps the selected frame.
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows the stored name, the current frame type and the current
    %   frame in the options tooltip; Save & Close writes the name and
    %   keeps the frame; a blank name is rejected and leaves the model
    %   alone; Cancel and window-X preserve the model; the frame type
    %   dropdown offers every reference frame type.

    properties(Access=private)
        fixture UiwaitInterceptorFixture
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredNameAndFrameType(testCase)
            [cs, lvdData] = testCase.coordSysFixture();
            app = testCase.openDialog(cs, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(get(handles.coordSysNameText, 'String'), 'parallel cs');
            testCase.verifyEqual(get(handles.refFrameTypeCombo, 'Value'), ...
                ReferenceFrameEnum.getIndForName('Body-Centered Inertial'), ...
                'The Kerbin inertial frame must be shown as selected.');
            testCase.verifyTrue(contains(get(handles.setFrameOptionsButton, 'TooltipString'), ...
                cs.frame.getNameStr()), 'The options tooltip must name the current frame.');
        end

        function frameTypeComboOffersEveryReferenceFrameType(testCase)
            [cs, lvdData] = testCase.coordSysFixture();
            app = testCase.openDialog(cs, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            strs = cellstr(get(handles.refFrameTypeCombo, 'String'));
            testCase.verifyEqual(numel(strs), numel(enumeration('ReferenceFrameEnum')), ...
                'Every reference frame type must be offered.');
            testCase.verifyTrue(any(strcmp(strs, 'Body-Centered Inertial')));
            testCase.verifyTrue(any(strcmp(strs, 'Body-Fixed Rotating')));
        end

        function saveAndCloseWritesNameAndKeepsFrame(testCase)
            [cs, lvdData] = testCase.coordSysFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(cs, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditFixedInFrameVectorGUI;

            set(handles.coordSysNameText, 'String', 'Renamed Parallel');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(cs.getName(), 'Renamed Parallel');
            testCase.verifyTrue(cs.frame == testCase.kerbinFrame, ...
                'Save must keep the selected frame when the type is untouched.');
        end

        function blankNameIsRejected(testCase)
            [cs, lvdData] = testCase.coordSysFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(cs, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.coordSysNameText, 'String', '   ');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank coordinate system name must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditFixedInFrameVectorGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(cs.getName(), 'parallel cs', ...
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
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(cs.getName(), 'parallel cs', 'Cancel must leave the model alone.');
        end

        function windowXPreservesModel(testCase)
            [cs, lvdData] = testCase.coordSysFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(cs, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditFixedInFrameVectorGUI;

            set(handles.coordSysNameText, 'String', 'discarded');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Window X must not report success.');
            testCase.verifyEqual(cs.getName(), 'parallel cs', 'Window X must leave the model alone.');
        end
    end

    methods(Access=private)
        function [cs, lvdData] = coordSysFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            cs = ParallelToFrameCoordSystem(testCase.kerbinFrame, 'parallel cs', lvdData);
        end

        function app = openDialog(testCase, cs, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditParallelToFrameCoordSysGUI_App(cs, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() ParallelToFrameCoordSysDialogTest.deleteIfValid(app));
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
