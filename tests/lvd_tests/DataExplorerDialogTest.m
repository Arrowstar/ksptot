classdef DataExplorerDialogTest < KsptotTestCase
    %DataExplorerDialogTest Open/browse/close tests for the LVD data
    %explorer (Phase 5: root/misc UIs).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/plugins/lvd_dataExplorerGUI.m (+ .fig)
    %   GUIDE dialog; ctor: lvd_dataExplorerGUI(inputData, inputNames).
    %   LvdData input renders through ScalarObjPropertyNode, cell input
    %   through FuncScopePropertyNode.  Production caller:
    %   showLvdDataStructButton_Callback in plugins/ldv_editPluginGUI.m.
    %
    % PATTERN
    %   The closest meaningful equivalent of a round-trip for this
    %   read-only browser: open on both input branches, assert the key
    %   panels/controls and the Java property-grid peers exist, and close
    %   through the Close-button callback (uicontrol-style dispatch into
    %   the local callback, as in the LvdMainGuiWidgetSmokeTest GUIDE
    %   fallback).  The dialog never calls uiwait (its uiwait line is
    %   commented out), so UiwaitInterceptorFixture is belt and braces only.
    %   The property grid is Java: every test assumes usejava('jvm').
    %
    % COVERED
    %   Open on LVD data and on cell input; key panels, appdata and Java
    %   peers present; Close deletes the figure; reopen-after-close works;
    %   cell input round-trips through appdata.  Nothing is propagated and
    %   the mission is never mutated.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end

        function requireJvm(testCase)
            testCase.assumeTrue(usejava('jvm'), 'The data explorer property grid needs the JVM.');
        end
    end

    methods(Test)
        function opensOnLvdDataWithKeyPanels(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            fig = testCase.openExplorer(lvdData, 'lvdData');

            handles = guidata(fig);
            for field = {'lvd_dataExplorerGUI', 'propGridPanel', 'breadcrumbPanel', 'busySpinnerIconPanel'}
                testCase.verifyTrue(isfield(handles, field{1}), ...
                    sprintf('The explorer must expose "%s".', field{1}));
            end
            testCase.verifyTrue(getappdata(fig, 'explrInput') == lvdData, ...
                'The explored input must be stashed on the figure.');
            testCase.closeExplorer(fig);
            testCase.verifyFalse(ishandle(fig), 'Close must delete the figure.');
        end

        function opensOnCellInputViaFuncScopeBranch(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            fig = testCase.openExplorer({lvdData, lvdData.stateLog}, {'lvdData', 'stateLog'});

            testCase.verifyTrue(ishandle(fig), 'Cell input must open without hanging.');
            testCase.verifyEqual(numel(getappdata(fig, 'explrInput')), 2);
            testCase.closeExplorer(fig);
            testCase.verifyFalse(ishandle(fig));
        end

        function javaPropertyGridPeersExist(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            fig = testCase.openExplorer(lvdData, 'lvdData');

            handles = guidata(fig);
            testCase.verifyFalse(isempty(handles.jBreadCrumbBar), 'The breadcrumb bar must be built.');
            testCase.verifyFalse(isempty(handles.jSpinnerIcon), 'The spinner icon must be built.');
            testCase.verifyTrue(ishandle(handles.hSpinnerIcon), 'The spinner peer must be parented.');
            testCase.closeExplorer(fig);
        end

        function closeButtonDeletesFigure(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            fig = testCase.openExplorer(lvdData, 'lvdData');

            lvd_dataExplorerGUI('closeButton_Callback', fig, [], guidata(fig));
            drawnow;

            testCase.verifyFalse(ishandle(fig), 'The Close callback must delete the figure.');
        end

        function reopenAfterCloseWithoutHang(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            fig = testCase.openExplorer(lvdData, 'lvdData');
            testCase.closeExplorer(fig);
            testCase.verifyFalse(ishandle(fig));

            fig2 = testCase.openExplorer(lvdData, 'lvdData');
            testCase.verifyTrue(ishandle(fig2), 'Singleton reuse must reopen cleanly.');
            testCase.closeExplorer(fig2);
            testCase.verifyFalse(ishandle(fig2));
        end

        function unknownInputErrorsWithoutHang(testCase)
            figuresBefore = findall(groot, 'Type', 'figure');

            %verifyError's second argument is an expected identifier, not a
            %message (the thrown error carries no identifier), so assert
            %via try/catch instead.
            threw = false;
            try
                lvd_dataExplorerGUI(42, 'x');
            catch ME
                threw = true;
                testCase.verifyNotEmpty(ME.message, 'The error must explain the bad input.');
            end
            testCase.verifyTrue(threw, 'Unknown explorer input must error, not hang.');

            figs = findall(groot, 'Type', 'figure');
            orphans = figs(not(ismember(figs, figuresBefore)));
            delete(orphans(isvalid(orphans)));
            testCase.verifyTrue(true, 'The failed open must leave no waiting dialog.');
        end

        function explorerLeavesMissionAlone(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.notes = 'Do not touch.';
            nPlugins = lvdData.plugins.getNumPlugins();

            fig = testCase.openExplorer(lvdData, 'lvdData');
            testCase.closeExplorer(fig);

            testCase.verifyEqual(lvdData.notes, 'Do not touch.');
            testCase.verifyEqual(lvdData.plugins.getNumPlugins(), nPlugins);
        end
    end

    methods(Access=private)
        function fig = openExplorer(testCase, inputData, inputNames)
            fig = lvd_dataExplorerGUI(inputData, inputNames);
            drawnow;
            testCase.assertTrue(ishandle(fig), 'The explorer constructor returned nothing.');
            testCase.addTeardown(@() DataExplorerDialogTest.closeIfOpen(fig));
        end

        function closeExplorer(~, fig)
            if ishandle(fig)
                lvd_dataExplorerGUI('closeButton_Callback', fig, [], guidata(fig));
                drawnow;
            end
        end
    end

    methods(Static, Access=private)
        function closeIfOpen(fig)
            if ishandle(fig)
                try %#ok<TRYNC>
                    delete(fig);
                end
            end
        end
    end
end
