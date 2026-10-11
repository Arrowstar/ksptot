classdef KinematicStateActionDialogTest < KsptotTestCase
    %KinematicStateActionDialogTest Full round-trip UI tests for the
    %set-kinematic-state action editor (Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/lvd_EditActionSetKinematicStateGUI_App.mlapp
    %   backing class: SetKinematicStateAction
    %   (opens via SetKinematicStateAction.openEditActionUI).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The dialog is opened
    %   directly (not via openEditActionUI); the fixture attaches the
    %   action to event 1, because populateGUI reads
    %   action.event.getEventNum() to trim the inherit-event lists.  Only
    %   the orbit/epoch/inherit subset is covered here; the stage, tank,
    %   engine and power tabs are left to their own dialogs.  No
    %   propagation or optimization is run: Save only rebuilds the
    %   in-memory orbit model and inherit flags.
    %
    % COVERED
    %   Open shows the stored epoch, element vector, element-set type,
    %   frame type and inherit flags; Save & Close writes a new epoch
    %   back; Save & Close writes the inherit-time/posvel flags back; a
    %   blank epoch is rejected and leaves the model alone; Cancel
    %   preserves the model; the element-set dropdown offers the full
    %   ElementSetEnum list.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredEpochAndElements(testCase)
            [action, lvdData] = testCase.fixture(); %#ok<ASGLU>
            app = testCase.openDialog(action, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(str2double(get(handles.utText, 'String')), 123.4, 'AbsTol', 1e-9);

            elemVector = action.orbitModel.getElementVector();
            shown = [str2double(get(handles.orbit1Text, 'String')), ...
                     str2double(get(handles.orbit2Text, 'String')), ...
                     str2double(get(handles.orbit3Text, 'String')), ...
                     str2double(get(handles.orbit4Text, 'String')), ...
                     str2double(get(handles.orbit5Text, 'String')), ...
                     str2double(get(handles.orbit6Text, 'String'))];
            testCase.verifyEqual(shown, elemVector, 'RelTol', 1e-9);

            expElemInd = ElementSetEnum.getIndForName(action.orbitModel.typeEnum.name);
            testCase.verifyEqual(get(handles.elementSetCombo, 'Value'), expElemInd);
            expFrameInd = ReferenceFrameEnum.getIndForName(action.orbitModel.frame.typeEnum.name);
            testCase.verifyEqual(get(handles.refFrameTypeCombo, 'Value'), expFrameInd);

            testCase.verifyFalse(logical(handles.inheritTimeCheckbox.Value));
            testCase.verifyFalse(logical(handles.inheritStateCheckbox.Value));
        end

        function elementSetComboOffersEveryElementSet(testCase)
            [action, lvdData] = testCase.fixture(); %#ok<ASGLU>
            app = testCase.openDialog(action, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(numel(cellstr(get(handles.elementSetCombo, 'String'))), ...
                numel(ElementSetEnum.getListBoxStr()), ...
                'Every element set type must be offered.');
        end

        function saveAndCloseWritesEpoch(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetKinematicStateGUI;

            set(handles.utText, 'String', '200');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyTrue(isa(action.orbitModel, 'KeplerianElementSet'), ...
                'The element-set type must survive the round trip.');
            testCase.verifyEqual(action.orbitModel.time, 200, 'AbsTol', 1e-12);
        end

        function saveAndCloseWritesInheritFlags(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetKinematicStateGUI;

            set(handles.inheritTimeCheckbox, 'Value', 1);
            set(handles.inheritStateCheckbox, 'Value', 1);
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyTrue(action.inheritTime, 'The inherit-time flag must be written back.');
            testCase.verifyTrue(action.inheritPosVel, 'The inherit-posvel flag must be written back.');
            testCase.verifyEqual(action.inheritTimeFrom, InheritStateEnum.InheritFromLastState);
        end

        function blankEpochIsRejected(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.utText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank epoch must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditActionSetKinematicStateGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(action.orbitModel.time, 123.4, 'AbsTol', 1e-12, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetKinematicStateGUI;

            set(handles.utText, 'String', '9999');
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(action.orbitModel.time, 123.4, 'AbsTol', 1e-12, ...
                'Cancel must leave the model alone.');
        end
    end

    methods(Access=private)
        function [action, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            bodyInfo = lvdData.getDefaultInitialBodyInfo(lvdData.celBodyData);
            frame = bodyInfo.getBodyCenteredInertialFrame();

            sma = bodyInfo.radius + 500;
            orbitModel = KeplerianElementSet(123.4, sma, 0.1, 0.3, 0.6, 1.1, 2.0, frame);

            action = SetKinematicStateAction(lvdData.stateLog, orbitModel);
            action.event = lvdData.script.getEventForInd(1);
        end

        function app = openDialog(testCase, action, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditActionSetKinematicStateGUI_App(action, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() KinematicStateActionDialogTest.deleteIfValid(app));
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
