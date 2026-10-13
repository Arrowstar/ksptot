classdef VehiclePointDialogTest < KsptotTestCase
    %VehiclePointDialogTest Full round-trip UI tests for the vehicle point
    %editor (Phase 5: geometry).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/geometry/points/lvd_EditVehiclePointGUI_App.mlapp
    %   backing class: VehiclePoint
    %   (opens via VehiclePoint.openEditDialog).
    %
    % CTOR (verified against VehiclePoint.openEditDialog and the dialog
    % OpeningFcn: point = varargin{1}, output = varargin{2}):
    %   app = lvd_EditVehiclePointGUI_App(point, out)
    %
    % NOTE: a vehicle point carries no parameters beyond its name (it
    % always evaluates the vehicle state), so the dialog is a pure rename
    % editor: populate shows the name, save writes it back, validation
    % rejects blank/whitespace names.
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows the stored name; Save & Close writes a new name back and
    %   reports success; blank and whitespace-only names are rejected and
    %   leave the model alone; Cancel and window-X preserve the model.

    properties(Access=private)
        fixture UiwaitInterceptorFixture
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredName(testCase)
            pt = testCase.pointFixture();
            app = testCase.openDialog(pt);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(get(handles.pointNameText, 'String'), 'crew hatch');
        end

        function saveAndCloseWritesName(testCase)
            pt = testCase.pointFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(pt, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditVehiclePointGUI;

            set(handles.pointNameText, 'String', 'engine bell');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(pt.getName(), 'engine bell');
            testCase.verifyTrue(contains(pt.getListboxStr(), 'engine bell'));
        end

        function blankNameIsRejected(testCase)
            pt = testCase.pointFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(pt, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.pointNameText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank point name must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditVehiclePointGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(pt.getName(), 'crew hatch', ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function whitespaceNameIsRejected(testCase)
            pt = testCase.pointFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(pt, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.pointNameText, 'String', '    ');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A whitespace-only point name must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditVehiclePointGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(pt.getName(), 'crew hatch', ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            pt = testCase.pointFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(pt, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditVehiclePointGUI;

            set(handles.pointNameText, 'String', 'discarded');
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(pt.getName(), 'crew hatch', 'Cancel must leave the model alone.');
        end

        function windowXPreservesModel(testCase)
            pt = testCase.pointFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(pt, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditVehiclePointGUI;

            set(handles.pointNameText, 'String', 'discarded');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Window X must not report success.');
            testCase.verifyEqual(pt.getName(), 'crew hatch', 'Window X must leave the model alone.');
        end
    end

    methods(Access=private)
        function pt = pointFixture(~)
            pt = VehiclePoint('crew hatch');
        end

        function app = openDialog(testCase, pt, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditVehiclePointGUI_App(pt, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() VehiclePointDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Point')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Point')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
