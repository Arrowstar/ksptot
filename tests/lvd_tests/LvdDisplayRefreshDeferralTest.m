classdef LvdDisplayRefreshDeferralTest < matlab.uitest.TestCase
    %LvdDisplayRefreshDeferralTest The display refresh's skipped work must
    %come back when it is needed (probe10 speedups):
    %  * a ground track on a hidden tab is drawn when the tab is selected
    %  * the disabled-ground-track placeholder is not rebuilt every refresh
    %  * the camera write-back suppression is released after the restore,
    %    so the user's own camera moves are still recorded

    properties(Access = private)
        celBodyData
        stubMainFig
        figuresBefore
        fixture UiwaitInterceptorFixture
    end

    methods(TestClassSetup)
        function setUpEnvironment(testCase)
            ksptotAddProjectPaths();
            testCase.celBodyData = ksptotTestBodyData();

            global GLOBAL_AppThemer %#ok<GVMIS>
            if(isempty(GLOBAL_AppThemer) || not(isvalid(GLOBAL_AppThemer)))
                GLOBAL_AppThemer = AppThemer();
            end

            global ksptot_TimeSystem options_UseEarthTimeSystem %#ok<GVMIS>
            if(isempty(ksptot_TimeSystem))
                [rawIni, ~, ~] = inifile(fullfile(ksptotTestRoot(), 'bodies.ini'), 'readall');
                ksptot_TimeSystem = getTimeSystemFromConfig(getAppOptionsFromFile(), rawIni);
                options_UseEarthTimeSystem = strcmpi(ksptot_TimeSystem.system, 'earth_stock');
            end
        end
    end

    methods(TestMethodSetup)
        function interceptUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
            testCase.figuresBefore = findall(groot, 'Type', 'figure');
            testCase.addTeardown(@() testCase.closeNewFigures());
        end
    end

    methods(Test)
        function hiddenGroundTrackIsDrawnWhenItsTabIsSelected(testCase)
            app = testCase.openLvd();
            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData');
            profile = lvdData.viewSettings.selViewProfile;
            profile.showGrdTrk = true;

            testCase.choose(app.DTrajectoryTab);
            app.lvdEnhancementsRefresh(true);

            testCase.verifyTrue(isappdata(app.GroundTrackAxes, 'lvdGrdTrkStale'), ...
                'A refresh with the ground-track tab hidden must defer the ground track.');
            testCase.verifyEmpty(profile.vehicleGrdTrackData, ...
                'The deferred refresh must drop the old track''s markers.');

            testCase.choose(app.GroundTrackTab);

            testCase.verifyFalse(isappdata(app.GroundTrackAxes, 'lvdGrdTrkStale'));
            testCase.verifyNotEmpty(profile.vehicleGrdTrackData, ...
                'Selecting the tab must draw the deferred ground track.');
            testCase.verifyNotEmpty(findobj(app.GroundTrackAxes, 'Type', 'line'));

            %Refreshing while the tab is showing draws immediately.
            app.lvdEnhancementsRefresh(false);
            testCase.verifyFalse(isappdata(app.GroundTrackAxes, 'lvdGrdTrkStale'));
            testCase.verifyNotEmpty(profile.vehicleGrdTrackData);
        end

        function disabledGroundTrackPlaceholderIsKeptAcrossRefreshes(testCase)
            app = testCase.openLvd();
            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData');
            lvdData.viewSettings.selViewProfile.showGrdTrk = false;

            app.lvdEnhancementsRefresh(false);
            first = findobj(app.GroundTrackAxes, 'Tag', 'lvdGrdTrkPlaceholder');
            testCase.assertNumElements(first, 1);

            app.lvdEnhancementsRefresh(false);
            second = findobj(app.GroundTrackAxes, 'Tag', 'lvdGrdTrkPlaceholder');
            testCase.verifyNumElements(second, 1);
            testCase.verifyEqual(second, first, 'The placeholder must be reused, not rebuilt.');
        end

        function cameraWritebackResumesAfterTheRestore(testCase)
            app = testCase.openLvd();
            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData');
            profile = lvdData.viewSettings.selViewProfile;
            profile.updateViewAxesLimits = false;
            profile.cameraMode = LvdCameraModeEnum.Manual;

            app.lvdEnhancementsRefresh(false);
            testCase.verifyFalse(isappdata(app.dispAxes, 'lvdSuppressCameraWriteback'), ...
                'plotStateLog must release the camera write-back suppression.');

            %A camera change of the user's own is still recorded (km).
            sAx = LvdSceneNormalizer.getScale(app.dispAxes);
            newPos = 1.5 * app.dispAxes.CameraPosition;
            app.dispAxes.CameraPosition = newPos;
            testCase.verifyEqual(profile.viewCameraPosition, newPos/sAx, 'RelTol', 1e-12);
        end
    end

    methods(Access = private)
        function app = openLvd(testCase)
            testCase.stubMainFig = figure('Visible', 'off', 'Name', 'KSPTOT main window stub');
            testCase.addTeardown(@() deleteIfValid(testCase.stubMainFig));

            app = ma_LvdMainGUI_App(testCase.celBodyData, testCase.stubMainFig);
            testCase.addTeardown(@() deleteIfValid(app));
            drawnow;

            testCase.assertTrue(isvalid(app.ma_LvdMainGUI), 'The LVD main window must open.');
        end

        function closeNewFigures(testCase)
            figs = setdiff(findall(groot, 'Type', 'figure'), testCase.figuresBefore);
            delete(figs(isvalid(figs)));
        end
    end
end

function deleteIfValid(h)
    if(not(isempty(h)) && all(isvalid(h)))
        delete(h);
    end
end
