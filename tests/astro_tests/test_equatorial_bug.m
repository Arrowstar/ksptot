function test_repro_equatorial_bug()
    % Setup environment
    mu = 398600.4415;
    
    % Test Case 1: Prograde Equatorial (i=0) with RAAN and Arg
    % Should result in longitude of periapsis = 30 + 60 = 90 deg
    sma = 10000;
    ecc = 0.5;
    inc = 0;
    raan = deg2rad(30);
    arg = deg2rad(60);
    tru = 0; % At periapsis
    
    [r1, v1] = vect_getStatefromKepler_Alg(sma, ecc, inc, raan, arg, tru, mu);
    % Expected position at periapsis: [0; 10000*(1-0.5); 0] = [0; 5000; 0] (because long=90)
    % Actually, if long=90, r = [0; 5000; 0].
    fprintf('Prograde (i=0): r=[%f, %f, %f]\n', r1);
    
    % Test Case 2: Retrograde Equatorial (i=pi) with RAAN and Arg
    % sma must be negative for hyperbolic or positive for elliptical?
    % Let's use elliptical.
    inc_pi = pi;
    [r2, v2] = vect_getStatefromKepler_Alg(sma, ecc, inc_pi, raan, arg, tru, mu);
    fprintf('Retrograde (i=pi): r=[%f, %f, %f]\n', r2);
    
    % Verify against a known correct physical state by commenting out the normalization
    % Or just calculate what it SHOULD be.
    % If i=pi, Rz(raan)*Rx(pi)*Rz(arg)
    % For tru=0, rPQW = [5000; 0; 0]
    % rECI = Rz(raan) * [1 0 0; 0 -1 0; 0 0 -1] * Rz(arg) * [5000; 0; 0]
    % Rz(arg) * [5000; 0; 0] = [5000*cos(arg); 5000*sin(arg); 0]
    % Rx(pi) * [...] = [5000*cos(arg); -5000*sin(arg); 0]
    % Rz(raan) * [...] = [cos(raan)*5000*cos(arg) - sin(raan)*(-5000*sin(arg));
    %                     sin(raan)*5000*cos(arg) + cos(raan)*(-5000*sin(arg));
    %                     0]
    % rECI = [5000 * (cos(raan)cos(arg) + sin(raan)sin(arg));
    %         5000 * (sin(raan)cos(arg) - cos(raan)sin(arg));
    %         0]
    % rECI = [5000 * cos(raan - arg); 5000 * sin(raan - arg); 0]
    
    raan_val = 30;
    arg_val = 60;
    expected_r2 = [5000 * cos(deg2rad(raan_val - arg_val));
                  5000 * sin(deg2rad(raan_val - arg_val));
                  0];
                  
    fprintf('Expected Retrograde: r=[%f, %f, %f]\n', expected_r2);
    
    if norm(r2 - expected_r2) > 1e-6
        fprintf('BUG FOUND IN RETROGRADE EQUATORIAL!\n');
    else
        fprintf('Retrograde equatorial seems correct (matches expectation).\n');
    end
    
    % Now test "bad" vs "good" normalization
    % If the code does raan=0, arg=raan+arg:
    % r_err = [5000 * cos(0 - (raan+arg)); 5000 * sin(0 - (raan+arg)); 0]
    % r_err = [5000 * cos(raan+arg); -5000 * sin(raan+arg); 0]
    % Test Case 3: Circular Retrograde Equatorial (i=pi)
    % Should result in longitude = raan + arg + tru? Or raan - arg - tru?
    tru_val = deg2rad(90);
    [r3, v3] = vect_getStatefromKepler_Alg(sma, 0, inc_pi, raan, arg, tru_val, mu);
    fprintf('Circular Retrograde (i=pi): r=[%f, %f, %f]\n', r3);
    
    % In Case 2, r2 was [0, -5000, 0].
    % sma=10000, ecc=0.5, tru=0 => r=5000.
    % If raan=30, arg=60, then r should be at 90 deg? No, I calculated raan-arg.
    % Let's see what Case 3 produces.
end
