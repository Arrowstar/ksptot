classdef E2TPriorityDialogTest < KsptotTestCase
    %E2TPriorityDialogTest Full round-trip UI tests for the engine-to-tank
    %flow-priority editor (Phase 3: vehicle).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_EditE2TPriorityGUI_App.m
    %   (programmatic uifigure dialog, NOT a .mlapp)
    %   backing class: EngineToTankConnection (dialog ctor is (conn, output))
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  The programmatic buttons are
    %   fired through their ButtonPushedFcn directly.  Figure cleanup matches
    %   the dialog Tag 'lvd_EditE2TPriorityGUI'.
    %
    % COVERED
    %   Open shows stored priority/weight (blank weight for the NaN even
    %   split); Save writes priority and weight; a blank weight saves as NaN
    %   (even split); a non-finite priority and a non-positive weight are
    %   rejected and leave the connection alone; Cancel preserves the
    %   connection.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredPriorityAndWeight(testCase)
            [conn] = testCase.fixture();
            conn.priority = 2;
            conn.flowWeight = 0.5;

            app = testCase.openDialog(conn);

            testCase.verifyEqual(app.PriorityText.Value, '2');
            testCase.verifyEqual(app.WeightText.Value, '0.5');
            testCase.verifyTrue(contains(app.TitleLabel.Text, conn.getName()), ...
                'The title must name the edited connection.');
            testCase.verifyTrue(startsWith(app.UIFigure.Name, 'Edit Flow Priority'), ...
                'The figure must carry the Edit Flow Priority name.');
        end

        function blankWeightShowsEmptyForEvenSplit(testCase)
            [conn] = testCase.fixture();
            testCase.assertTrue(isnan(conn.flowWeight), 'Fixture: the default weight must be NaN (even).');

            app = testCase.openDialog(conn);

            testCase.verifyEqual(app.WeightText.Value, '', ...
                'A NaN (even-split) weight must show blank.');
        end

        function saveWritesPriorityAndWeight(testCase)
            [conn] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(conn, out);
            fig = app.UIFigure;

            app.PriorityText.Value = '3';
            app.WeightText.Value = '0.25';
            testCase.pushButton(app.SaveCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save must close the dialog.');
            testCase.verifyEqual(conn.priority, 3);
            testCase.verifyEqual(conn.flowWeight, 0.25, 'AbsTol', 1e-12);
        end

        function blankWeightSavesAsEvenSplit(testCase)
            [conn] = testCase.fixture();
            conn.flowWeight = 3;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(conn, out);

            app.PriorityText.Value = '0';
            app.WeightText.Value = '';
            testCase.pushButton(app.SaveCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save must report success.');
            testCase.verifyTrue(isnan(conn.flowWeight), 'A blank weight must save as NaN (even).');
            testCase.verifyEqual(conn.getEffectiveWeight(), 1, 'A blank weight must resolve to 1.');
        end

        function invalidPriorityIsRejected(testCase)
            [conn] = testCase.fixture();
            conn.priority = 2;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(conn, out);
            fig = app.UIFigure;

            app.PriorityText.Value = 'abc';
            app.WeightText.Value = '0.5';
            testCase.pushButton(app.SaveCloseButton);

            testCase.verifyFalse(out.output{1}, 'A non-numeric priority must not save.');
            testCase.verifyTrue(isvalid(fig), 'Failed validation must leave the dialog open.');
            testCase.verifyEqual(conn.priority, 2, 'Rejected input must leave the connection alone.');
            testCase.closeAlerts(fig);
        end

        function nonPositiveWeightIsRejected(testCase)
            [conn] = testCase.fixture();
            conn.flowWeight = 0.5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(conn, out);
            fig = app.UIFigure;

            app.PriorityText.Value = '1';
            app.WeightText.Value = '-4';
            testCase.pushButton(app.SaveCloseButton);

            testCase.verifyFalse(out.output{1}, 'A negative weight must not save.');
            testCase.verifyTrue(isvalid(fig), 'Failed validation must leave the dialog open.');

            app.WeightText.Value = '0';
            testCase.pushButton(app.SaveCloseButton);

            testCase.verifyFalse(out.output{1}, 'A zero weight must not save.');
            testCase.verifyTrue(isvalid(fig), 'Failed validation must leave the dialog open.');
            testCase.verifyEqual(conn.flowWeight, 0.5, 'AbsTol', 1e-12, ...
                'Rejected input must leave the connection alone.');
            testCase.closeAlerts(fig);
        end

        function cancelPreservesConnection(testCase)
            [conn] = testCase.fixture();
            conn.priority = 2;
            conn.flowWeight = 0.5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(conn, out);
            fig = app.UIFigure;

            app.PriorityText.Value = '9';
            app.WeightText.Value = '7';
            testCase.pushButton(app.CancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(conn.priority, 2, 'Cancel must leave the connection alone.');
            testCase.verifyEqual(conn.flowWeight, 0.5, 'AbsTol', 1e-12);
        end
    end

    methods(Access=private)
        function conn = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            conn = lvdData.launchVehicle.engineTankConns(1);
        end

        function app = openDialog(testCase, conn, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditE2TPriorityGUI_App(conn, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() E2TPriorityDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~, keepFig)
            %Compare by captured figure number: .Number on a figure that
            %died mid-sweep returns [] and breaks &&-chained comparisons.
            keepNum = [];
            if ~isempty(keepFig) && isvalid(keepFig)
                keepNum = keepFig.Number;
            end
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~isequal(figs(i).Number, keepNum)
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
            figs = findall(groot, 'Type', 'figure', 'Tag', 'lvd_EditE2TPriorityGUI');
            for i = 1:numel(figs)
                if isvalid(figs(i))
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
