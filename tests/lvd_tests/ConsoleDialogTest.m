classdef ConsoleDialogTest < KsptotTestCase
    %ConsoleDialogTest Open/execute/clear/close tests for the LVD console
    %(Phase 5: root/misc UIs; upgrades the main-GUI smoke press to a
    %value-level suite).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/lvd_Console_App.mlapp
    %   ctor: lvd_Console_App(lvdData)
    %   main-GUI caller: LVDConsoleMenuSelected (Tools menu).  The console
    %   evaluates MATLAB commands with lvdData in scope, echoes into
    %   OutputTextArea, tracks workspace variables in VariableTable, and
    %   holds no mission state itself.
    %
    % PATTERN
    %   The console never blocks in uiwait and pops no native dialogs, so
    %   UiwaitInterceptorFixture is applied for uniformity only.  Commands
    %   are run by setting CommandLineText and firing EnterButton (both
    %   call executeConsoleCmd); only side-effect-free commands are used.
    %
    % COVERED
    %   Open exposes the command line, output, buttons and variable table;
    %   the table lists lvdData; Enter echoes the command and its result
    %   and clears the line; errors are reported inline; Clear empties the
    %   output; closing deletes the figure and leaves the mission alone.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogOpensWithExpectedControls(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            testCase.verifyEqual(app.LaunchVehicleDesignerConsoleUIFigure.Name, ...
                'Launch Vehicle Designer Console');
            testCase.verifyTrue(isvalid(app.CommandLineText));
            testCase.verifyTrue(isvalid(app.OutputTextArea));
            testCase.verifyEqual(app.EnterButton.Text, 'Enter');
            testCase.verifyEqual(app.ClearButton.Text, 'Clear');
            testCase.verifyEqual(cellstr(app.VariableTable.ColumnName), {'Variable'; 'Data'});
        end

        function variableTableListsLvdData(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            names = string(app.VariableTable.Data(:, 1));
            testCase.verifyTrue(any(names == "lvdData"), ...
                'The workspace table must offer the mission data.');
        end

        function enterButtonExecutesCommand(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            app.CommandLineText.Value = '1+1';
            testCase.pushButton(app.EnterButton);

            out = strjoin(string(app.OutputTextArea.Value), newline);
            testCase.verifyTrue(contains(out, '>> 1+1'), 'The command must be echoed.');
            testCase.verifyTrue(contains(out, '2'), 'The result must be shown.');
            testCase.verifyEqual(app.CommandLineText.Value, '', 'The line must clear after Enter.');
        end

        function commandErrorIsReportedInline(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            app.CommandLineText.Value = 'thisFnDoesNotExist_xyz';
            testCase.pushButton(app.EnterButton);

            out = strjoin(string(app.OutputTextArea.Value), newline);
            testCase.verifyTrue(contains(out, 'ERROR:'), 'Failures must be reported, not thrown.');
            testCase.verifyTrue(isvalid(app.LaunchVehicleDesignerConsoleUIFigure));
        end

        function clearButtonEmptiesOutput(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            app.CommandLineText.Value = '1+1';
            testCase.pushButton(app.EnterButton);
            testCase.assertTrue(strlength(strjoin(string(app.OutputTextArea.Value), newline)) > 0, ...
                'Fixture: the output must be non-empty before clearing.');
            testCase.pushButton(app.ClearButton);

            testCase.verifyEqual(strlength(app.OutputTextArea.Value), 0, ...
                'Clear must empty the output.');
        end

        function commandLineValueChangedAlsoExecutes(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            app.CommandLineText.Value = '2+3';
            app.CommandLineText.ValueChangedFcn(app.CommandLineText, ...
                struct('Source', app.CommandLineText, 'EventName', 'ValueChanged'));
            drawnow;

            out = strjoin(string(app.OutputTextArea.Value), newline);
            testCase.verifyTrue(contains(out, '>> 2+3'), 'Committing the line must execute it.');
            testCase.verifyTrue(contains(out, '5'), 'The result must be shown.');
        end

        function closeDeletesFigureAndPreservesMission(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.notes = 'Untouched.';
            app = testCase.openDialog(lvdData);
            fig = app.LaunchVehicleDesignerConsoleUIFigure;

            delete(app);

            testCase.verifyFalse(isvalid(fig), 'Closing must delete the console figure.');
            testCase.verifyEqual(lvdData.notes, 'Untouched.', ...
                'The console holds no mission state to preserve.');
        end
    end

    methods(Access=private)
        function app = openDialog(testCase, lvdData)
            app = lvd_Console_App(lvdData);
            drawnow;
            testCase.assertTrue(~isempty(app) && isvalid(app.LaunchVehicleDesignerConsoleUIFigure), ...
                'The dialog constructor returned nothing.');
            testCase.addTeardown(@() ConsoleDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Launch Vehicle Designer Console')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
