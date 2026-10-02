classdef SolarSystemRotationPckTest < matlab.unittest.TestCase
    %SolarSystemRotationPckTest Verifies the rotational data carried in
    %bodiesSolarSystem.ini against NAIF SPICE/MSOPCK ground truth.
    %
    %For every body, bodiesSolarSystem.ini carries
    %   bodyxaxis, bodyzaxis   : the IAU frame's x/z axes at J2000.0
    %                            in the Sun-Earth ecliptic frame
    %   rotini                 : the IAU prime-meridian angle W at J2000.0
    %   rotperiod              : sidereal rotation period [s]
    %Designed to be checked against cspice_pxform('IAU_<body>',
    %'ECLIPJ2000', et), with pole/nutation data from NAIF's pck00011.tpc
    %(Archinal et al. 2018, Celest. Mech. Dyn. Astr. 130:22).

    properties
        celBodyData
        spiceAvailable (1,1) logical = false
    end

    methods(TestClassSetup)
        function setupBodies(testCase)
            ksptotAddProjectPaths();
            root = ksptotTestRoot();
            [rawIni,~,~] = inifile(fullfile(root,'bodies_other','bodiesSolarSystem.ini'), 'readall');
            bi = processINIBodyInfo(rawIni, false, 'bodyInfo');
            testCase.celBodyData = CelestialBodyData(bi);

            % set up NAIF SPICE: kernels are vendored under tests/spice_kernels
            % (see tests/spice_kernels/README.txt); the MICE toolkit itself
            % lives at C:\spice (mex + cspice_*.m, not vendored)
            spiceKernelDir = fullfile(root,'tests','spice_kernels');
            kTl = fullfile(spiceKernelDir,'naif0012.tls');
            kPck = fullfile(spiceKernelDir,'pck00011.tpc');
            testCase.spiceAvailable = exist(kTl,'file')==2 && exist(kPck,'file')==2 ...
                && (exist(fullfile('C:\spice\mice\lib','mice.mexw64'),'file')~=0);
            if testCase.spiceAvailable
                addpath('C:\spice\mice\lib','C:\spice\mice\src\mice');
                cspice_furnsh(kTl);
                cspice_furnsh(kPck);
            end
        end
    end

    methods(TestClassTeardown)
        function unloadKernels(testCase)
            if testCase.spiceAvailable
                try
                    cspice_kclear;
                catch
                end
            end
        end
    end

    methods(Test)
        function axesMatchSpiceAtJ2000(testCase)
            % bodyxaxis / bodyzaxis must equal the IAU frame's x/z axes
            % expressed in ECLIPJ2000 at J2000.0
            testCase.assumeTrue(testCase.spiceAvailable, 'SPICE kernels not available');
            names = testCase.verifyBodyList();
            et = 0; % J2000.0 epoch in ET seconds
            for k = 1:numel(names)
                nm = names{k};
                b = testCase.getBody(nm);
                M = cspice_pxform(sprintf('IAU_%s', upper(nm)), 'ECLIPJ2000', et);
                xSpice = M(:,1); zSpice = M(:,3);
                angX = acosd(max(-1,min(1,dot(b.bodyxaxis/norm(b.bodyxaxis), xSpice))));
                angZ = acosd(max(-1,min(1,dot(b.bodyzaxis/norm(b.bodyzaxis), zSpice))));
                testCase.verifyLessThan(angX, 1e-5, [nm ' bodyxaxis mismatch (deg)']);
                testCase.verifyLessThan(angZ, 1e-5, [nm ' bodyzaxis mismatch (deg)']);
            end
        end

        function polesMatchSpiceAtVariousEpochs(testCase)
            % The spin pole (bodyzaxis, fixed in the ini) must track the SPICE pole.
            % Tolerance per body = the kernel's own nutation envelope
            %   (sum |NUT_PREC_RA| + sum |NUT_PREC_DEC|, a strict upper bound on the
            %   pole wobble; RA part conservatively unscaled by cos(dec))
            % plus secular pole-rate drift over the sweep window, plus 0.05 deg margin.
            % Bodies with big IAU nutation series (Phobos/Deimos/Mimas/Tethys/...)
            % legitimately wander by degrees, so their bound is degrees wide; the
            % J2000-exactness is covered by axesMatchSpiceAtJ2000 instead.
            testCase.assumeTrue(testCase.spiceAvailable, 'SPICE kernels not available');
            names = testCase.verifyBodyList();
            et = 0; % J2000.0 epoch in ET seconds
            offsDays = [0, 3652.5, -3652.5]; % sweep +-10 yr
            maxDtCy = max(abs(offsDays))/36525;
            for k = 1:numel(names)
                nm = names{k};
                b = testCase.getBody(nm);
                id = testCase.bodyId(nm);
                fz = b.bodyzaxis/norm(b.bodyzaxis);
                pra = cspice_gdpool(sprintf('BODY%d_POLE_RA', id), 1, 3);
                pde = cspice_gdpool(sprintf('BODY%d_POLE_DEC', id), 1, 3);
                [nra, fra] = cspice_gdpool(sprintf('BODY%d_NUT_PREC_RA', id), 1, 25);
                [nde, fde] = cspice_gdpool(sprintf('BODY%d_NUT_PREC_DEC', id), 1, 25);
                if ~fra, nra = 0; end
                if ~fde, nde = 0; end
                tol = sum(abs(nra)) + sum(abs(nde)) ...
                    + (abs(pra(2)) + abs(pde(2)))*maxDtCy + 0.05;
                for offs = offsDays %#ok<*NO4LP>
                    M = cspice_pxform(sprintf('IAU_%s', upper(nm)), 'ECLIPJ2000', et + offs*86400);
                    angZ = acosd(max(-1,min(1,dot(fz, M(:,3)))));
                    testCase.verifyLessThan(angZ, tol, sprintf('%s: pole drift %.0f d (tol %.2f)', nm, offs, tol));
                end
            end
        end

        function rotiniMatchesSpiceModelW0(testCase)
            % rotini must equal the PM W angle at J2000.0 of the pck model
            testCase.assumeTrue(testCase.spiceAvailable, 'SPICE kernels not available');
            names = testCase.verifyBodyList();
            for k = 1:numel(names)
                nm = names{k};
                b = testCase.getBody(nm);
                id = testCase.bodyId(nm);
                pm = cspice_gdpool(sprintf('BODY%d_PM', id), 1, 3);
                W0 = pm(1);
                e = mod(abs(b.rotini - W0) + 180, 360) - 180;
                testCase.verifyLessThan(abs(e), 1e-4, [nm ' rotini vs PM W0 mismatch']);
            end
        end

        function rotperiodMatchesPMRate(testCase)
            % rotperiod must equal the sidereal spin period of the pck PM rate:
            % T = 360 deg / |rate in deg/day|
            testCase.assumeTrue(testCase.spiceAvailable, 'SPICE kernels not available');
            names = testCase.verifyBodyList();
            for k = 1:numel(names)
                nm = names{k};
                b = testCase.getBody(nm);
                id = testCase.bodyId(nm);
                pm = cspice_gdpool(sprintf('BODY%d_PM', id), 1, 3);
                expectedSec = sign(pm(2)) * 360/abs(pm(2)) * 86400;
                testCase.verifyEqual(b.rotperiod, expectedSec, 'RelTol', 1e-2, [nm ' rotperiod']);
            end
        end
    end

    methods
        function names = verifyBodyList(testCase) %#ok<MANU>
            names = {'Mercury','Venus','Moon','Mars','Jupiter','Saturn','Uranus','Neptune','Pluto', ...
                     'Phobos','Deimos','Io','Europa','Ganymede','Callisto', ...
                     'Mimas','Enceladus','Tethys','Dione','Rhea','Titan','Iapetus', ...
                     'Ariel','Umbriel','Titania','Oberon','Miranda','Triton'};
        end

        function b = getBody(testCase, name)
            bs = testCase.celBodyData.getAllBodyInfo();
            idx = find(arrayfun(@(b) strcmpi(b.name, name), bs), 1);
            b = bs(idx);
        end

        function id = bodyId(testCase, name) %#ok<INUSD,MANU>
            ids = struct('Mercury',199,'Venus',299,'Moon',301,'Mars',499,'Jupiter',599, ...
                'Saturn',699,'Uranus',799,'Neptune',899,'Pluto',999,'Phobos',401,'Deimos',402, ...
                'Io',501,'Europa',502,'Ganymede',503,'Callisto',504,'Mimas',601,'Enceladus',602, ...
                'Tethys',603,'Dione',604,'Rhea',605,'Titan',606,'Iapetus',608, ...
                'Ariel',701,'Umbriel',702,'Titania',703,'Oberon',704,'Miranda',705,'Triton',801);
            id = ids.(name);
        end
    end
end

