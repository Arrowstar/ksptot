function goldens = generateVrRotGoldens(outFile)
%GENERATEVRROTGOLDENS Capture golden vrrotvec/vrrotvec2mat outputs.
%   goldens = generateVrRotGoldens() builds a seeded set of inputs (random
%   plus adversarial edge cases) and records the outputs of the REAL
%   Simulink 3D Animation vrrotvec/vrrotvec2mat for bit-compatibility
%   testing after those functions were removed in R2026b.
%
%   goldens = generateVrRotGoldens(outFile) additionally saves the struct
%   to a .mat file. The stock fixture shipped with the repo was generated
%   with MATLAB R2024b:
%
%       fixture: tests/unit_tests/fixtures/vrrot_goldens_R2024b.mat
%
%   Regeneration requires a release where the toolbox functions still run
%   (R2026a or older) AND must not see the project replacements on the
%   path; the generator verifies this via which().
%
%   Fields of the returned/saved struct:
%       A, B      3-by-N input vector pairs (double)
%       Rs        N-by-4  vrrotvec outputs, one row per column pair
%       Ms        3-by-3-by-N vrrotvec2mat outputs
%       Asingle    3-by-K single-precision subset of inputs
%       Bsingle    3-by-K single-precision subset of inputs
%       Rsingle    K-by-4  vrrotvec outputs for the single subset
%       Msingle    3-by-3-by-K vrrotvec2mat outputs for the single subset
%       generatedIn  string identifying the generating release

%   KSPTOT project, 2025.

if(nargin < 1)
    outFile = '';
end

% --- guard: must be calling the real toolbox functions -----------------
wv = which('vrrotvec');
if(isempty(regexp(wv, 'toolbox.sl3d', 'once')))
    error('generateVrRotGoldens:shadowed', ...
        ['vrrotvec resolves to "%s", not the Simulink 3D Animation ' ...
         'toolbox. Remove the project replacement folders from the path ' ...
         '(restoredefaultpath; rehash) before regenerating goldens.'], wv);
end

% --- deterministic input set -------------------------------------------
rng(42);
N = 5000;
A = randn(3, N);
B = randn(3, N);

% adversarial cases:
%  exact parallel (unnormalized), exact antiparallel, two near-antiparallel
%  (+/-1e-16 perturbation), parallel scaled by 2, antiparallel scaled,
%  90-degree pair, mixed large/small scales, huge magnitudes, normalized
%  diagonal, just above epsilon threshold, mixed-sign near-antiparallel
pairSpecs = { ...
    [1;0;0],                [5;0;0];           % exact parallel
    [0;0;1],                [0;0;-7];          % exact antiparallel
    [1;0;0],                [-1; 1e-16; 0];    % near-antiparallel +
    [1;0;0],                [-1;-1e-16; 0];    % near-antiparallel -
    [1;2;3],                [2;4;6];           % parallel scaled
    [1;2;3],                [-2;-4;-6];        % antiparallel scaled
    [1;0;0],                [0;0;1];           % 90 degrees
    [1e7;0;0],              [0;1e-7;0];        % mixed scales
    [realmax/2;0;0],        [0;realmax/2;0];   % huge magnitudes
    [0.7071067811865476;0.7071067811865476;0], [0;1;0]; % unit diagonal
    [1e-11;0;0],            [0;1;0];           % just above epsilon
    [0.3;0.4;0.5],          [-0.5;-0.4;-0.3]}; % mixed-sign antiparallel
numSpecial = size(pairSpecs, 1);
specialA = zeros(3, numSpecial);
specialB = zeros(3, numSpecial);
for kS = 1:numSpecial
    specialA(:,kS) = pairSpecs{kS,1};
    specialB(:,kS) = pairSpecs{kS,2};
end

A = [A, specialA];
B = [B, specialB];
N = size(A, 2);  % total columns incl. specials

% --- record outputs -----------------------------------------------------
Rs   = zeros(N, 4);
Ms   = zeros(3, 3, N);
for k = 1:N
    rK = vrrotvec(A(:,k), B(:,k));
    Rs(k,:) = rK;
    Ms(:,:,k) = vrrotvec2mat(rK);
end

% single-precision behavior: parallel-scaled, 90-degree, just-above-epsilon
% tiny, and mixed-sign near-antiparallel pairs (the realmax/2 pair is
% excluded because converting it to single overflows to Inf)
singlePairIdx = [4 6 10 11];
Asingle = single(specialA(:, singlePairIdx));
Bsingle = single(specialB(:, singlePairIdx));
Rsingle = zeros(numel(singlePairIdx), 4, 'like', Asingle);
Msingle = zeros(3, 3, numel(singlePairIdx), 'like', Asingle);
for k = 1:numel(singlePairIdx)
    rK = vrrotvec(Asingle(:,k), Bsingle(:,k));
    Rsingle(k,:) = rK;
    Msingle(:,:,k) = vrrotvec2mat(rK);
end

goldens = struct();
goldens.A = A;
goldens.B = B;
goldens.Rs = Rs;
goldens.Ms = Ms;
goldens.Asingle = Asingle;
goldens.Bsingle = Bsingle;
goldens.Rsingle = Rsingle;
goldens.Msingle = Msingle;
goldens.generatedIn = version;

if(~isempty(outFile))
    save(outFile, '-struct', 'goldens');
    fprintf('Wrote goldens (%d double cases, 4 single cases) to %s\n', ...
        size(A,2), outFile);
end
end
