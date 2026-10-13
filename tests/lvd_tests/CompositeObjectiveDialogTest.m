classdef CompositeObjectiveDialogTest < KsptotTestCase
    %CompositeObjectiveDialogTest Full round-trip UI tests for the composite
    %objective-function editor (Phase 1: optimization).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/optimization/lvd_EditCompositeObjectiveFunctionGUI_App.mlapp
    %   backing class: CompositeObjectiveFcn (edited through
    %   LvdData.optimizer.objFcn; dialog ctor is (lvdData, output)).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The Add button opens
    %   listdlgARH_App (figure 'Constraint Type'), stubbed below with
    %   UiwaitInterceptorFixture.whenShown to pick a self-contained type.
    %   This dialog has no Cancel button; only Save & Close is tested.
    %   No test propagates or optimizes; opening the dialog evaluates the
    %   listed functions on the (empty) state log only.
    %
    % COVERED
    %   Open shows stored direction/method; empty list shows the
    %   placeholder; Save & Close writes direction/method; Add (stubbed
    %   picker) appends a function; Remove drops the selection; editing
    %   the scale factor writes through; bad scale factors are rejected;
    %   the event dropdown reflects the selected function.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredDirectionAndMethod(testCase)
            [lvdData] = testCase.fixture();
            compObjFcn = lvdData.optimizer.objFcn;
            compObjFcn.dirType = ObjFcnDirectionTypeEnum.Maximize;
            compObjFcn.compositeMethod = ObjFcnCompositeMethodEnum.RSS;

            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(handles.optDirTypeCombo.Value, ...
                ObjFcnDirectionTypeEnum.getIndForName(compObjFcn.dirType.name));
            testCase.verifyEqual(handles.compositionTypeCombo.Value, ...
                ObjFcnCompositeMethodEnum.getIndForName(compObjFcn.compositeMethod.name));
        end

        function emptyObjectiveListShowsPlaceholder(testCase)
            [lvdData] = testCase.fixture();
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(app.objFuncListbox.Items, {'<No Objective Functions>'}, ...
                'An empty composite must show the placeholder row.');
            testCase.verifyEqual(char(handles.removeObjFuncButton.Enable), 'off', ...
                'With nothing listed there is nothing to remove.');
        end

        function saveAndCloseWritesDirectionAndMethod(testCase)
            [lvdData] = testCase.fixture();
            compObjFcn = lvdData.optimizer.objFcn;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditCompositeObjectiveFunctionGUI;

            handles.optDirTypeCombo.Value = ...
                ObjFcnDirectionTypeEnum.getIndForName(ObjFcnDirectionTypeEnum.Maximize.name);
            handles.compositionTypeCombo.Value = ...
                ObjFcnCompositeMethodEnum.getIndForName(ObjFcnCompositeMethodEnum.RSS.name);
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(compObjFcn.dirType, ObjFcnDirectionTypeEnum.Maximize);
            testCase.verifyEqual(compObjFcn.compositeMethod, ObjFcnCompositeMethodEnum.RSS);
        end

        function addObjFuncButtonAddsAnObjectiveFunction(testCase)
            [lvdData] = testCase.fixture();
            compObjFcn = lvdData.optimizer.objFcn;
            registrar = UiwaitInterceptorFixture();
            registrar.whenShown('Constraint Type', ...
                @(fig) CompositeObjectiveDialogTest.pickTotalMassAndOk(fig));

            app = testCase.openDialog(lvdData);
            nBefore = compObjFcn.getNumberObjFuncs();
            testCase.pushButton(app.addObjFuncButton);

            testCase.verifyEmpty(registrar.errors(), strjoin(registrar.errors(), newline));
            testCase.verifyEqual(compObjFcn.getNumberObjFuncs(), nBefore + 1, ...
                'Accepting the picker must append one objective function.');
            testCase.verifyFalse(isequal(app.objFuncListbox.Items, {'<No Objective Functions>'}));
        end

        function removeObjFuncButtonRemovesSelectedFunction(testCase)
            [lvdData] = testCase.fixture();
            compObjFcn = lvdData.optimizer.objFcn;
            genObj = testCase.makeOneObjFunc(lvdData);

            app = testCase.openDialog(lvdData);
            app.objFuncListbox.Value = genObj;
            drawnow;
            testCase.pushButton(app.removeObjFuncButton);

            testCase.verifyEqual(compObjFcn.getNumberObjFuncs(), 0, ...
                'Remove must drop the selected function.');
            testCase.verifyEqual(app.objFuncListbox.Items, {'<No Objective Functions>'});
        end

        function scaleFactorEditWritesThroughToSelectedFunction(testCase)
            [lvdData] = testCase.fixture();
            genObj = testCase.makeOneObjFunc(lvdData);

            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.scaleFactorText, 'String', '4');
            evt = struct('Source', app.scaleFactorText, 'Value', '4', ...
                'PreviousValue', '', 'EventName', 'ValueChanged');
            app.scaleFactorText.ValueChangedFcn(app.scaleFactorText, evt);
            drawnow;

            testCase.verifyEqual(genObj.scaleFactor, 4, 'AbsTol', 1e-12, ...
                'A valid scale factor edits the selected function at once.');
        end

        function invalidScaleFactorIsRejected(testCase)
            [lvdData] = testCase.fixture();
            genObj = testCase.makeOneObjFunc(lvdData);

            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditCompositeObjectiveFunctionGUI;

            set(handles.scaleFactorText, 'String', '0');
            evt = struct('Source', app.scaleFactorText, 'Value', '0', ...
                'PreviousValue', '', 'EventName', 'ValueChanged');
            app.scaleFactorText.ValueChangedFcn(app.scaleFactorText, evt);
            drawnow;

            testCase.verifyEqual(genObj.scaleFactor, 1, 'AbsTol', 1e-12, ...
                'A rejected scale factor must leave the model alone.');
            testCase.verifyTrue(isvalid(fig), 'The dialog must stay open.');
            testCase.closeAlerts();
        end

        function eventComboReflectsSelectedFunction(testCase)
            [lvdData] = testCase.fixture();
            testCase.makeOneObjFunc(lvdData);

            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(handles.eventCombo.Value, 1, ...
                'The single-event fixture must be selected.');
            testCase.verifyFalse(isempty(cellstr(handles.eventCombo.String)));
        end
    end

    methods(Access=private)
        function [lvdData, out] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            out = AppDesignerGUIOutput({false});
        end

        function genObj = makeOneObjFunc(testCase, lvdData) %#ok<INUSL>
            event = lvdData.script.getEventForInd(1);
            frame = LvdData.getDefaultInitialBodyInfo(lvdData.celBodyData).getBodyCenteredInertialFrame();
            fcn = GenericMAConstraint.getDefaultConstraint('Total Spacecraft Mass', lvdData);
            fcn.event = event;
            genObj = GenericObjectiveFcn(event, frame, fcn, 1, lvdData.optimizer, lvdData);
            lvdData.optimizer.objFcn.addObjFunc(genObj);
        end

        function app = openDialog(testCase, lvdData, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditCompositeObjectiveFunctionGUI_App(lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() CompositeObjectiveDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Objective Function')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Objective Function')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end

        function pickTotalMassAndOk(fig)
            %pickTotalMassAndOk listdlgARH handler: select a constraint
            %type whose setupForUseAsObjectiveFcn needs no extra objects
            %and press OK.  The registry lives in groot appdata, so any
            %interceptor instance can register this handler.
            lbs = findall(fig, 'Type', 'uilistbox');
            lb = lbs(1);
            idx = find(strcmp(lb.Items, 'Total Spacecraft Mass'), 1);
            if isempty(idx)
                idx = 1;
            end
            lb.Value = lb.Items{idx};
            drawnow;
            UiwaitInterceptorFixture.pushButton(fig, 'OK');
        end
    end
end
