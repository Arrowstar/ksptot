classdef ConditionalActionDialogTest < KsptotTestCase
    %ConditionalActionDialogTest Full round-trip UI tests for the
    %conditional-action container editor (Phase 2: event actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/lvd_EditConditionalActionGUI_App.mlapp
    %   backing class: ConditionalAction
    %   (opens via ConditionalAction.openEditActionUI).  This is the
    %   container dialog; the per-conditional editor
    %   (lvd_EditActionConditionalGUI_App) already has partial
    %   PatchedMlappDialogs coverage.
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  This modern dialog exposes its
    %   controls as app properties, so tests drive the listboxes and
    %   Add/Remove buttons directly.  The dialog has no Cancel button
    %   (window-X is the preserve path); Save merely reports success
    %   because branch membership is edited in place by the Add/Remove
    %   buttons.  The Add*Action buttons open the nested action picker and
    %   are deliberately never pressed here (they would block on their own
    %   uiwait); add/remove of branch actions is covered through the
    %   Remove buttons, and conditional add/remove through the
    %   Add/RemoveElseIfConditional buttons, which need no nested dialog.
    %
    % COVERED
    %   Open shows the IF/ELSE branch actions and the IF conditional text;
    %   adding an ELSE IF conditional adds a listbox row and a model entry;
    %   removing it drops both; removing an IF action drops its row and its
    %   model entry; Save reports success and closes; window-X preserves
    %   the model.  No validation or propagation is involved.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredBranches(testCase)
            [action, lvdData] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);

            testCase.verifyEqual(numel(app.IfActionsListBox.Items), 1, ...
                'The seeded IF action must be listed.');
            testCase.verifyEqual(string(app.IfActionsListBox.Items(1)), string(action.ifActions(1).getName()), ...
                'The IF row must name the stored action.');
            testCase.verifyEqual(numel(app.ElseActionsListBox.Items), 1, ...
                'The seeded ELSE action must be listed.');
            testCase.verifyEqual(string(app.ElseActionsListBox.Items(1)), string(action.elseActions(1).getName()), ...
                'The ELSE row must name the stored action.');
            testCase.verifyEqual(string(app.IfConditionalTextArea.Value), "TRUE", ...
                'The AlwaysTrue IF conditional must be shown.');
            testCase.verifyEqual(numel(app.ElseIfConditionsListbox.Items), 0, ...
                'The fixture starts with no ELSE IF conditions.');
        end

        function addElseIfConditionalAddsRow(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);

            n0 = numel(app.ElseIfConditionsListbox.Items);
            testCase.pushButton(app.AddElseIfConditionalButton);

            testCase.verifyEqual(numel(action.elseifConditions), 1, ...
                'Add must append a condition to the model.');
            testCase.verifyEqual(numel(app.ElseIfConditionsListbox.Items), n0 + 1, ...
                'Add must append a listbox row.');
            testCase.verifyTrue(app.ElseIfConditionsListbox.Value == action.elseifConditions(1), ...
                'The new condition must be selected.');
        end

        function removeElseIfConditionalRemovesRow(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);

            testCase.pushButton(app.AddElseIfConditionalButton);
            testCase.assertEqual(numel(action.elseifConditions), 1, 'Add must stage one condition.');
            testCase.pushButton(app.RemoveElseIfConditionalButton);

            testCase.verifyEmpty(action.elseifConditions, 'Remove must drop the condition from the model.');
            testCase.verifyEqual(numel(app.ElseIfConditionsListbox.Items), 0, ...
                'Remove must drop the listbox row.');
            testCase.verifyFalse(out.output{1}, 'Add/remove must not trip the save output.');
        end

        function removeIfActionRemovesRow(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);

            app.IfActionsListBox.Value = action.ifActions(1);
            testCase.pushButton(app.RemoveIFActionButton);

            testCase.verifyEmpty(action.ifActions, 'Remove must drop the action from the model.');
            testCase.verifyEqual(numel(app.IfActionsListBox.Items), 0, ...
                'Remove must drop the listbox row.');
            testCase.verifyEqual(numel(app.ElseActionsListBox.Items), 1, ...
                'Removing an IF action must leave the ELSE branch alone.');
            testCase.verifyFalse(out.output{1}, 'Remove must not trip the save output.');
        end

        function removeElseActionRemovesRow(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);

            app.ElseActionsListBox.Value = action.elseActions(1);
            testCase.pushButton(app.RemoveELSEActionButton);

            testCase.verifyEmpty(action.elseActions, 'Remove must drop the action from the model.');
            testCase.verifyEqual(numel(app.ElseActionsListBox.Items), 0, ...
                'Remove must drop the listbox row.');
            testCase.verifyEqual(numel(app.IfActionsListBox.Items), 1, ...
                'Removing an ELSE action must leave the IF branch alone.');
        end

        function saveAndCloseReportsSuccess(testCase)
            [action, lvdData] = testCase.fixture(); %#ok<ASGLU>
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            fig = app.EditActionUIFigure;

            testCase.pushButton(app.SaveandCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save must close the dialog.');
        end

        function windowClosePreservesModel(testCase)
            [action, lvdData] = testCase.fixture();
            nIf = numel(action.ifActions);
            nElse = numel(action.elseActions);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            fig = app.EditActionUIFigure;

            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Closing without Save must not report success.');
            testCase.verifyEqual(numel(action.ifActions), nIf, 'Window-X must keep the IF branch.');
            testCase.verifyEqual(numel(action.elseActions), nElse, 'Window-X must keep the ELSE branch.');
        end
    end

    methods(Access=private)
        function [action, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            action = ConditionalAction();
            action.ifCondition = AlwaysTrueActionCondition();
            action.addIfAction(AddDeltaVAction([0.1; 0; 0], DeltaVFrameEnum.Inertial, false));
            action.addElseAction(AddDeltaVAction([0.2; 0; 0], DeltaVFrameEnum.Inertial, false));
        end

        function app = openDialog(testCase, action, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditConditionalActionGUI_App(action, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() ConditionalActionDialogTest.deleteIfValid(app));
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
