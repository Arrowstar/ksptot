classdef ExportEphemerisDialogTest < KsptotTestCase
    %ExportEphemerisDialogTest Full round-trip UI tests for the ephemeris
    %export dialog (Phase 5: root/misc UIs).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/lvd_ExportEphemerisGUI_App.m
    %   (programmatic uifigure dialog, NOT a .mlapp; ctor is (lvdData))
    %   function twin: lvd_exportEphemeris (covered by EphemerisExportTest).
    %   main-GUI caller: ExportEphemerisMenuSelected opens it on the File
    %   menu; the dialog itself picks CSV vs OEM, the reference frame, an
    %   optional resampling step, and the mass column, then asks uiputfile.
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live dialog object, and
    %   NativeDialogInterceptorFixture stubs uiputfile so no native file
    %   picker can hang "matlab -batch".  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct.
    %
    % COVERED
    %   Open shows CSV/OEM formats, a blank step, the default object name
    %   and the selected frame; Export writes a CSV file through the
    %   stubbed picker; cancelling the picker writes nothing; a bad step
    %   and an empty state log are rejected before any picker appears; an
    %   OEM export carries the CCSDS header; Cancel closes without writing.
    %   Entries are synthesized (no propagation).

    properties(Access=private)
        nativeFixture NativeDialogInterceptorFixture
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end

        function stubNativeDialogs(testCase)
            testCase.nativeFixture = testCase.applyFixture(NativeDialogInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsExportOptions(testCase)
            lvdData = testCase.fixture();
            app = testCase.openDialog(lvdData);

            expFormats = {'csv'; 'oem'};
            testCase.verifyEqual(sort(cellstr(app.formatCombo.ItemsData(:))), sort(expFormats(:)), ...
                'Both file formats must be offered.');
            testCase.verifyEqual(app.formatCombo.Value, 'csv', 'CSV must be the default.');
            testCase.verifyEqual(app.stepSizeText.Value, '', 'Raw (per-epoch) export must be the default.');
            testCase.verifyEqual(app.objectNameText.Value, 'LVD Vehicle');
            testCase.verifyFalse(isempty(app.FrameSelector.getSelectedFrame()), ...
                'A reference frame must be preselected.');
            testCase.verifyEqual(app.UIFigure.Name, 'Export Ephemeris');
        end

        function exportWritesCsvFile(testCase)
            lvdData = testCase.fixture();
            app = testCase.openDialog(lvdData);

            tmpDir = tempname(); mkdir(tmpDir);
            testCase.addTeardown(@() rmdir(tmpDir, 's'));
            csvFile = fullfile(tmpDir, 'dialog_export.csv');
            testCase.nativeFixture.setUiputfileSuccess(csvFile);

            testCase.pushButton(app.exportButton);

            testCase.verifyTrue(isfile(csvFile), 'Export must write the picked file.');
            testCase.verifyEqual(testCase.nativeFixture.calls().uiputfile, 1);
            M = readmatrix(csvFile);
            testCase.verifySize(M, [3, 8], 'Three synthetic entries must yield three rows.');
            testCase.verifyTrue(all(diff(M(:, 1)) > 0), 'Epochs must increase.');
            %NOTE: the success path ends in uialert, which materializes no
            %figure in headless/batch MATLAB (verified live), so there is no
            %alert to dismiss; the dialog stays open and the teardown reaps
            %it.  The file content above is the durable success signal.
            testCase.verifyTrue(isvalid(app.UIFigure), 'Success must leave the dialog open.');
        end

        function exportCancelAtFileDialogWritesNothing(testCase)
            lvdData = testCase.fixture();
            app = testCase.openDialog(lvdData);

            tmpDir = tempname(); mkdir(tmpDir);
            testCase.addTeardown(@() rmdir(tmpDir, 's'));
            testCase.nativeFixture.setUiputfileCancel();

            testCase.pushButton(app.exportButton);

            testCase.verifyEqual(testCase.nativeFixture.calls().uiputfile, 1, 'The picker must be asked.');
            testCase.verifyTrue(isvalid(app.UIFigure), 'Cancelling the picker must leave the dialog open.');
            testCase.verifyEmpty(dir(fullfile(tmpDir, '*.csv')), 'No file may be written on cancel.');
        end

        function invalidStepSizeIsRejected(testCase)
            lvdData = testCase.fixture();
            app = testCase.openDialog(lvdData);

            app.stepSizeText.Value = 'abc';
            testCase.pushButton(app.exportButton);

            testCase.verifyEqual(testCase.nativeFixture.calls().uiputfile, 0, ...
                'A bad step must never reach the file picker.');
            testCase.verifyTrue(isvalid(app.UIFigure), 'Failed validation must leave the dialog open.');
            testCase.closeAlerts();
        end

        function emptyStateLogIsRejected(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            testCase.pushButton(app.exportButton);

            testCase.verifyEqual(testCase.nativeFixture.calls().uiputfile, 0, ...
                'An empty state log must never reach the file picker.');
            testCase.verifyTrue(isvalid(app.UIFigure));
            testCase.closeAlerts();
        end

        function oemExportWritesCcsdsHeader(testCase)
            lvdData = testCase.fixture();
            app = testCase.openDialog(lvdData);

            tmpDir = tempname(); mkdir(tmpDir);
            testCase.addTeardown(@() rmdir(tmpDir, 's'));
            oemFile = fullfile(tmpDir, 'dialog_export.oem');
            testCase.nativeFixture.setUiputfileSuccess(oemFile);

            app.formatCombo.Value = 'oem';
            testCase.pushButton(app.exportButton);

            testCase.verifyTrue(isfile(oemFile), 'OEM export must write the picked file.');
            txt = fileread(oemFile);
            testCase.verifyTrue(contains(txt, 'CCSDS_OEM_VERS = 2.0'));
            testCase.verifyTrue(contains(txt, 'OBJECT_NAME = LVD Vehicle'));
            testCase.closeAlerts();
        end

        function cancelPreservesMission(testCase)
            lvdData = testCase.fixture();
            nEntries = lvdData.stateLog.getNumberOfEntries();
            app = testCase.openDialog(lvdData);
            %Capture the figure first: Cancel deletes the app object, so
            %touching app.UIFigure afterwards is invalid.
            fig = app.UIFigure;

            app.objectNameText.Value = 'Changed';
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(testCase.nativeFixture.calls().uiputfile, 0, 'Cancel must not ask for a file.');
            testCase.verifyEqual(lvdData.stateLog.getNumberOfEntries(), nEntries, ...
                'Cancel must leave the mission alone.');
        end
    end

    methods(Access=private)
        function lvdData = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt1 = lvdData.script.getEventForInd(1);
            evt2 = LaunchVehicleEvent.getDefaultEvent(lvdData.script);
            lvdData.script.addEvent(evt2);

            %Synthetic entries; nothing is propagated here.
            template = lvdData.initStateModel.getInitialStateLogEntry();
            e1 = template.deepCopy(); e1.event = evt1; e1.time = 0;
            e2 = template.deepCopy(); e2.event = evt1; e2.time = 10;
            e3 = template.deepCopy(); e3.event = evt2; e3.time = 20;
            lvdData.stateLog.appendStateLogEntries([e1, e2, e3]);
        end

        function app = openDialog(testCase, lvdData)
            app = lvd_ExportEphemerisGUI_App(lvdData);
            drawnow;
            testCase.assertTrue(~isempty(app) && isvalid(app.UIFigure), ...
                'The dialog constructor returned nothing.');
            testCase.addTeardown(@() ExportEphemerisDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Export Ephemeris')
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
            if ~isempty(app) && isvalid(app) && isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Export Ephemeris')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
