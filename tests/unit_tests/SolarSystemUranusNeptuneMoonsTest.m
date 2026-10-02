classdef SolarSystemUranusNeptuneMoonsTest < matlab.unittest.TestCase
    %SolarSystemUranusNeptuneMoonsTest Verifies the Tier-1 Uranus/Neptune
    %moons added to bodiesSolarSystem.ini (Ariel, Umbriel, Titania, Oberon,
    %Miranda, Triton) against their published sources.
    %
    %Ground truth:
    %  orbit  - JPL Horizons geometric osculating Keplerian elements @ JDTDB
    %           2451545.0 (J2000.0), ECLIPJ2000, planet-centered
    %           (targets 701-705 center 799; 801 center 899)
    %  gm     - NAIF gm_de431.tpc DE431 ASTRO-VALUES BODY70x_GM / BODY801_GM
    %  radius - Horizons satellite physical-properties header (Ariel/Miranda
    %           are means of their triaxial radii)
    %  rot    - NAIF pck00011.tpc IAU PM model (W0 + rate); axes from
    %           cspice_pxform('IAU_<BODY>','ECLIPJ2000',0). Cross-checked by
    %           SolarSystemRotationPckTest when MICE is available.
    %  atmo   - airless Uranian moons (Voyager 2, Smith et al. 1986
    %           Science 233:43); Triton N2 model from Voyager 2 RSS
    %           (Tyler et al. 1989; Gurrola 1995) + Elliot et al. 2000 +
    %           Marques Oliveira et al. 2022 / Sicardy et al. 2024.

    properties
        celBodyData
        root
    end

    methods(TestClassSetup)
        function setupBodies(testCase)
            ksptotAddProjectPaths();
            testCase.root = ksptotTestRoot();
            [rawIni,~,~] = inifile(fullfile(testCase.root,'bodies_other','bodiesSolarSystem.ini'), 'readall');
            bi = processINIBodyInfo(rawIni, false, 'bodyInfo');
            testCase.celBodyData = CelestialBodyData(bi);
        end
    end

    methods(Test)
        function idsParentsAndNames(testCase)
            exp = {
                'Ariel',   701, 'Uranus',  799
                'Umbriel', 702, 'Uranus',  799
                'Titania', 703, 'Uranus',  799
                'Oberon',  704, 'Uranus',  799
                'Miranda', 705, 'Uranus',  799
                'Triton',  801, 'Neptune', 899};
            for i = 1:size(exp,1)
                b = testCase.getBody(exp{i,1});
                testCase.verifyEqual(b.id, exp{i,2}, [exp{i,1} ' id']);
                testCase.verifyEqual(b.parentid, exp{i,4}, [exp{i,1} ' parentID']);
                testCase.verifyEqual(char(b.name), exp{i,1}, [exp{i,1} ' name']);
                testCase.verifyEqual(b.epoch, 0, [exp{i,1} ' epoch']);
            end
        end

        function gmAndRadiusMatchPublished(testCase)
            % gm from gm_de431.tpc; radius = Horizons mean radius (km)
            exp = {
                'Ariel',   8.346344431770477E+01,  578.9
                'Umbriel', 8.509338094489388E+01,  584.7
                'Titania', 2.269437003741248E+02,  788.9
                'Oberon',  2.053234302535623E+02,  761.4
                'Miranda', 4.319516899232100E+00,  235.7
                'Triton',  1.427598140725034E+03, 1352.6};
            for i = 1:size(exp,1)
                b = testCase.getBody(exp{i,1});
                testCase.verifyEqual(b.gm, exp{i,2}, 'RelTol', 1e-9, [exp{i,1} ' gm']);
                testCase.verifyEqual(b.radius, exp{i,3}, 'RelTol', 1e-9, [exp{i,1} ' radius']);
            end
        end

        function orbitalElementsMatchHorizonsJ2000(testCase)
            % Columns: sma ecc inc raan arg mean (sma km, angles deg)
            exp = {
                'Ariel',   1.909413469791885E+05, 1.520812328868678E-03, 9.771931922807300E+01, 1.676455486422633E+02, 4.535674156751863E+01, 1.527943682479845E+02
                'Umbriel', 2.660121887486960E+05, 4.170165145635332E-03, 9.766606723745439E+01, 1.676381821495947E+02, 3.349516684490692E+02, 2.712233789529364E+02
                'Titania', 4.362926755951638E+05, 2.479000317146799E-03, 9.781836838381200E+01, 1.676178145945835E+02, 2.021167721066045E+02, 7.441677554285916E+01
                'Oberon',  5.835499440510160E+05, 5.523244847399845E-04, 9.787585296035932E+01, 1.677555265636234E+02, 2.540067252060520E+02, 9.349629094330373E+01
                'Miranda', 1.298717551017135E+05, 1.509798566639019E-03, 9.725415391960598E+01, 1.720875833032825E+02, 2.610221270814858E+02, 6.206189119864032E+01
                'Triton',  3.547660619253411E+05, 1.461079095879048E-04, 1.302614060073336E+02, 2.158591103702256E+02, 9.117138119399802E+01, 3.434606712122722E+02};
            for i = 1:size(exp,1)
                b = testCase.getBody(exp{i,1});
                testCase.verifyEqual(b.sma,  exp{i,2}, 'RelTol', 1e-6, [exp{i,1} ' sma']);
                testCase.verifyEqual(b.ecc,  exp{i,3}, 'RelTol', 1e-6, [exp{i,1} ' ecc']);
                testCase.verifyEqual(b.inc,  exp{i,4}, 'RelTol', 1e-9, [exp{i,1} ' inc']);
                testCase.verifyEqual(b.raan, exp{i,5}, 'RelTol', 1e-9, [exp{i,1} ' raan']);
                testCase.verifyEqual(b.arg,  exp{i,6}, 'RelTol', 1e-9, [exp{i,1} ' arg']);
                testCase.verifyEqual(b.mean, exp{i,7}, 'RelTol', 1e-9, [exp{i,1} ' mean']);
            end
        end

        function rotationValuesMatchPckModel(testCase)
            % rotini = BODY{id}_PM(1) (deg); rotperiod = 360/rate*86400 (s,
            % negative = retrograde). Axes are unit + mutually orthogonal.
            exp = {
                'Ariel',   156.22, -217760.7345
                'Umbriel', 108.05, -358056.8277
                'Titania',  77.74, -752186.7756
                'Oberon',    6.77, -1163223.243
                'Miranda',  30.70, -122124.6057
                'Triton',  296.53, -507760.1924};
            for i = 1:size(exp,1)
                b = testCase.getBody(exp{i,1});
                testCase.verifyEqual(b.rotini, exp{i,2}, 'AbsTol', 1e-9, [exp{i,1} ' rotini']);
                testCase.verifyEqual(b.rotperiod, exp{i,3}, 'RelTol', 1e-6, [exp{i,1} ' rotperiod']);
                testCase.verifyLessThan(b.rotperiod, 0, [exp{i,1} ' must be retrograde (negative)']);
                testCase.verifyEqual(norm(b.bodyxaxis), 1, 'RelTol', 1e-9, [exp{i,1} ' bodyxaxis unit']);
                testCase.verifyEqual(norm(b.bodyzaxis), 1, 'RelTol', 1e-9, [exp{i,1} ' bodyzaxis unit']);
                testCase.verifyLessThan(abs(dot(b.bodyxaxis, b.bodyzaxis)), 1e-9, [exp{i,1} ' axes orthogonal']);
            end
        end

        function flagsColorsAndTextures(testCase)
            files = struct('Ariel','arielSurface.jpg','Umbriel','umbrielSurface.jpg', ...
                'Titania','titaniaSurface.jpg','Oberon','oberonSurface.jpg', ...
                'Miranda','mirandaSurface.jpg','Triton','tritonSurface.jpg');
            names = fieldnames(files);
            for k = 1:numel(names)
                b = testCase.getBody(names{k});
                testCase.verifyEqual(char(b.bodycolor), 'winter', [names{k} ' bodycolor']);
                testCase.verifyEqual(b.canbecentral, 0, [names{k} ' canBeCentral']);
                testCase.verifyEqual(b.canbearrivedepart, 0, [names{k} ' canBeArriveDepart']);
                f = fullfile(testCase.root, 'images', 'body_textures', 'surface', files.(names{k}));
                testCase.verifyTrue(exist(f, 'file') == 2, [names{k} ' texture missing: ' f]);
                d = dir(f);
                testCase.verifyGreaterThan(d.bytes, 20000, [names{k} ' texture suspiciously small']);
            end
        end

        function airlessUranianMoonsHaveZeroAtmo(testCase)
            names = {'Ariel','Umbriel','Titania','Oberon','Miranda'};
            for k = 1:numel(names)
                b = testCase.getBody(names{k});
                testCase.verifyEqual(b.atmohgt, 0, [names{k} ' atmohgt']);
                testCase.verifyEqual(b.atmomolarmass, 0, [names{k} ' atmomolarmass']);
                [rho0, P0, ~] = getAtmoDensityAtAltitude(b, 0, 0, 0, 0);
                testCase.verifyEqual(rho0, 0, [names{k} ' surface density']);
                testCase.verifyEqual(P0, 0, [names{k} ' surface pressure']);
                [rhoHi, ~, ~] = getAtmoDensityAtAltitude(b, 10, 0, 0, 0);
                testCase.verifyEqual(rhoHi, 0, [names{k} ' density at 10 km']);
            end
        end

        function tritonAtmosphereAnchors(testCase)
            b = testCase.getBody('Triton');
            testCase.verifyEqual(b.atmohgt, 220, 'RelTol', 1e-9, 'Triton atmohgt');
            testCase.verifyEqual(b.atmomolarmass, 0.0280134, 'RelTol', 1e-6, 'Triton molar mass (N2)');
            [rho0, P0, T0] = getAtmoDensityAtAltitude(b, 0, 0, 0, 0);
            testCase.verifyEqual(T0, 38, 'RelTol', 0.01, 'Triton surface T');
            testCase.verifyEqual(P0, 0.0014, 'RelTol', 0.01, 'Triton surface P (kPa)');
            testCase.verifyEqual(rho0, 1.24e-4, 'RelTol', 0.02, 'Triton surface density');
            [~, P40, T40] = getAtmoDensityAtAltitude(b, 40, 0, 0, 0);
            testCase.verifyEqual(T40, 50.19, 'RelTol', 0.02, 'Triton T at 40 km');
            testCase.verifyEqual(P40, 1.163e-4, 'RelTol', 0.02, 'Triton P at 40 km (kPa)');
            [rhoTop, ~, ~] = getAtmoDensityAtAltitude(b, b.atmohgt - 1, 0, 0, 0);
            testCase.verifyGreaterThan(rhoTop, 0, 'Triton density just below atmohgt');
            [rhoAbove, ~, ~] = getAtmoDensityAtAltitude(b, b.atmohgt + 1, 0, 0, 0);
            testCase.verifyEqual(rhoAbove, 0, 'Triton density above atmohgt');
        end
    end

    methods
        function b = getBody(testCase, name)
            bs = testCase.celBodyData.getAllBodyInfo();
            idx = find(arrayfun(@(x) strcmpi(x.name, name), bs), 1);
            testCase.assertTrue(~isempty(idx), ['body not found in ini: ' name]);
            b = bs(idx);
        end
    end
end
