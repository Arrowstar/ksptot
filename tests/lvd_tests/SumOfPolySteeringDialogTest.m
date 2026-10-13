classdef SumOfPolySteeringDialogTest < KsptotTestCase
    %SumOfPolySteeringDialogTest Full round-trip UI tests for the
    %sum-of-polynomial-terms math editor (Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/steeringModels/lvd_EditSumOfPolynomialTermsModelGUI_App.mlapp
    %   backing class: SumOfPolyTermsModel (+ PolynominalTermModel rows)
    %   production caller: none under helper_methods/ (.mlapp only; opened
    %   from the selectable-steering edit-term buttons).  The dialog is
    %   therefore driven directly as
    %   lvd_EditSumOfPolynomialTermsModelGUI_App(model, out).
    %
    % PATTERN
    %   GUIDE-migrated dialog; UiwaitInterceptorFixture stands in for uiwait
    %   (the PatchedMlappDialogsTest pattern).  The termListbox mirrors
    %   the InterpThrottleModelUITest table: population, add/remove rows,
    %   validation of bad rows, save mutation and preservation without
    %   saving.  This editor is save-only (no Cancel in
    %   AREA_actionUIs.txt), so preservation is checked via failed
    %   validation and via closing without saving.
    %
    % COVERED
    %   Listbox population from terms (const/coeff display in degrees);
    %   add appends a term; remove drops the selected term (select by member
    %   object: the listbox holds PolynominalTermModel handles); removing the
    %   last term empties the list (the dialog has no last-term guard);
    %   control callbacks write through live (degrees in, radians stored);
    %   blank/non-numeric coeff/exponent edits are rejected at the control;
    %   Save & Close only reports success (no validation of its own); close
    %   without saving preserves the model.
    %
    % NOTE: reassigning the listbox Items while Value holds a removed term
    %   trips the App Designer migration-layer ismember crash (bug log
    %   1.25-family); it surfaces as a listener warning, not a failure.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogListboxMatchesModel(testCase)
            model = testCase.fixture();
            model.const = 0.15;
            model.terms(1).coeff = 0.02;
            model.terms(1).exponent = 1;
            model.addTerm(PolynominalTermModel(0, -0.001, 2));

            app = testCase.openDialog(model);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(numel(cellstr(handles.termListbox.String)), 2, ...
                'Both polynomial terms must be listed.');
            testCase.verifyEqual(str2double(get(handles.constText, 'String')), rad2deg(0.15), 'AbsTol', 1e-9, ...
                'Const displays in degrees.');
        end

        function dialogAddTermAppendsRow(testCase)
            model = testCase.fixture();
            app = testCase.openDialog(model);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            testCase.verifyEqual(model.getNumTerms(), 1);

            testCase.pushButton(app.addTermButton);
            drawnow;

            testCase.verifyEqual(model.getNumTerms(), 2, 'Add must append one term.');
            testCase.verifyEqual(numel(cellstr(handles.termListbox.String)), 2, ...
                'The listbox must show the new term.');
        end

        function dialogRemoveTermDropsSelectedRow(testCase)
            model = testCase.fixture();
            model.terms(1).coeff = 0.02;
            model.addTerm(PolynominalTermModel(0, 0.05, 1));
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            testCase.verifyEqual(model.getNumTerms(), 2);

            %Select by member object through the modern handle (the listbox
            %holds term handles; the legacy handle only accepts indices).
            app.termListbox.Value = model.terms(1);
            testCase.pushButton(app.removeTermButton);

            testCase.verifyEqual(model.getNumTerms(), 1, 'One of the two terms must remain.');
            testCase.verifyEqual(model.terms(1).coeff, 0.05, 'AbsTol', 1e-12, ...
                'Removing term 1 must keep term 2.');
        end

        function dialogRemoveLastTermEmptiesList(testCase)
            %The dialog has no last-term guard (removeTerm has none either):
            %removing the only term empties the model.
            model = testCase.fixture();
            app = testCase.openDialog(model);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            testCase.assertEqual(model.getNumTerms(), 1);

            app.termListbox.Value = model.terms(1);
            testCase.pushButton(app.removeTermButton);
            drawnow;

            testCase.verifyEqual(model.getNumTerms(), 0, 'Removing the last term empties the model.');
            testCase.closeAlerts();
        end

        function controlCallbacksWriteThroughLive(testCase)
            model = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditSumOfPolynomialTermsModelGUI;

            %Degree entries store as radians as soon as each control
            %callback fires; Save & Close only reports success.
            testCase.editControl(app, handles.constText, app.constText, '0.3');
            testCase.editControl(app, handles.coeffText, app.coeffText, '0.04');
            testCase.editControl(app, handles.expText, app.expText, '2');
            testCase.verifyEqual(model.const, deg2rad(0.3), 'AbsTol', 1e-12);
            testCase.verifyEqual(model.terms(1).coeff, deg2rad(0.04), 'AbsTol', 1e-12);
            testCase.verifyEqual(model.terms(1).exponent, 2);

            testCase.pushButton(app.saveAndCloseButton);
            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
        end

        function blankCoeffIsRejectedAtControl(testCase)
            model = testCase.fixture();
            model.terms(1).coeff = 0.02;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.coeffText, 'String', '');
            app.coeffText.ValueChangedFcn(app.coeffText, testCase.vcEvent(app.coeffText, ''));
            drawnow;

            testCase.verifyEqual(model.terms(1).coeff, 0.02, 'AbsTol', 1e-15, ...
                'Rejected input must leave the model alone.');
            testCase.verifyTrue(isvalid(handles.lvd_EditSumOfPolynomialTermsModelGUI), ...
                'The dialog must stay open.');
            testCase.verifyFalse(out.output{1}, 'Nothing saved yet.');
            testCase.closeAlerts();
            close(handles.lvd_EditSumOfPolynomialTermsModelGUI);
        end

        function nonNumericExponentIsRejectedAtControl(testCase)
            model = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.expText, 'String', 'abc');
            app.expText.ValueChangedFcn(app.expText, testCase.vcEvent(app.expText, 'abc'));
            drawnow;

            testCase.verifyTrue(isvalid(handles.lvd_EditSumOfPolynomialTermsModelGUI));
            testCase.verifyFalse(out.output{1}, 'Nothing saved yet.');
            testCase.closeAlerts();
            close(handles.lvd_EditSumOfPolynomialTermsModelGUI);
        end

        function closeWithoutSavingPreservesModel(testCase)
            model = testCase.fixture();
            model.const = 0.15;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditSumOfPolynomialTermsModelGUI;

            set(handles.constText, 'String', '9.9');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1});
            testCase.verifyEqual(model.const, 0.15, 'AbsTol', 1e-15, ...
                'Closing without saving must leave the model alone.');
        end
    end

    methods(Access=private)
        function model = fixture(~)
            model = SumOfPolyTermsModel(0);
        end

        function app = openDialog(testCase, model, out)
            if(nargin < 3 || isempty(out))
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditSumOfPolynomialTermsModelGUI_App(model, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() SumOfPolySteeringDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function editControl(testCase, app, legacyCtrl, ctrl, str)
            %editControl Sets an EditField's text through its legacy
            %GUIDE handle and fires its ValueChanged callback on the app
            %component (the redirect strategy needs a Value-bearing event).
            %#ok<INUSL>
            set(legacyCtrl, 'String', str);
            ctrl.ValueChangedFcn(ctrl, testCase.vcEvent(ctrl, str));
            drawnow;
        end

        function evt = vcEvent(~, ctrl, str)
            evt = struct('Source', ctrl, 'Value', str, ...
                'PreviousValue', '', 'EventName', 'ValueChanged');
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for(i = 1:numel(figs))
                if(isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Generic Polynomial Model'))
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
            if(~isempty(app) && isvalid(app))
                delete(app);
            end
            figs = findall(groot, 'Type', 'figure');
            for(i = 1:numel(figs))
                if(isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Generic Polynomial Model'))
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
