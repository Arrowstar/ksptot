classdef ManagePluginsDialogTest < KsptotTestCase
    %ManagePluginsDialogTest List/add/remove/close tests for the Manage
    %Plugins dialog (Phase 5: root/misc UIs).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/plugins/ldv_editPluginGUI.m (+ .fig)
    %   GUIDE dialog; ctor: ldv_editPluginGUI(lvdData).
    %   main-GUI caller: managePluginsMenu_Callback (result drives undo).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait.  GUIDE's OutputFcn closes live figures on return, so with a
    %   stubbed uiwait the dialog would self-close before it can be driven:
    %   the whenShown hook therefore stashes guidata in figure appdata and
    %   blanks guidata, OutputFcn then returns false without closing, and
    %   the figure stays open (guidata is restored right after).  Controls
    %   are driven uicontrol-style by dispatching the .m file's local
    %   callbacks by name (the documented GUIDE 'CALLBACK' API, same idea
    %   as the LvdMainGuiWidgetSmokeTest GUIDE fallback).  The embedded
    %   code editor is Java: every test assumes usejava('jvm'), exactly like
    %   pluginsManageOpensWithoutHang.  The Save/Load-to-file buttons are
    %   never pressed (uiputfile/uigetfile/listdlgARH would hang or write).
    %
    % COVERED
    %   Open with no plugins; Add appends a stub; rename, exec-location
    %   and enable checkboxes write live; move up/down reorders; Delete
    %   removes an unused stub; Cancel and the figure control close without
    %   changing the model.  Nothing is executed or propagated.

    properties(Access=private)
        uiwaitFx UiwaitInterceptorFixture
    end

    methods(TestMethodSetup)
        function armFixtures(testCase)
            testCase.uiwaitFx = testCase.applyFixture(UiwaitInterceptorFixture());
        end

        function requireJvm(testCase)
            testCase.assumeTrue(usejava('jvm'), 'The plugin code editor needs the JVM.');
        end
    end

    methods(Test)
        function dialogOpensWithNoPluginsSelected(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            [fig, handles] = testCase.openDialog(lvdData);

            testCase.verifyTrue(isfield(handles, 'pluginsListbox'));
            testCase.verifyEmpty(get(handles.pluginsListbox, 'String'), ...
                'A fresh mission has no plugins to list.');
            testCase.verifyEqual(get(handles.pluginNameText, 'String'), 'No Plugin Selected');
            testCase.verifyEqual(get(handles.execBeforePropCheckbox, 'Enable'), 'off', ...
                'With no selection the per-plugin controls must disable.');
        end

        function addPluginButtonAppendsStub(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            [fig, handles] = testCase.openDialog(lvdData);

            testCase.dispatch(fig, 'addPluginButton_Callback', fig);

            testCase.verifyEqual(lvdData.plugins.getNumPlugins(), 1, 'Add must append a plugin.');
            testCase.verifyEqual(get(guidata(fig).pluginsListbox, 'String'), ...
                {'Untitled LVD Plugin'}, 'The listbox must refresh.');
            testCase.verifyEqual(get(guidata(fig).pluginNameText, 'String'), 'Untitled LVD Plugin');
            testCase.verifyEqual(get(guidata(fig).execBeforePropCheckbox, 'Enable'), 'on');
        end

        function renamePluginWritesLive(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            [fig, handles] = testCase.openDialog(lvdData);
            testCase.dispatch(fig, 'addPluginButton_Callback', fig);

            set(handles.pluginNameText, 'String', 'Stub Plugin');
            testCase.dispatch(fig, 'pluginNameText_Callback', handles.pluginNameText);

            testCase.verifyEqual(lvdData.plugins.plugins(1).pluginName, 'Stub Plugin', ...
                'Renaming must write live to the plugin.');
            testCase.verifyEqual(get(guidata(fig).pluginsListbox, 'String'), {'Stub Plugin'}, ...
                'The listbox must refresh.');
        end

        function execLocationCheckboxWritesLive(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            [fig, handles] = testCase.openDialog(lvdData);
            testCase.dispatch(fig, 'addPluginButton_Callback', fig);

            set(handles.execBeforePropCheckbox, 'Value', 1);
            testCase.dispatch(fig, 'execBeforePropCheckbox_Callback', handles.execBeforePropCheckbox);

            testCase.verifyTrue(lvdData.plugins.plugins(1).execBeforePropTF, ...
                'The exec-location checkbox must write live.');
        end

        function enablePluginsCheckboxFlipsSet(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            testCase.assertTrue(lvdData.plugins.enablePlugins, 'Fixture: plugins start enabled.');
            [fig, handles] = testCase.openDialog(lvdData);

            set(handles.enablePluginsCheckbox, 'Value', 0);
            testCase.dispatch(fig, 'enablePluginsCheckbox_Callback', handles.enablePluginsCheckbox);

            testCase.verifyFalse(lvdData.plugins.enablePlugins, 'The enable switch must write live.');
        end

        function moveUpAndDownReorderStubs(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            [fig, handles] = testCase.openDialog(lvdData);
            testCase.dispatch(fig, 'addPluginButton_Callback', fig);
            set(handles.pluginNameText, 'String', 'AAA');
            testCase.dispatch(fig, 'pluginNameText_Callback', handles.pluginNameText);
            testCase.dispatch(fig, 'addPluginButton_Callback', fig);
            handles = guidata(fig);
            set(handles.pluginNameText, 'String', 'BBB');
            testCase.dispatch(fig, 'pluginNameText_Callback', handles.pluginNameText);
            testCase.assertEqual({lvdData.plugins.plugins.pluginName}, {'AAA', 'BBB'});

            set(handles.pluginsListbox, 'Value', 2);
            testCase.dispatch(fig, 'movePluginUpButton_Callback', fig);
            testCase.verifyEqual({lvdData.plugins.plugins.pluginName}, {'BBB', 'AAA'}, ...
                'Move Up must swap the selected stub upward.');

            testCase.dispatch(fig, 'movePluginDownButton_Callback', fig);
            testCase.verifyEqual({lvdData.plugins.plugins.pluginName}, {'AAA', 'BBB'}, ...
                'Move Down must swap it back.');
        end

        function deletePluginButtonRemovesUnusedStub(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            [fig, handles] = testCase.openDialog(lvdData);
            testCase.dispatch(fig, 'addPluginButton_Callback', fig);
            testCase.assertEqual(lvdData.plugins.getNumPlugins(), 1);

            set(guidata(fig).pluginsListbox, 'Value', 1);
            testCase.dispatch(fig, 'deletePluginButton_Callback', fig);

            testCase.verifyEqual(lvdData.plugins.getNumPlugins(), 0, 'Delete must remove the stub.');
            testCase.verifyEqual(get(guidata(fig).pluginNameText, 'String'), 'No Plugin Selected');
        end

        function cancelClosesWithoutChangingModel(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            [fig, handles] = testCase.openDialog(lvdData);
            testCase.dispatch(fig, 'addPluginButton_Callback', fig);
            set(handles.pluginNameText, 'String', 'Keep Me');
            testCase.dispatch(fig, 'pluginNameText_Callback', handles.pluginNameText);

            testCase.dispatch(fig, 'cancelButton_Callback', fig);

            testCase.verifyFalse(ishandle(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(lvdData.plugins.getNumPlugins(), 1, 'Cancel must not drop the stub.');
            testCase.verifyEqual(lvdData.plugins.plugins(1).pluginName, 'Keep Me');
        end
    end

    methods(Access=private)
        function [fig, handles] = openDialog(testCase, lvdData)
            %keepOpen (below) runs inside the stubbed uiwait and keeps the
            %figure alive past OutputFcn; it is one-shot per open.
            testCase.uiwaitFx.whenShown('*', @ManagePluginsDialogTest.keepOpen);
            figuresBefore = findall(groot, 'Type', 'figure');

            ldv_editPluginGUI(lvdData);
            drawnow;

            figs = findall(groot, 'Type', 'figure');
            newFigs = figs(not(ismember(figs, figuresBefore)));
            testCase.assertNotEmpty(newFigs, 'The Manage Plugins dialog did not open.');
            fig = newFigs(1);
            testCase.assertTrue(ishandle(fig));

            handles = getappdata(fig, 'ManagePluginsDialogTest_handles');
            testCase.assertTrue(isstruct(handles) && isfield(handles, 'pluginsListbox'), ...
                'The dialog handles were not stashed.');
            guidata(fig, handles);
            testCase.addTeardown(@() ManagePluginsDialogTest.closeIfOpen(fig));
        end

        function dispatch(~, fig, callbackName, hObject)
            handles = guidata(fig);
            ldv_editPluginGUI(callbackName, hObject, [], handles);
            drawnow;
        end
    end

    methods(Static, Access=private)
        function keepOpen(fig)
            %keepOpen whenShown hook: stash the live handles, then blank
            %guidata so OutputFcn returns false instead of closing the
            %figure (see class header).  Restored by openDialog.
            setappdata(fig, 'ManagePluginsDialogTest_handles', guidata(fig));
            guidata(fig, []);
        end

        function closeIfOpen(fig)
            if ishandle(fig)
                try %#ok<TRYNC>
                    delete(fig);
                end
            end
        end
    end
end
