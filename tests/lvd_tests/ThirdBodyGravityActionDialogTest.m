classdef ThirdBodyGravityActionDialogTest < KsptotTestCase
    %ThirdBodyGravityActionDialogTest Full round-trip UI tests for the
    %third-body gravity sources action editor (Phase 2: event actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/lvd_EditActionSetThirdBodyGravitySourcesGUI_App.mlapp
    %   backing class: SetThirdBodyGravitySourcesAction
    %   (opens via SetThirdBodyGravitySourcesAction.openEditActionUI).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows an empty selection; Save & Close writes a changed
    %   selection back; saving an empty selection clears the model; Cancel
    %   and window-X preserve the model; the listbox offers every body in
    %   the celestial-body data.  The dialog performs no validation, so
    %   there is no rejection case.  No seeding is required: bodies come
    %   from celBodyData, and the default fixture always has Kerbin/Mun.
    %
    % NOTE (bug log 2.9): populateGUI intersects the stored bodies with the
    %   sorted body list, and KSPTOT_BodyInfo's id-based eq overload makes
    %   intersect/ismember unreliable for these handles, so opening the
    %   dialog with a NON-EMPTY stored selection crashes (flakily).  The
    %   fixture below therefore starts empty (the reliable path); opening
    %   with a stored non-empty set will be covered once the dialog matches
    %   by id instead of intersecting handles.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogOpensWithEmptySelection(testCase)
            [action, lvdData] = testCase.fixture();
            testCase.assertEmpty(action.bodiesToSet, 'Fixture must start empty (see header).');
            app = testCase.openDialog(action, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEmpty(get(handles.bodiesListBox, 'Value'), ...
                'An empty stored set must open with nothing selected.');
        end

        function bodiesListBoxOffersEveryBody(testCase)
            [action, lvdData] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, sortedBodyInfo] = ma_getSortedBodyNames(lvdData.celBodyData);
            testCase.verifyEqual(numel(cellstr(get(handles.bodiesListBox, 'String'))), numel(sortedBodyInfo), ...
                'Every body in the celestial-body data must be offered.');
        end

        function saveAndCloseWritesSelectedBodies(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetThirdBodyGravitySourcesGUI;

            [~, sortedBodyInfo] = ma_getSortedBodyNames(lvdData.celBodyData);
            sortedArr = [sortedBodyInfo{:}];
            kerbinInd = find(sortedArr == testCase.kerbin, 1);
            testCase.assertNotEmpty(kerbinInd, 'Kerbin must be among the sorted bodies.');
            set(handles.bodiesListBox, 'Value', kerbinInd);

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(numel(action.bodiesToSet), 1, 'Save must write the new selection.');
            testCase.verifyEqual(action.bodiesToSet, testCase.kerbin, ...
                'Save must write Kerbin as the only source.');
        end

        function saveEmptySelectionClearsBodies(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetThirdBodyGravitySourcesGUI;

            set(handles.bodiesListBox, 'Value', []);
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Saving an empty selection must succeed.');
            testCase.verifyFalse(isvalid(fig));
            testCase.verifyEmpty(action.bodiesToSet, 'An empty selection must clear the bodies.');
        end

        function cancelPreservesModel(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetThirdBodyGravitySourcesGUI;

            [~, sortedBodyInfo] = ma_getSortedBodyNames(lvdData.celBodyData);
            set(handles.bodiesListBox, 'Value', 1:min(1, numel(sortedBodyInfo)));
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEmpty(action.bodiesToSet, ...
                'Cancel must leave the bodies alone.');
        end

        function windowClosePreservesModel(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetThirdBodyGravitySourcesGUI;

            [~, sortedBodyInfo] = ma_getSortedBodyNames(lvdData.celBodyData);
            set(handles.bodiesListBox, 'Value', 1:min(1, numel(sortedBodyInfo)));
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Closing without Save must not report success.');
            testCase.verifyEmpty(action.bodiesToSet, ...
                'Window-X must leave the bodies alone.');
        end
    end

    methods(Access=private)
        function [action, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            action = SetThirdBodyGravitySourcesAction();
        end

        function app = openDialog(testCase, action, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            lv = lvdData.launchVehicle;
            app = lvd_EditActionSetThirdBodyGravitySourcesGUI_App(action, lv, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() ThirdBodyGravityActionDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Action')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Action')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
