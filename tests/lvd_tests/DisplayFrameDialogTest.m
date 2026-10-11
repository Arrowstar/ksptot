classdef DisplayFrameDialogTest < KsptotTestCase
    %DisplayFrameDialogTest Full round-trip UI tests for the orbit display
    %frame/element-set editor (Phase 4: state/aero/SRP; upgrade of the
    %open+Cancel smoke test).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/state/lvd_EditDisplayFrameAndElementSet_App.mlapp
    %   ('Edit Orbit Display'; programmatic,
    %   ctor (lvdData, curElementSet, curReferenceFrame, out))
    %   backing state: none stored -- the dialog returns the picked frame
    %   and element set through out (Save: {refFrame, elementSet};
    %   Cancel: {false, false}).
    %   production caller: the LVD main GUI (.mlapp side); the ctor shape
    %   is taken from startupFcn(lvdData, curElementSet, curReferenceFrame, out).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  The frame sub-dialog (Set Frame
    %   Options) is not pressed here; the frame change under test is the
    %   central-body default checkbox plus the element-set combo.
    %
    % COVERED
    %   Open shows the given element set and frame (and the checked,
    %   disabling default when the frame is empty); Save writes a changed
    %   element set; Save with the default checked clears the frame; Cancel
    %   and window-X report {false, false} and change nothing.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsCurrentElementSetAndFrame(testCase)
            lvdData = testCase.newLvdData();
            frame = testCase.kerbin.getBodyCenteredInertialFrame();
            out = AppDesignerGUIOutput({false, false});
            app = testCase.openDialog(lvdData, ElementSetEnum.KeplerianElements, frame, out);

            testCase.verifyEqual(app.EditOrbitDisplayUIFigure.Name, 'Edit Orbit Display');
            testCase.verifyEqual(app.elementSetCombo.Value, ElementSetEnum.KeplerianElements, ...
                'The given element set must be shown.');
            testCase.verifyEqual(app.refFrameTypeCombo.Value, ReferenceFrameEnum.BodyCenteredInertial, ...
                'The given frame type must be shown.');
            testCase.verifyFalse(logical(app.UseCentralBodyInertialFrameCheckBox.Value), ...
                'A given frame must leave the default unchecked.');
            testCase.verifyTrue(isvalid(app.setFrameOptionsButton), ...
                'The frame options button must exist.');
        end

        function emptyFrameChecksCentralBodyDefault(testCase)
            lvdData = testCase.newLvdData();
            out = AppDesignerGUIOutput({false, false});
            app = testCase.openDialog(lvdData, ElementSetEnum.CartesianElements, ...
                AbstractReferenceFrame.empty(1, 0), out);

            testCase.verifyTrue(logical(app.UseCentralBodyInertialFrameCheckBox.Value), ...
                'An empty frame must check the central-body default.');
            testCase.verifyEqual(app.elementSetCombo.Value, ElementSetEnum.CartesianElements);
            testCase.verifyTrue(testCase.isOff(app.refFrameTypeCombo), ...
                'The default must disable the frame-type combo.');
            testCase.verifyTrue(testCase.isOff(app.setFrameOptionsButton), ...
                'The default must disable the frame options button.');
        end

        function saveWritesChangedElementSet(testCase)
            lvdData = testCase.newLvdData();
            frame = testCase.kerbin.getBodyCenteredInertialFrame();
            out = AppDesignerGUIOutput({false, false});
            app = testCase.openDialog(lvdData, ElementSetEnum.KeplerianElements, frame, out);
            fig = app.EditOrbitDisplayUIFigure;

            app.elementSetCombo.Value = ElementSetEnum.CartesianElements;
            testCase.pushButton(app.SaveCloseButton);

            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(out.output{2}, ElementSetEnum.CartesianElements, ...
                'Save must write the changed element set.');
            testCase.verifySameHandle(out.output{1}, frame, ...
                'An untouched frame must pass straight through.');
        end

        function saveWithCheckboxClearsFrame(testCase)
            lvdData = testCase.newLvdData();
            frame = testCase.kerbin.getBodyCenteredInertialFrame();
            out = AppDesignerGUIOutput({false, false});
            app = testCase.openDialog(lvdData, ElementSetEnum.KeplerianElements, frame, out);
            fig = app.EditOrbitDisplayUIFigure;

            app.UseCentralBodyInertialFrameCheckBox.Value = true;
            testCase.pushButton(app.SaveCloseButton);

            testCase.verifyFalse(isvalid(fig));
            testCase.verifyEmpty(out.output{1}, ...
                'Save with the default checked must clear the frame.');
            testCase.verifyEqual(out.output{2}, ElementSetEnum.KeplerianElements);
        end

        function cancelPreservesOutputs(testCase)
            lvdData = testCase.newLvdData();
            frame = testCase.kerbin.getBodyCenteredInertialFrame();
            out = AppDesignerGUIOutput({false, false});
            app = testCase.openDialog(lvdData, ElementSetEnum.KeplerianElements, frame, out);
            fig = app.EditOrbitDisplayUIFigure;

            app.elementSetCombo.Value = ElementSetEnum.CartesianElements;
            testCase.pushButton(app.CancelButton);

            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyFalse(out.output{1}, 'Cancel must report {false, false}.');
            testCase.verifyFalse(out.output{2});
        end

        function windowXLeavesOutputsAlone(testCase)
            lvdData = testCase.newLvdData();
            frame = testCase.kerbin.getBodyCenteredInertialFrame();
            out = AppDesignerGUIOutput({false, false});
            app = testCase.openDialog(lvdData, ElementSetEnum.KeplerianElements, frame, out);
            fig = app.EditOrbitDisplayUIFigure;

            app.elementSetCombo.Value = ElementSetEnum.CartesianElements;
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Window X must not report a selection.');
            testCase.verifyFalse(out.output{2});
        end
    end

    methods(Access=private)
        function lvdData = newLvdData(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.settings.autoPropScript = false;
        end

        function app = openDialog(testCase, lvdData, elemSet, frame, out)
            if(nargin < 5 || isempty(out))
                out = AppDesignerGUIOutput({false, false});
            end
            app = lvd_EditDisplayFrameAndElementSet_App(lvdData, elemSet, frame, out);
            drawnow;
            testCase.assertTrue(~isempty(app) && isvalid(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() DisplayFrameDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function tf = isOff(~, comp)
            tf = strcmpi(string(comp.Enable), 'off');
        end
    end

    methods(Static, Access=private)
        function deleteIfValid(app)
            if(~isempty(app) && isvalid(app))
                delete(app);
            end
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Orbit Display')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
