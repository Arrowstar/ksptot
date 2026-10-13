classdef InitialStateDialogTest < KsptotTestCase
    %InitialStateDialogTest Full round-trip UI tests for the initial-state
    %editor (Phase 4: state/aero/SRP; upgrade of the open+Cancel smoke test).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/state/lvd_EditInitialStateGUI_App.mlapp
    %   ('Edit Initial State'; GUIDE-migrated, ctor (lvdData, out))
    %   backing state: LvdData.initStateModel (orbitModel plus the initial
    %   state optimization variable and bounds).
    %   production caller: the LVD main GUI (.mlapp side); the ctor shape
    %   (lvdData, out) is taken from lvd_EditInitialStateGUI_OpeningFcn
    %   (varargin{1,2}).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   TankConstraintDialogTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The frame sub-dialog
    %   (listdlgARH_App, 'Select Frame Central Body') is stubbed with a
    %   whenShown handler that picks another body and presses OK, so the
    %   frame change is exercised without a human and without ever
    %   propagating: autoPropScript is off for the whole test.
    %
    % COVERED
    %   Open shows the stored epoch, element vector, element set and frame;
    %   Save & Close writes an edited epoch; changing the frame through the
    %   stubbed sub-dialog moves the state to the new frame; a blank epoch
    %   is rejected and leaves the model alone; Cancel and window-X
    %   preserve the model.  Nothing here runs the optimizer or propagates
    %   the script (lvdData.settings.autoPropScript = false).

    properties(Access=private)
        fixture UiwaitInterceptorFixture
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredTimeAndElements(testCase)
            lvdData = testCase.newLvdData();
            initState = lvdData.initStateModel;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(handles.lvd_EditInitialStateGUI.Name, 'Edit Initial State');
            testCase.verifyEqual(str2double(get(handles.utText, 'String')), initState.time, 'AbsTol', 1e-9, ...
                'The stored epoch must be shown.');
            elemVect = initState.orbitModel.getElementVector();
            testCase.verifyEqual(str2double(get(handles.orbit1Text, 'String')), elemVect(1), 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.orbit2Text, 'String')), elemVect(2), 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.orbit3Text, 'String')), elemVect(3), 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.orbit4Text, 'String')), elemVect(4), 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.orbit5Text, 'String')), elemVect(5), 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.orbit6Text, 'String')), elemVect(6), 'AbsTol', 1e-9);
            testCase.verifyEqual(handles.elementSetCombo.Value, ElementSetEnum.getIndForName(initState.orbitModel.typeEnum.name), ...
                'The element-set combo must reflect the model.');
            testCase.verifyEqual(handles.refFrameTypeCombo.Value, ReferenceFrameEnum.getIndForName(initState.orbitModel.frame.typeEnum.name), ...
                'The frame-type combo must reflect the model.');
        end

        function saveWritesEditedEpoch(testCase)
            lvdData = testCase.newLvdData();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditInitialStateGUI;

            set(handles.utText, 'String', '100');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save must close the dialog.');
            testCase.verifyEqual(lvdData.initStateModel.time, 100, 'AbsTol', 1e-9, ...
                'Save must write the edited epoch.');
        end

        function changeFrameViaStubbedSubDialog(testCase)
            lvdData = testCase.newLvdData();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditInitialStateGUI;

            beforeBody = getappdata(fig, 'curElemSet').frame.getOriginBody();
            testCase.fixture.whenShown('Select Frame Central Body', @pickOtherBodyAndOk);
            testCase.pushButton(app.setFrameOptionsButton);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyTrue(isvalid(fig), 'The editor must stay open after the frame change.');
            afterBody = getappdata(fig, 'curElemSet').frame.getOriginBody();
            testCase.verifyFalse(afterBody == beforeBody, ...
                'The stubbed frame dialog must move the state to another body.');
        end

        function blankEpochIsRejected(testCase)
            lvdData = testCase.newLvdData();
            beforeTime = lvdData.initStateModel.time;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.utText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank epoch must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditInitialStateGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(lvdData.initStateModel.time, beforeTime, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            lvdData = testCase.newLvdData();
            beforeTime = lvdData.initStateModel.time;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditInitialStateGUI;

            set(handles.utText, 'String', '9999');
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(lvdData.initStateModel.time, beforeTime, ...
                'Cancel must leave the model alone.');
        end

        function windowXPreservesModel(testCase)
            lvdData = testCase.newLvdData();
            beforeTime = lvdData.initStateModel.time;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditInitialStateGUI;

            set(handles.utText, 'String', '9999');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Window X must not report success.');
            testCase.verifyEqual(lvdData.initStateModel.time, beforeTime, ...
                'Window X must leave the model alone.');
        end
    end

    methods(Access=private)
        function lvdData = newLvdData(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.settings.autoPropScript = false;
        end

        function app = openDialog(testCase, lvdData, out)
            if(nargin < 3 || isempty(out))
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditInitialStateGUI_App(lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() InitialStateDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Initial State')
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
            for i = 1:numel(figs)
                if isvalid(figs(i)) && (strcmp(figs(i).Name, 'Edit Initial State') || ...
                        strcmp(figs(i).Name, 'Select Frame Central Body'))
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end

function pickOtherBodyAndOk(fig)
    %pickOtherBodyAndOk Stubbed user for the frame body picker: selects a
    %different central body than the current one and presses OK.
    lbs = findall(fig, 'Type', 'uilistbox');
    lb = lbs(1);
    items = cellstr(lb.Items);
    cur = cellstr(lb.Value);
    idx = find(~strcmp(items, cur{1}), 1, 'first');
    if(~isempty(idx))
        lb.Value = items{idx};
    end
    UiwaitInterceptorFixture.pushButton(fig, 'OK');
end
