classdef HaloConstructorDialogTest < KsptotTestCase
    %HaloConstructorDialogTest Pure-UI tests for the halo orbit constructor
    %(Phase 5: root/misc UIs; upgrades the main-GUI smoke press to a
    %value-level suite).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/lvd_HaloOrbitConstructor_App.mlapp
    %   ctor: lvd_HaloOrbitConstructor_App(celBodyData)
    %   main-GUI caller: haloOrbitConstructorMenu_Callback (Tools menu).
    %
    % PATTERN
    %   The constructor never blocks in uiwait and pops no native dialogs,
    %   so UiwaitInterceptorFixture is applied for uniformity only.  Only
    %   pure-UI state is driven (dropdown reselection, edit-field edits):
    %   ComputeHaloOrbitButton is ASSERTED TO EXIST BUT NEVER PRESSED,
    %   because it runs the differential corrector, manifold propagation,
    %   a modal progress dialog and alerts.  Dropdown edits rebuild only
    %   the cheap HaloOrbitApproximator parameters object.
    %
    % COVERED
    %   Open populates primary/secondary bodies, libration points and
    %   senses; changing the primary refreshes the secondaries; Z-amplitude
    %   and step-size edits round-trip; the Z field clamps at zero by
    %   control limits; solver/manifold defaults hold; the results tab and
    %   Compute button exist; close deletes the figure.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogOpensWithPopulatedSelectors(testCase)
            app = testCase.openDialog();

            testCase.verifyEqual(app.HaloOrbitConstructorUIFigure.Name, 'Halo Orbit Constructor');
            bodies = testCase.celBodyData.getAllBodiesWithChildren();
            testCase.verifyEqual(numel(app.PrimaryBodyDropDown.Items), numel(bodies), ...
                'Every body with children must be offered as primary.');
            testCase.verifyTrue(all(ismember(string(app.PrimaryBodyDropDown.Items), ...
                string({bodies.name}'))), 'Primary names must mirror the body data.');

            primary = app.PrimaryBodyDropDown.Value;
            [~, expNames] = primary.getChildrenBodyInfo(testCase.celBodyData);
            testCase.verifyEqual(numel(app.SecondaryBodyDropDown.Items), numel(expNames), ...
                'Secondaries must be the primary''s children.');
            testCase.verifyTrue(all(ismember(string(app.SecondaryBodyDropDown.Items), string(expNames))), ...
                'Secondary names must mirror the primary''s children.');

            testCase.verifyTrue(any(strcmp(app.LibrationPointDropDown.Items, 'L1')));
            testCase.verifyTrue(any(strcmp(app.LibrationPointDropDown.Items, 'L2')));
            testCase.verifyTrue(any(strcmp(app.SenseDropDown.Items, 'Northern')));
            testCase.verifyTrue(any(strcmp(app.SenseDropDown.Items, 'Southern')));
        end

        function changingPrimaryRefreshesSecondaries(testCase)
            app = testCase.openDialog();
            primaries = app.PrimaryBodyDropDown.ItemsData;
            testCase.assumeTrue(numel(primaries) >= 2, 'Fixture: need two parent bodies.');

            other = primaries(end);
            testCase.assumeTrue(~isequal(other, app.PrimaryBodyDropDown.Value), ...
                'Fixture: the last primary must differ from the default.');
            app.PrimaryBodyDropDown.Value = other;
            testCase.fireValueChanged(app.PrimaryBodyDropDown);

            [~, expNames] = other.getChildrenBodyInfo(testCase.celBodyData);
            testCase.verifyTrue(all(ismember(string(app.SecondaryBodyDropDown.Items), string(expNames))), ...
                'Reselecting the primary must refresh the secondaries.');
            testCase.verifyTrue(isvalid(app.HaloOrbitConstructorUIFigure), ...
                'Rebuilding the approximator must not break the dialog.');
        end

        function zAmplitudeEditRoundTrips(testCase)
            app = testCase.openDialog();

            app.ZAmplitudeEditField.Value = 2500;
            testCase.fireValueChanged(app.ZAmplitudeEditField);

            testCase.verifyEqual(app.ZAmplitudeEditField.Value, 2500, ...
                'The amplitude edit must persist without computing.');
            testCase.verifyTrue(isvalid(app.HaloOrbitConstructorUIFigure));
        end

        function zAmplitudeLimitsRejectNegatives(testCase)
            app = testCase.openDialog();

            testCase.verifyEqual(app.ZAmplitudeEditField.Limits, [0, Inf], ...
                'The Z amplitude is clamped at zero by the control itself.');
            testCase.verifyGreaterThanOrEqual(app.ZAmplitudeEditField.Value, 0);
        end

        function solverTuningControlsPersist(testCase)
            app = testCase.openDialog();

            testCase.verifyEqual(app.CoordinateToAdjustDropDown.Value, HaloCoordAdjustEnum.Z, ...
                'Z must be the default adjusted coordinate.');
            testCase.verifyEqual(app.ManifoldArriveDepartCombo.Value, ...
                HaloArriveDepartManifoldEnum.Arrive, 'Arrive must be the default manifold.');

            app.StepSizeFactorEditField.Value = 0.5;
            testCase.fireValueChanged(app.StepSizeFactorEditField);
            testCase.verifyEqual(app.StepSizeFactorEditField.Value, 0.5, ...
                'The step-size edit must persist without computing.');
        end

        function computeButtonExistsButIsNeverPressed(testCase)
            app = testCase.openDialog();

            testCase.verifyTrue(isa(app.ComputeHaloOrbitButton, 'matlab.ui.control.Button'), ...
                'Compute must be wired (it is never pressed: corrector + propagation).');
            testCase.verifyTrue(isvalid(app.ConstructHaloOrbitTab));
            testCase.verifyTrue(isvalid(app.ResultsTab));
            testCase.verifyTrue(isvalid(app.XPositionEditField));
            testCase.verifyTrue(isvalid(app.PeriodEditField));
            testCase.verifyTrue(isvalid(app.DispAxes));
        end

        function closeDeletesFigure(testCase)
            app = testCase.openDialog();
            fig = app.HaloOrbitConstructorUIFigure;

            delete(app);

            testCase.verifyFalse(isvalid(fig), 'Closing must delete the constructor figure.');
        end
    end

    methods(Access=private)
        function app = openDialog(testCase)
            app = lvd_HaloOrbitConstructor_App(testCase.celBodyData);
            drawnow;
            testCase.assertTrue(~isempty(app) && isvalid(app.HaloOrbitConstructorUIFigure), ...
                'The dialog constructor returned nothing.');
            testCase.addTeardown(@() HaloConstructorDialogTest.deleteIfValid(app));
        end

        function fireValueChanged(~, ctrl)
            evt = struct('Source', ctrl, 'EventName', 'ValueChanged');
            ctrl.ValueChangedFcn(ctrl, evt);
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Halo Orbit Constructor')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
