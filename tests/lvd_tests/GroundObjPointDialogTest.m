classdef GroundObjPointDialogTest < KsptotTestCase
    %GroundObjPointDialogTest Full round-trip UI tests for the ground
    %object point editor (Phase 5: geometry).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/geometry/points/lvd_EditGroundObjPointGUI_App.mlapp
    %   backing class: GroundObjectPoint
    %   (opens via GroundObjectPoint.openEditDialog).
    %
    % CTOR (verified against GroundObjectPoint.openEditDialog and the
    % dialog OpeningFcn: point = varargin{1}, output = varargin{2}; there
    % is deliberately no lvdData argument, the ground object set is reached
    % through point.groundObj.groundObjs):
    %   app = lvd_EditGroundObjPointGUI_App(point, out)
    %
    % FIXTURE (mirrors GroundObjConstraintDialogTest and
    % CaseMatrixPluginGroundObjTest): default LvdData ships one ground
    % object (KSC); the set is topped up only if it is empty, and the point
    % under test always wraps a set member so its back-reference resolves.
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows the stored name and the stored ground object; Save &
    %   Close writes the name and the ground object selection back; a blank
    %   name is rejected and leaves the model alone; Cancel and window-X
    %   preserve the model; the dropdown mirrors the ground object set.

    properties(Access=private)
        fixture UiwaitInterceptorFixture
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredNameAndGroundObj(testCase)
            [pt, lvdData] = testCase.pointFixture();
            app = testCase.openDialog(pt);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(get(handles.pointNameText, 'String'), 'pad camera');
            testCase.verifyEqual(get(handles.groundObjCombo, 'Value'), 1, ...
                'The stored ground object must be selected.');
            testCase.verifyEqual(numel(cellstr(get(handles.groundObjCombo, 'String'))), ...
                lvdData.groundObjs.getNumGroundObj());
        end

        function groundObjComboOffersEveryGroundObj(testCase)
            [pt, lvdData] = testCase.pointFixture();
            second = LaunchVehicleGroundObject.getDefaultObj(testCase.celBodyData);
            second.name = 'Downrange Station';
            lvdData.groundObjs.addGroundObj(second);

            app = testCase.openDialog(pt);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(numel(cellstr(get(handles.groundObjCombo, 'String'))), 2, ...
                'Every ground object must be offered.');
        end

        function saveAndCloseWritesNameAndGroundObj(testCase)
            [pt, lvdData] = testCase.pointFixture();
            second = LaunchVehicleGroundObject.getDefaultObj(testCase.celBodyData);
            second.name = 'Downrange Station';
            lvdData.groundObjs.addGroundObj(second);

            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(pt, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditGroundObjPointGUI;

            set(handles.pointNameText, 'String', 'renamed point');
            set(handles.groundObjCombo, 'Value', 2);
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(pt.getName(), 'renamed point');
            testCase.verifyEqual(lvdData.groundObjs.getIndsForGroundObjs(pt.groundObj), 2, ...
                'The selected ground object must be written back.');
            testCase.verifyTrue(contains(pt.getListboxStr(), 'Downrange Station'));
        end

        function blankNameIsRejected(testCase)
            [pt, lvdData] = testCase.pointFixture();
            first = lvdData.groundObjs.getGroundObjAtInd(1);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(pt, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.pointNameText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank point name must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditGroundObjPointGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(pt.getName(), 'pad camera', ...
                'Rejected input must leave the model alone.');
            testCase.verifyTrue(pt.groundObj == first, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [pt, lvdData] = testCase.pointFixture();
            second = LaunchVehicleGroundObject.getDefaultObj(testCase.celBodyData);
            second.name = 'Downrange Station';
            lvdData.groundObjs.addGroundObj(second);

            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(pt, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditGroundObjPointGUI;

            set(handles.pointNameText, 'String', 'discarded');
            set(handles.groundObjCombo, 'Value', 2);
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(pt.getName(), 'pad camera', 'Cancel must leave the model alone.');
            testCase.verifyEqual(lvdData.groundObjs.getIndsForGroundObjs(pt.groundObj), 1, ...
                'Cancel must leave the model alone.');
        end

        function windowXPreservesModel(testCase)
            [pt, ~] = testCase.pointFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(pt, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditGroundObjPointGUI;

            set(handles.pointNameText, 'String', 'discarded');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Window X must not report success.');
            testCase.verifyEqual(pt.getName(), 'pad camera', 'Window X must leave the model alone.');
        end
    end

    methods(Access=private)
        function [pt, lvdData] = pointFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            % DefaultLvdData ships one ground object (KSC); top up only if
            % some other test run left the template empty.
            if lvdData.groundObjs.getNumGroundObj() < 1
                lvdData.groundObjs.addGroundObj( ...
                    LaunchVehicleGroundObject.getDefaultObj(testCase.celBodyData));
            end
            pt = GroundObjectPoint(lvdData.groundObjs.getGroundObjAtInd(1), 'pad camera');
        end

        function app = openDialog(testCase, pt, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditGroundObjPointGUI_App(pt, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() GroundObjPointDialogTest.deleteIfValid(app));
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
