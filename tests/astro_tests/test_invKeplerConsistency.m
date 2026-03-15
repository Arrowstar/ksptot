classdef test_invKeplerConsistency < matlab.unittest.TestCase
    % test_invKeplerConsistency Verifies consistency between vectorized and scalar state-to-Kepler algorithms
    
    properties
        mu = 398600.4415;
    end
    
    methods(Test)
        function testEllipticalConsistency(testCase)
            % Test normal elliptical orbits
            sma = [7000, 10000, 15000];
            ecc = [0.1, 0.3, 0.5];
            inc = deg2rad([10, 20, 30]);
            raan = deg2rad([45, 90, 135]);
            arg = deg2rad([30, 60, 90]);
            tru = deg2rad([0, 90, 180]);
            gmu = testCase.mu * ones(size(sma));
            
            testCase.runConsistencyCheck(sma, ecc, inc, raan, arg, tru, gmu);
        end
        
        function testCircularConsistency(testCase)
            % Test circular orbits (e=0)
            sma = [7000, 10000];
            ecc = [0, 0];
            inc = deg2rad([10, 45]);
            raan = [0, 1];
            arg = [0, 1];
            tru = [1, 2];
            gmu = testCase.mu * ones(size(sma));
            
            testCase.runConsistencyCheck(sma, ecc, inc, raan, arg, tru, gmu);
        end
        
        function testEquatorialConsistency(testCase)
            % Test equatorial orbits (i=0 and i=pi)
            sma = [8000, 8000];
            ecc = [0.1, 0.1];
            inc = [0, pi];
            raan = [0.5, 0.5];
            arg = [0.6, 0.6];
            tru = [0.7, 0.7];
            gmu = testCase.mu * ones(size(sma));
            
            testCase.runConsistencyCheck(sma, ecc, inc, raan, arg, tru, gmu);
        end
        
        function testParabolicConsistency(testCase)
            % Test parabolic orbits (e=1)
            sma = [Inf, Inf];
            ecc = [1, 1];
            inc = [0.1, 0.5];
            raan = [0.2, 0.6];
            arg = [0.3, 0.7];
            tru = [0.4, 0.8];
            gmu = testCase.mu * ones(size(sma));
            
            testCase.runConsistencyCheck(sma, ecc, inc, raan, arg, tru, gmu);
        end
        
        function testHyperbolicConsistency(testCase)
            % Test hyperbolic orbits (e>1, sma<0)
            sma = [-10000, -20000];
            ecc = [1.2, 2.5];
            inc = [0.1, 0.8];
            raan = [0.2, 0.9];
            arg = [0.3, 1.0];
            tru = [0.4, 1.1];
            gmu = testCase.mu * ones(size(sma));
            
            testCase.runConsistencyCheck(sma, ecc, inc, raan, arg, tru, gmu);
        end
    end
    
    methods
        function runConsistencyCheck(testCase, sma, ecc, inc, raan, arg, tru, gmu)
            % 1. Convert Keplerian to State Vectors (using trusted vectorized forward conversion)
            [rVect, vVect] = vect_getStatefromKepler_Alg(sma, ecc, inc, raan, arg, tru, gmu);
            
            % 2. Vectorized Inverse Call
            [smaV, eccV, incV, raanV, argV, truV] = vect_getKeplerFromState_Alg(rVect, vVect, gmu);
            
            % 3. Scalar Inverse Calls
            num = length(sma);
            smaS = zeros(1, num);
            eccS = zeros(1, num);
            incS = zeros(1, num);
            raanS = zeros(1, num);
            argS = zeros(1, num);
            truS = zeros(1, num);
            
            for i = 1:num
                [s, e, in, rn, ar, tr] = getKeplerFromState_Alg(rVect(:,i), vVect(:,i), gmu(i));
                smaS(i) = s;
                eccS(i) = e;
                incS(i) = in;
                raanS(i) = rn;
                argS(i) = ar;
                truS(i) = tr;
            end
            
            % 4. Compare Vectorized vs Scalar
            % SMA can be Inf, so we use RelTol carefully or handle Inf
            tol = 1e-10;
            
            testCase.verifyEqual(smaV, smaS, 'AbsTol', tol, 'RelTol', tol, 'SMA mismatch');
            testCase.verifyEqual(eccV, eccS, 'AbsTol', tol, 'RelTol', tol, 'ECC mismatch');
            testCase.verifyEqual(incV, incS, 'AbsTol', tol, 'RelTol', tol, 'INC mismatch');
            testCase.verifyEqual(raanV, raanS, 'AbsTol', tol, 'RelTol', tol, 'RAAN mismatch');
            testCase.verifyEqual(argV, argS, 'AbsTol', tol, 'RelTol', tol, 'ARG mismatch');
            testCase.verifyEqual(truV, truS, 'AbsTol', tol, 'RelTol', tol, 'TRU mismatch');
        end
    end
end
