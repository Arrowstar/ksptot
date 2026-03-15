classdef test_keplerConsistency < matlab.unittest.TestCase
    % test_keplerConsistency Verifies consistency between vectorized and scalar state-from-Kepler algorithms
    
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
            % Note: getStatefromKepler_Alg might handle e=1 differently than vect_ version
            % if sma is Inf.
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
            % Vectorized Call
            % We use vect_getStatefromKepler_Alg (the M-file which might call MEX)
            % or call the MEX directly if we prefer. The user asked for vect_getStatefromKepler_Alg.
            [rVectV, vVectV] = vect_getStatefromKepler_Alg(sma, ecc, inc, raan, arg, tru, gmu);
            
            % Scalar Calls
            num = length(sma);
            rVectS = zeros(3, num);
            vVectS = zeros(3, num);
            for i = 1:num
                [r, v] = getStatefromKepler_Alg(sma(i), ecc(i), inc(i), raan(i), arg(i), tru(i), gmu(i));
                rVectS(:,i) = r;
                vVectS(:,i) = v;
            end
            
            % Compare
            testCase.verifyEqual(rVectV, rVectS, 'AbsTol', 1e-12, 'RelTol', 1e-12, ...
                sprintf('Position mismatch in regime. Vectors: \nVectorized: %s\nScalar: %s', mat2str(rVectV), mat2str(rVectS)));
            testCase.verifyEqual(vVectV, vVectS, 'AbsTol', 1e-12, 'RelTol', 1e-12, ...
                sprintf('Velocity mismatch in regime. Vectors: \nVectorized: %s\nScalar: %s', mat2str(vVectV), mat2str(vVectS)));
        end
    end
end
