function test_debug_parabola()
    body = KSPTOT_BodyInfo();
    body.gm = 398600.4415;
    body.radius = 6378.137;
    frame = body.getBodyCenteredInertialFrame();
    
    ut = 0;
    rP = 7000;
    c3 = 0; % Parabolic
    tau = 1000; % 1000 seconds past periapsis
    
    univ = UniversalElementSet(ut, c3, rP, 0, 0, 0, tau, frame);
    fprintf('Universal: rP=%0.1f, c3=%0.1f, tau=%0.1f\n', univ.rP, univ.c3, univ.tau);
    
    try
        kep = univ.convertToKeplerianElementSet();
        fprintf('Keplerian: sma=%e, ecc=%0.12f, tru=%e\n', kep.sma, kep.ecc, kep.tru);
        
        cart = kep.convertToCartesianElementSet();
        fprintf('Cartesian: r=[%e, %e, %e], v=[%e, %e, %e]\n', cart.rVect, cart.vVect);
        fprintf('Velocity magnitude: %e\n', norm(cart.vVect));
    catch ME
        fprintf('Error ID: %s\n', ME.identifier);
        fprintf('Error message: %s\n', ME.message);
        for i=1:length(ME.stack)
            fprintf('  File: %s, Name: %s, Line: %d\n', ME.stack(i).file, ME.stack(i).name, ME.stack(i).line);
        end
    end
end
