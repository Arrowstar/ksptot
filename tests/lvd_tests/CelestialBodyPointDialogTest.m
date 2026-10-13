classdef CelestialBodyPointDialogTest < KsptotTestCase
    %CelestialBodyPointDialogTest Full round-trip UI tests for the
    %celestial-body point editor (Phase 5: geometry).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/geometry/points/lvd_EditCelestialBodyPointGUI_App.mlapp
    %   backing class: CelestialBodyPoint
    %   (opens via CelestialBodyPoint.openEditDialog).
    %
    % CTOR (verified against CelestialBodyPoint.openEditDialog and the
    % dialog OpeningFcn: point = varargin{1}, output = varargin{2}; there
    % is deliberately no lvdData argument, the body catalog comes from
    % point.bodyInfo.celBodyData):
    %   app = lvd_EditCelestialBodyPointGUI_App(point, out)
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows the stored name and the stored body; Save & Close writes
    %   the name and the body selection back; a blank name is rejected and
    %   leaves the model alone; Cancel and window-X preserve the model; the
    %   body dropdown offers every body in the catalog.

    properties(Access=private)
        fixture UiwaitInterceptorFixture
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredNameAndBody(testCase)
            pt = testCase.pointFixture();
            pt.setName('home point');
            app = testCase.openDialog(pt);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, sortedBodyInfo] = ma_getSortedBodyNames(testCase.celBodyData);
            ind = find(pt.bodyInfo == [sortedBodyInfo{:}], 1, 'first');

            testCase.verifyEqual(get(handles.pointNameText, 'String'), 'home point');
            testCase.verifyEqual(get(handles.celestialBodyCombo, 'Value'), ind, ...
                'The stored body must be selected.');
        end

        function bodyComboOffersEveryBody(testCase)
            pt = testCase.pointFixture();
            app = testCase.openDialog(pt);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, sortedBodyInfo] = ma_getSortedBodyNames(testCase.celBodyData);
            testCase.verifyEqual(numel(cellstr(get(handles.celestialBodyCombo, 'String'))), ...
                numel(sortedBodyInfo), 'Every catalog body must be offered.');
            testCase.verifyGreaterThanOrEqual(numel(sortedBodyInfo), 2, ...
                'The test catalog must hold at least Kerbin and the Mun.');
        end

        function saveAndCloseWritesNameAndBody(testCase)
            pt = testCase.pointFixture();
            [~, sortedBodyInfo] = ma_getSortedBodyNames(testCase.celBodyData);
            indMun = find(testCase.mun == [sortedBodyInfo{:}], 1, 'first');
            testCase.assertNotEmpty(indMun, 'The Mun must be in the test body catalog.');

            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(pt, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditCelestialBodyPointGUI;

            set(handles.pointNameText, 'String', 'mun point');
            set(handles.celestialBodyCombo, 'Value', indMun);
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(pt.getName(), 'mun point');
            testCase.verifyTrue(pt.bodyInfo == testCase.mun, ...
                'The selected body must be written back.');
            testCase.verifyTrue(contains(pt.getListboxStr(), testCase.mun.name));
        end

        function blankNameIsRejected(testCase)
            pt = testCase.pointFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(pt, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.pointNameText, 'String', '  ');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank point name must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditCelestialBodyPointGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(pt.getName(), 'origin point', ...
                'Rejected input must leave the model alone.');
            testCase.verifyTrue(pt.bodyInfo == testCase.kerbin, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            pt = testCase.pointFixture();
            [~, sortedBodyInfo] = ma_getSortedBodyNames(testCase.celBodyData);
            indMun = find(testCase.mun == [sortedBodyInfo{:}], 1, 'first');

            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(pt, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditCelestialBodyPointGUI;

            set(handles.pointNameText, 'String', 'discarded');
            set(handles.celestialBodyCombo, 'Value', indMun);
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(pt.getName(), 'origin point', 'Cancel must leave the model alone.');
            testCase.verifyTrue(pt.bodyInfo == testCase.kerbin, 'Cancel must leave the model alone.');
        end

        function windowXPreservesModel(testCase)
            pt = testCase.pointFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(pt, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditCelestialBodyPointGUI;

            set(handles.pointNameText, 'String', 'discarded');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Window X must not report success.');
            testCase.verifyEqual(pt.getName(), 'origin point', 'Window X must leave the model alone.');
        end
    end

    methods(Access=private)
        function pt = pointFixture(testCase)
            pt = CelestialBodyPoint(testCase.kerbin, 'origin point');
        end

        function app = openDialog(testCase, pt, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditCelestialBodyPointGUI_App(pt, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() CelestialBodyPointDialogTest.deleteIfValid(app));
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
