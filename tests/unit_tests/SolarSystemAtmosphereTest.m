classdef SolarSystemAtmosphereTest < matlab.unittest.TestCase
    %SolarSystemAtmosphereTest Verifies the published-data atmosphere
    %models for the solar-system bodies in bodiesSolarSystem.ini
    %(Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto), anchored to
    %VIRA, MCD, Voyager/Galileo radio occultation profiles, and New
    %Horizons REX. Earth's USSA76 model is checked for regression.

    properties
        celBodyData
    end

    methods(TestClassSetup)
        function setupBodies(testCase)
            ksptotAddProjectPaths();
            root = ksptotTestRoot();
            [rawIni,~,~] = inifile(fullfile(root,'bodies_other','bodiesSolarSystem.ini'), 'readall');
            bi = processINIBodyInfo(rawIni, false, 'bodyInfo');
            testCase.celBodyData = CelestialBodyData(bi);
        end
    end

    methods(Test)
        function surfaceAnchorsMatchPublished(testCase)
            anchors = {
                'Venus',   735,  9210,   65.5
                'Mars',    224.7, 0.6523, 0.0152
                'Jupiter', 166.1, 100,    0.161
                'Saturn',  134.8, 100,    0.185
                'Uranus',  76.4,  100,    0.416
                'Neptune', 72,    100,    0.434
                'Pluto',   39,    0.00115, 9.9e-5
                'Triton',  38,    0.0014,  1.24e-4};
            for i = 1:size(anchors,1)
                b = testCase.getBody(anchors{i,1});
                [rho,P,T] = getAtmoDensityAtAltitude(b, 0, 0, 0, 0);
                testCase.verifyEqual(T, anchors{i,2}, 'RelTol', 0.01, [anchors{i,1} ' surface T']);
                testCase.verifyEqual(P, anchors{i,3}, 'RelTol', 0.01, [anchors{i,1} ' surface P']);
                testCase.verifyEqual(rho, anchors{i,4}, 'RelTol', 0.02, [anchors{i,1} ' surface density']);
            end
        end

        function altitudeAnchorsMatchPublished(testCase)
            checks = {
                'Venus',  50, 348, 106.6
                'Venus',  60, 263, 23.57
                'Mars',   21.18, 188.276, 0.0898169
                'Mars',   60, 139.695, 0.00084117
                'Jupiter', 44.54, 113.5, 10
                'Saturn', 106.39, 82.0, 6
                'Uranus', 49.08, 53, 10
                'Neptune', 39.32, 52, 10
                'Pluto',  30, 110, NaN
                'Triton', 40, 50.19, 1.163e-4};
            for i = 1:size(checks,1)
                b = testCase.getBody(checks{i,1});
                [~,P,T] = getAtmoDensityAtAltitude(b, checks{i,2}, 0, 0, 0);
                testCase.verifyEqual(T, checks{i,3}, 'RelTol', 0.02, [checks{i,1} ' T at anchor alt']);
                if(~isnan(checks{i,4}))
                    testCase.verifyEqual(P, checks{i,4}, 'RelTol', 0.02, [checks{i,1} ' P at anchor alt']);
                end
            end
        end

        function pressureDecreasesAndDensityVanishesAboveAtmohgt(testCase)
            names = {'Venus','Mars','Jupiter','Saturn','Uranus','Neptune','Pluto','Triton'};
            for k = 1:numel(names)
                b = testCase.getBody(names{k});
                Ps = zeros(1,50);
                for j = 1:50
                    [~,Ps(j),~] = getAtmoDensityAtAltitude(b, (j-1)/49*b.atmohgt, 0, 0, 0);
                end
                testCase.verifyTrue(all(diff(Ps) <= 1e-12), [names{k} ' pressure must be monotonic decreasing']);
                [r2,~,~] = getAtmoDensityAtAltitude(b, b.atmohgt+1, 0, 0, 0);
                testCase.verifyEqual(r2, 0, [names{k} ' density above atmohgt']);
                [r1,~,~] = getAtmoDensityAtAltitude(b, b.atmohgt-1, 0, 0, 0);
                testCase.verifyGreaterThan(r1, 0, [names{k} ' density just below atmohgt']);
            end
        end

        function giantsZeroAltitudeIsOneBarLevel(testCase)
            % At radius (altitude 0), giants sit at their 1-bar reference
            % level; verify T(0) and P(0)=100 kPa and the published
            % tropopause anchors.
            checks = {
                'Jupiter', 166.1, 44.54, 113.5
                'Saturn',  134.8, 106.39, 82.0
                'Uranus',  76.4,  49.08, 53
                'Neptune', 72,    39.32, 52};
            for i = 1:size(checks,1)
                b = testCase.getBody(checks{i,1});
                [~,P0,T0] = getAtmoDensityAtAltitude(b, 0, 0, 0, 0);
                testCase.verifyEqual(P0, 100, 'RelTol', 1e-6, [checks{i,1} ' P(0)=100 kPa']);
                testCase.verifyEqual(T0, checks{i,2}, 'RelTol', 0.01, [checks{i,1} ' T(0)']);
                [~,~,Tz] = getAtmoDensityAtAltitude(b, checks{i,3}, 0, 0, 0);
                testCase.verifyEqual(Tz, checks{i,4}, 'RelTol', 0.02, [checks{i,1} ' tropopause T']);
            end
        end

        function earthUSSA76Regression(testCase)
            % Earth's USSA76 model must still match the published standard.
            b = testCase.getBody('Earth');
            [rho,P,T] = getAtmoDensityAtAltitude(b, 0, 28.6, 0, -80.6);
            testCase.verifyEqual(rho, 1.225, 'RelTol', 0.01);
            testCase.verifyEqual(P, 101.325, 'RelTol', 0.01);
            testCase.verifyEqual(T, 288.15, 'RelTol', 0.01);
            [r2,~,~] = getAtmoDensityAtAltitude(b, 140.1, 28.6, 0, -80.6);
            testCase.verifyEqual(r2, 0);
        end
    end

    methods
        function b = getBody(testCase, name)
            bs = testCase.celBodyData.getAllBodyInfo();
            idx = find(arrayfun(@(b) strcmpi(b.name, name), bs), 1);
            b = bs(idx);
        end
    end
end
