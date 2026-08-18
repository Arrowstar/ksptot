function [fnoise, level, inform] = ecnoiseCore(fval)
%ECNOISECORE  Moré-Wild ECnoise estimate from equally spaced function samples.
%   [fnoise, level, inform] = adamnlopt.ecnoiseCore(fval) builds the
%   finite-difference table of the samples fval (taken at equally spaced points
%   along a line) and returns the estimated noise level fnoise, the per-level
%   estimates level, and a status code inform:
%     inform = 1  noise detected (fnoise valid),
%     inform = 2  spacing too small (differences vanish -> increase spacing),
%     inform = 3  spacing too large / inconclusive (decrease spacing).
%   This is the shared core used both by ESTIMATENOISE (scalar functions along a
%   random direction) and by EVALUATOR/CALIBRATESTEP (each constraint component
%   from a single set of vector samples).
%
%   Reference: J. J. Moré and S. M. Wild, "Estimating Computational Noise",
%   SIAM J. Sci. Comput. 33(3), 2011.
%
%   Inputs:
%     fval - nf-by-1 vector of function samples at equally spaced points.
%
%   Outputs:
%     fnoise - estimated noise level (0 when inform ~= 1).
%     level  - (nf-1)-by-1 per-difference-level noise estimates.
%     inform - status code (1 detected, 2 too small, 3 too large/inconclusive).
%
%   See also ESTIMATENOISE, EVALUATOR/CALIBRATESTEP.

fval  = fval(:);
nf    = numel(fval);
level = zeros(nf-1, 1);
dsgn  = false(nf-1, 1);
fnoise = 0;
gamma = 1.0;

% Range check: if the samples vary too much, the smooth trend dominates the
% low-order differences (spacing too large).
fmin = min(fval);  fmax = max(fval);
if (fmax - fmin) / max(max(abs(fmax), abs(fmin)), realmin) > 0.1
    inform = 3;  return;
end

% Successive-difference table, overwriting fval (Moré-Wild in-place scheme).
for j = 1:nf-1
    for i = 1:nf-j
        fval(i) = fval(i+1) - fval(i);
    end

    % Spacing too small: at the first level, half or more differences are zero.
    if j == 1 && sum(fval(1:nf-1) == 0) >= nf/2
        inform = 2;  return;
    end

    gamma = 0.5 * (j / (2*j - 1)) * gamma;
    level(j) = sqrt(gamma * mean(fval(1:nf-j).^2));

    emin = min(fval(1:nf-j));
    emax = max(fval(1:nf-j));
    if emin * emax < 0
        dsgn(j) = true;                     % sign changes -> noise-dominated
    end
end

% Noise level = first stable, sign-changing level (neighbours agree within 4x).
for k = 1:nf-3
    emin = min(level(k:k+2));
    emax = max(level(k:k+2));
    if emax <= 4*emin && dsgn(k)
        fnoise = level(k);
        inform = 1;  return;
    end
end

inform = 3;                                 % inconclusive -> treat as too large
end
