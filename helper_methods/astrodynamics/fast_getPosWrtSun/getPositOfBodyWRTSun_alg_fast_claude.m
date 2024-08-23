function [rVectB, vVectB] = getPositOfBodyWRTSun_alg_fast_claude(time, smas, eccs, incs, raans, args, means, epochs, parentGMs, rotFramesBodyToGI)
    %This function written with the help of Claude: https://claude.ai/chat/d0071dbd-3599-4d2a-884f-bfeeb07abde4
    numBodies = length(parentGMs);
    numTimes = length(time);
    
    % Precompute common values
    incs = deg2rad(incs);
    raans = deg2rad(raans);
    args = deg2rad(args);
    M0 = deg2rad(means);
    
    n = sqrt(parentGMs ./ smas.^3);
    
    % Handle both scalar and vector time inputs
    if numTimes == 1
        deltaT = time - epochs;
        M = M0 + n .* deltaT;
    else
        deltaT = time' - epochs;  % Transpose time to make it a column vector
        M = M0 + n .* deltaT;     % This will create a matrix: numBodies x numTimes
    end
    
    p = smas .* (1 - eccs.^2);
    sqrtMuOverP = sqrt(parentGMs ./ p);
    
    rVectB = zeros(3, numTimes);
    vVectB = zeros(3, numTimes);
    
    for i = 1:numBodies-1
        for j = 1:numTimes
            [rVect1, vVect1] = getStateAtTime_alg_fast(M(j,i), smas(i), eccs(i), incs(i), raans(i), args(i), p(i), sqrtMuOverP(i));
            
            R_BodyInertialFrame_to_GlobalInertial = rotFramesBodyToGI(:,:,i+1);

            rVect2 = R_BodyInertialFrame_to_GlobalInertial * rVect1;
            vVect2 = R_BodyInertialFrame_to_GlobalInertial * vVect1;
            
            rVectB(:,j) = rVectB(:,j) + rVect2;
            vVectB(:,j) = vVectB(:,j) + vVect2;
        end
    end
end

function [rVect, vVect] = getStateAtTime_alg_fast(M, sma, ecc, inc, raan, arg, p, sqrtMuOverP)
    tru = computeTrueAnomFromMean(M, ecc);
    if isnan(tru)
        fprintf('NaN tru detected. M: %f, ecc: %f\n', M, ecc);
    end
    [rVect, vVect] = getStatefromKepler_Alg(sma, ecc, inc, raan, arg, tru, p, sqrtMuOverP);
end

function tru = computeTrueAnomFromMean(M, ecc)
    if ecc < 1.0
        E = keplerEq(M, ecc);
        tru = computeTrueAnomFromEccAnom(E, ecc);
    else
        H = keplerEqHyp(M, ecc);
        tru = computeTrueAnomFromHypAnom(H, ecc);
    end
end

function E = keplerEq(M, e)
    tol = 1E-12;
    E = M;
    for i = 1:50  % Increased max iterations
        E_next = E - (E - e * sin(E) - M) / (1 - e * cos(E));
        if abs(E_next - E) <= tol
            E = E_next;
            return;
        end
        E = E_next;
    end
    fprintf('Warning: keplerEq did not converge. M: %f, e: %f\n', M, e);
end

function H = keplerEqHyp(M, e)
    tol = 1E-12;
    if e < 1.6
        if (-pi < M && M < 0) || M > pi
            H = M - e;
        else
            H = M + e;
        end
    elseif e < 3.6 && abs(M) > pi
        H = M - sign(M) * e;
    else
        H = M / (e - 1);
    end
    
    for i = 1:50  % Increased max iterations
        H_next = H + (M - e * sinh(H) + H) / (e * cosh(H) - 1);
        if abs(H_next - H) <= tol
            H = H_next;
            return;
        end
        H = H_next;
    end
    fprintf('Warning: keplerEqHyp did not converge. M: %f, e: %f\n', M, e);
end

function tru = computeTrueAnomFromEccAnom(E, ecc)
    tru = 2 * atan2(sqrt(1+ecc) * sin(E/2), sqrt(1-ecc) * cos(E/2));
end

function tru = computeTrueAnomFromHypAnom(H, ecc)
    tru = 2 * atan2(sqrt(ecc+1) * sinh(H/2), sqrt(ecc-1));
end

function [rVect, vVect] = getStatefromKepler_Alg(sma, ecc, inc, raan, arg, tru, p, sqrtMuOverP)
    % Special cases
    if ecc < 1E-10
        if inc < 1E-10 || abs(inc-pi) < 1E-10
            tru = mod(raan + arg + tru, 2*pi);
            raan = 0;
            arg = 0;
        else
            tru = mod(arg + tru, 2*pi);
            arg = 0;
        end
    elseif inc < 1E-10 || abs(inc-pi) < 1E-10
        raan = 0;
    end

    r = p / (1 + ecc * cos(tru));
    
    rPQW = [r * cos(tru); r * sin(tru); 0];
    vPQW = sqrtMuOverP * [-sin(tru); ecc + cos(tru); 0];
    
    cos_raan = cos(raan); sin_raan = sin(raan);
    cos_arg = cos(arg); sin_arg = sin(arg);
    cos_inc = cos(inc); sin_inc = sin(inc);
    
    R11 = cos_raan * cos_arg - sin_raan * sin_arg * cos_inc;
    R12 = -cos_raan * sin_arg - sin_raan * cos_arg * cos_inc;
    R13 = sin_raan * sin_inc;
    R21 = sin_raan * cos_arg + cos_raan * sin_arg * cos_inc;
    R22 = -sin_raan * sin_arg + cos_raan * cos_arg * cos_inc;
    R23 = -cos_raan * sin_inc;
    R31 = sin_arg * sin_inc;
    R32 = cos_arg * sin_inc;
    R33 = cos_inc;
    
    rVect = [R11 * rPQW(1) + R12 * rPQW(2) + R13 * rPQW(3);
             R21 * rPQW(1) + R22 * rPQW(2) + R23 * rPQW(3);
             R31 * rPQW(1) + R32 * rPQW(2) + R33 * rPQW(3)];
    
    vVect = [R11 * vPQW(1) + R12 * vPQW(2) + R13 * vPQW(3);
             R21 * vPQW(1) + R22 * vPQW(2) + R23 * vPQW(3);
             R31 * vPQW(1) + R32 * vPQW(2) + R33 * vPQW(3)];
end