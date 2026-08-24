classdef VrRotVecCompatTest < KsptotTestCase
    %VrRotVecCompatTest Bit-compatibility of the vrrotvec/vrrotvec2mat
    %replacements with the Simulink 3D Animation functions removed in
    %MATLAB R2026b.
    %
    % Three independent layers of protection:
    %   1. Golden fixtures recorded from the real toolbox (R2024b) and
    %      checked in under unit_tests/fixtures.
    %   2. Verbatim reference ports of the original algorithm
    %      (vrrotvecReference / vrrotvec2matReference) compared against the
    %      production shims on large fuzzed input sets - this works on any
    %      MATLAB release, even where no toolbox copy exists.
    %   3. Batch functions proven bit-identical to the scalar replacements,
    %      so the performance rewrites cannot drift from the reference
    %      behavior.

    properties
        goldensPath
    end

    methods(TestClassSetup)
        function locateGoldens(testCase)
            thisDir = fileparts(mfilename('fullpath'));
            testCase.goldensPath = fullfile(thisDir, 'fixtures', 'vrrot_goldens_R2024b.mat');
            testCase.assertTrue(isfile(testCase.goldensPath), ...
                sprintf('Golden fixture missing: %s', testCase.goldensPath));
        end
    end

    methods(Test, ParameterCombination = 'sequential')
        %% ------------------------------------------------------ goldens
        function goldenVrRotVecBitwise(testCase)
            %Replacement vrrotvec must reproduce recorded toolbox outputs exactly.
            G = load(testCase.goldensPath);
            for k = 1:size(G.A, 2)
                rAct = vrrotvec(G.A(:,k), G.B(:,k));
                testCase.verifyEqual(rAct, G.Rs(k,:), ...
                    sprintf('column %d differs bitwise from R2024b toolbox output', k));
            end
        end

        function goldenVrRotVec2MatBitwise(testCase)
            %Replacement vrrotvec2mat must reproduce recorded toolbox outputs exactly.
            G = load(testCase.goldensPath);
            for k = 1:size(G.A, 2)
                mAct = vrrotvec2mat(G.Rs(k,:));
                testCase.verifyEqual(mAct, G.Ms(:,:,k), ...
                    sprintf('case %d differs bitwise from R2024b toolbox output', k));
            end
        end

        function goldenSinglePrecision(testCase)
            %Single inputs stay single and match toolbox single-precision results.
            G = load(testCase.goldensPath);
            for k = 1:size(G.Asingle, 2)
                rAct = vrrotvec(G.Asingle(:,k), G.Bsingle(:,k));
                testCase.verifyEqual(class(rAct), 'single', 'output class must follow input');
                testCase.verifyEqual(rAct, G.Rsingle(k,:));
                mAct = vrrotvec2mat(rAct);
                testCase.verifyEqual(mAct, G.Msingle(:,:,k));
            end
        end

        %% ------------------------------------------- reference fuzzing
        function referenceFuzzVrRotVec(testCase)
            %Shim must match the verbatim reference port bitwise on fuzzed inputs.
            rng(777);
            nPairs = 50000;
            A = randn(3, nPairs);
            B = randn(3, nPairs);
            [A, B] = testCase.appendSpecialCases(A, B);

            Rs   = zeros(size(A, 2), 4);
            Rref = zeros(size(A, 2), 4);
            for k = 1:size(A, 2)
                Rs(k,:)   = vrrotvec(A(:,k), B(:,k));
                Rref(k,:) = vrrotvecReference(A(:,k), B(:,k));
            end

            testCase.verifyBitwiseEqualBatch(Rs, Rref, 'fuzz: shim != reference');
        end

        function referenceFuzzVrRotVecWithEpsilon(testCase)
            %Non-default epsilon must flow through identically.
            rng(888);
            A = randn(3, 20000);
            B = randn(3, 20000);
            opts.epsilon = 1e-6;

            Rs   = zeros(size(A, 2), 4);
            Rref = zeros(size(A, 2), 4);
            for k = 1:size(A, 2)
                Rs(k,:)   = vrrotvec(A(:,k), B(:,k), opts);
                Rref(k,:) = vrrotvecReference(A(:,k), B(:,k), opts);
            end

            testCase.verifyBitwiseEqualBatch(Rs, Rref, 'epsilon fuzz: shim != reference');
        end

        function referenceFuzzVrRotVec2Mat(testCase)
            %Shim vrrotvec2mat must match the verbatim reference bitwise.
            rng(999);
            nCases = 20000;
            % random axis-angle rotations incl. tiny angles and axes of all sizes
            ax = randn(3, nCases);
            ang = (rand(1, nCases) * 2 - 1) .* pi;
            scales = 10 .^ (rand(1, nCases) * 8 - 4);   % 1e-4 .. 1e4 axis magnitudes
            R = [ax .* scales; ang];

            Ms   = zeros(3, 3, size(R, 2));
            Mref = zeros(3, 3, size(R, 2));
            for k = 1:size(R, 2)
                Ms(:,:,k)   = vrrotvec2mat(R(:,k));
                Mref(:,:,k) = vrrotvec2matReference(R(:,k));
            end

            testCase.verifyBitwiseEqualBatch(Ms, Mref, 'fuzz: shim != reference');
        end

        %% ------------------------------------------ batch equivalence
        function batchMatchesScalarBitwise(testCase)
            %vrrotvecBatch rows must be bit-identical to scalar vrrotvec calls.
            rng(111);
            A = randn(3, 30000);
            B = randn(3, 30000);
            [A, B] = testCase.appendSpecialCases(A, B);

            batch = vrrotvecBatch(A, B);

            expected = zeros(size(A, 2), 4);
            for k = 1:size(A, 2)
                expected(k,:) = vrrotvec(A(:,k), B(:,k));
            end

            testCase.verifyBitwiseEqualBatch(batch, expected, ...
                'vrrotvecBatch is not bit-identical to scalar vrrotvec');
        end

        function batchMatchesScalarWithEpsilon(testCase)
            %Batch honors epsilon identically to scalar with options struct.
            rng(222);
            A = randn(3, 5000);
            B = randn(3, 5000);
            % keep only columns valid under the large epsilon (norm > 0.5)
            valid = sqrt(sum(A.^2,1)) > 0.6 & sqrt(sum(B.^2,1)) > 0.6;
            A = A(:,valid);
            B = B(:,valid);
            batch = vrrotvecBatch(A, B, 0.5);

            expected = zeros(size(A, 2), 4);
            for k = 1:size(A, 2)
                expected(k,:) = vrrotvec(A(:,k), B(:,k), struct('epsilon', 0.5));
            end

            testCase.verifyBitwiseEqualBatch(batch, expected, ...
                'batch epsilon handling differs from scalar');
        end

        function batch2MatMatchesScalarBitwise(testCase)
            %vrrotvec2matBatch pages must be bit-identical to scalar calls.
            rng(333);
            nCases = 10000;
            ax = randn(3, nCases);
            ang = (rand(1, nCases)) .* 2*pi;
            Rrows = [ax; ang].';          % N-by-4

            Mbatch = vrrotvec2matBatch(Rrows);

            Mscalar = zeros(3, 3, nCases);
            for k = 1:nCases
                Mscalar(:,:,k) = vrrotvec2mat(Rrows(k,:));
            end

            testCase.verifyBitwiseEqualBatch(Mbatch, Mscalar, ...
                'vrrotvec2matBatch pages are not bit-identical to scalar calls');
        end

        function batch2MatAcceptsFourByN(testCase)
            %4-by-N columns are accepted and give identical pages.
            rng(444);
            Rcols = randn(4, 2500);
            Rcols(4,:) = Rcols(4,:) .* pi;
            MfromCols = vrrotvec2matBatch(Rcols);
            MfromRows = vrrotvec2matBatch(Rcols.');
            testCase.verifyEqual(MfromCols, MfromRows, '4xN and Nx4 must agree');
            for k = 1:size(Rcols, 2)
                testCase.verifyEqual(MfromCols(:,:,k), vrrotvec2mat(Rcols(:,k)));
            end
        end

        function batchPreservesInputClass(testCase)
            %Single-precision batches return single-precision results.
            rng(555);
            A = single(randn(3, 100));
            B = single(randn(3, 100));
            batch = vrrotvecBatch(A, B);
            testCase.verifyEqual(class(batch), 'single');

            R = single([randn(3, 50); rand(1, 50)*pi]);
            M = vrrotvec2matBatch(R);
            testCase.verifyEqual(class(M), 'single');
        end

        function batchRejectsMismatchedSizes(testCase)
            testCase.verifyError(@() vrrotvecBatch(rand(3,5), rand(3,6)), ...
                'sl3d:vrdirorirot:argbaddim');
            testCase.verifyError(@() vrrotvecBatch(rand(2,5), rand(2,5)), ...
                'sl3d:vrdirorirot:argbaddim');
        end

        function batchErrorsOnZeroMagnitudeColumn(testCase)
            A = [1 0 0; 0 0 0; 0 0 1];
            B = [0 1 0; 1 0 0; 0 0 1];
            testCase.verifyError(@() vrrotvecBatch(A, B), ...
                'sl3d:vrdirorirot:argzeromagnitude');
        end

        %% --------------------------------------------------- edge cases
        function parallelVectorsGiveZeroAngle(testCase)
            %Exactly parallel vectors: angle 0, axis perpendicular to a.
            a = [1;2;3];
            r = vrrotvec(a, 2*a);
            testCase.verifyEqual(r(4), acos(min(dot(a/norm(a), (2*a)/norm(2*a)), 1)), ...
                'angle must equal the documented acos(dot) computation');
            testCase.verifyEqual(size(r), [1 4], 'result must be a row vector');
            % cross-product fallback axis must be perpendicular to an
            an = a / norm(a);
            testCase.verifyLessThan(abs(dot(r(1:3)', an)), 1e-12, ...
                'fallback axis must be orthogonal to the normalized input');
        end

        function antiParallelVectorsGivePiAngle(testCase)
            %Antiparallel vectors: angle pi, axis perpendicular to a.
            a = [1;2;3];
            r = vrrotvec(a, -a);
            testCase.verifyEqual(r(4), pi, 'antiparallel rotation angle must be pi');
            an = a / norm(a);
            testCase.verifyLessThan(abs(dot(r(1:3)', an)), 1e-12, ...
                'fallback axis must be orthogonal to the normalized input');
            testCase.verifyEqual(norm(r(1:3)), 1, 'axis must be unit length');
        end

        function nearAntiParallelStaysNumericallyStable(testCase)
            %Tiny perturbations off exact antiparallel must not flip behavior.
            rPlus  = vrrotvec([1;0;0], [-1; 1e-16; 0]);
            rMinus = vrrotvec([1;0;0], [-1;-1e-16; 0]);
            testCase.verifyEqual(rPlus(4), pi, '+perturbed angle must still be pi');
            testCase.verifyEqual(rMinus(4), pi, '-perturbed angle must still be pi');
            % and both must agree with the reference implementation bitwise
            testCase.verifyEqual(rPlus,  vrrotvecReference([1;0;0], [-1; 1e-16; 0]));
            testCase.verifyEqual(rMinus, vrrotvecReference([1;0;0], [-1;-1e-16; 0]));
        end

        function zeroMagnitudeRaisesExactError(testCase)
            %Below-epsilon magnitudes raise the original error ID and text.
            try
                vrrotvec([0;0;0], [0;1;0]);
                testCase.verifyFail('expected error for zero-magnitude vector');
            catch ME
                testCase.verifyEqual(ME.identifier, 'sl3d:vrdirorirot:argzeromagnitude');
                testCase.verifyEqual(ME.message, 'Input argument has zero magnitude.');
            end
            try
                vrrotvec([1;2;3]*1e-13, [0;1;0]);
                testCase.verifyFail('expected error for below-epsilon vector');
            catch ME
                testCase.verifyEqual(ME.identifier, 'sl3d:vrdirorirot:argzeromagnitude');
                testCase.verifyEqual(ME.message, 'Input argument has zero magnitude.');
            end
            % note: vrrotvec2mat does NOT raise argzeromagnitude for a zero
            % axis - the original treats it as a scaled identity matrix;
            % document that behavior and pin it to the reference
            testCase.verifyEqual(vrrotvec2mat([0;0;0;1]), ...
                vrrotvec2matReference([0;0;0;1]), ...
                'zero axis must match reference (scaled identity)');
        end

        function epsilonOptionAcceptsTinyVectors(testCase)
            %A smaller epsilon option makes below-default vectors valid.
            opts.epsilon = 1e-14;
            r = vrrotvec([1e-13;0;0], [0;1;0], opts);
            testCase.verifyEqual(r, vrrotvecReference([1e-13;0;0], [0;1;0], opts), ...
                'epsilon handling must match reference bitwise');
        end

        function dimensionAndTypeErrorsMatchOriginal(testCase)
            %Validation errors reproduce the removed functions' IDs and texts.
            wrongDimFcn  = @() vrrotvec([1;0], [0;1;0]);
            complexFcn   = @() vrrotvec(1+2i, [0;1;0]);
            badOptsField = @() vrrotvec([1;0;0], [0;1;0], struct('bad', 1));
            badOptsValue = @() vrrotvec([1;0;0], [0;1;0], struct('epsilon', 'x'));
            badOptsType  = @() vrrotvec([1;0;0], [0;1;0], 7);

            testCase.verifyError(wrongDimFcn,  'sl3d:vrdirorirot:argbaddim');
            testCase.verifyError(complexFcn,   'sl3d:vrdirorirot:argnotreal');
            testCase.verifyError(badOptsField, 'sl3d:vrdirorirot:optsfieldnameinvalid');
            testCase.verifyError(badOptsValue, 'sl3d:vrdirorirot:optsfieldvalueinvalid');
            testCase.verifyError(badOptsType,  'sl3d:vrdirorirot:optsnotstruct');

            matWrongDim = @() vrrotvec2mat([1;0;0;0;0]);
            matNotReal  = @() vrrotvec2mat([1;0;0;1i]);

            testCase.verifyError(matWrongDim, 'sl3d:vrdirorirot:argbaddim');
            testCase.verifyError(matNotReal,  'sl3d:vrdirorirot:argnotreal');
        end

        function rowAndColumnInputsAccepted(testCase)
            %Row vectors, columns, and mixed orientations all produce the
            %same 1-by-4 result (documented tolerance of the original).
            aCol = [1;2;3]; bCol = [-2;-4;-6];  % antiparallel
            aRow = aCol.';  bRow = bCol.';

            rCC = vrrotvec(aCol, bCol);
            rRR = vrrotvec(aRow, bRow);
            rRC = vrrotvec(aRow, bCol);
            testCase.verifyEqual(rRR, rCC, 'row/row must match col/col');
            testCase.verifyEqual(rRC, rCC, 'row/col must match col/col');

            % mixed orientations also match the reference implementation
            testCase.verifyEqual(rRC, vrrotvecReference(aRow, bCol));
        end

        function noDeprecationOrRemovalWarningsEmitted(testCase)
            %The shims must be silent (the originals warned about removal).
            lastwarn('');
            vrrotvec([1;2;3], [3;2;1]);
            vrrotvec2mat([0 0 1 pi/2]);
            vrrotvecBatch([1 0; 0 1; 0 0], [0 0; 1 0; 0 1]);
            [msg, msgID] = lastwarn;
            testCase.verifyEqual(msgID, '', ...
                sprintf('replacement functions must not emit warnings, saw: %s', msg));
        end

        function shimsShadowRemovedToolboxFunctions(testCase)
            %vrrotvec must resolve to the project replacement, never to the
            %(removed or deprecated) toolbox copies.
            w = which('vrrotvec');
            testCase.assertFalse(isempty(w), 'vrrotvec must resolve on the path');
            testCase.assertTrue(~isempty(regexp(w, 'helper_methods', 'once')), ...
                sprintf('vrrotvec must resolve into helper_methods/, got: %s', w));
            w2 = which('vrrotvec2mat');
            testCase.assertTrue(~isempty(regexp(w2, 'helper_methods', 'once')), ...
                sprintf('vrrotvec2mat must resolve into helper_methods/, got: %s', w2));
        end

        %% ------------------------------------------------------- sanity
        function rotationsAreOrthonormal(testCase)
            %Sanity (tolerance-based): produced matrices are proper rotations.
            G = load(testCase.goldensPath);
            M = G.Ms;
            err = max(abs(pagemtimes(permute(M,[2 1 3]), M) - repmat(eye(3),[1 1,size(M,3)])), [], 'all');
            testCase.verifyLessThanOrEqual(err, 1e-12, 'R''*R deviates from I');
            maxDetErr = 0;
            for k = 1:size(M,3)
                maxDetErr = max(maxDetErr, abs(det(M(:,:,k)) - 1));
            end
            testCase.verifyLessThanOrEqual(maxDetErr, 1e-12, 'det(R) deviates from 1');
        end

        function rotationMapsAOntoB(testCase)
            %Sanity (tolerance-based): applying the rotation maps a onto b.
            G = load(testCase.goldensPath);
            worst = 0;
            for k = 1:size(G.A, 2)
                aU = G.A(:,k) / norm(G.A(:,k));
                bU = G.B(:,k) / norm(G.B(:,k));
                worst = max(worst, norm(G.Ms(:,:,k) * aU - bU));
            end
            testCase.verifyLessThanOrEqual(worst, 1e-9, ...
                'rotation matrices do not map a onto b');
        end
    end

    methods(Access = private)
        function verifyBitwiseEqualBatch(testCase, actual, expected, msg)
            %verifyBitwiseEqualBatch Exact whole-array comparison through a
            %single qualification call, so large fuzz/batch suites do not pay
            %per-iteration qualification overhead.  Semantics match
            %verifyEqual: bitwise equality with NaN == NaN.  On mismatch the
            %first offending element is located and reported.

            if(~isequal(size(actual), size(expected)))
                testCase.verifyFail(sprintf('%s: sizes differ: %s vs %s', ...
                    msg, mat2str(size(actual)), mat2str(size(expected))));
                return;
            end

            if(isequaln(actual, expected))
                return;
            end

            mismatch = ~(actual == expected) & ~(isnan(actual) & isnan(expected));
            idx      = find(mismatch, 1);

            sub = cell(1, ndims(actual));
            [sub{:}] = ind2sub(size(actual), idx);
            subscriptTxt = strjoin(string(sub), ',');

            testCase.verifyFail(sprintf('%s: first mismatch at (%s): %.17g vs %.17g', ...
                msg, subscriptTxt, actual(idx), expected(idx)));
        end

        function [A, B] = appendSpecialCases(~, A, B)
            %appendSpecialCases Adds adversarial edge-case columns to fuzz sets.
            specialA = [ 1     1     1    -1     1              1               1  1;
                         0     0     0     0     0              0               2  0;
                         0     0     0     0     0              0               3  0];
            specialB = [ 5    -1    -1     1    -1             -1               1  0;
                         0     0     0     0     1e-16        -1e-16           2  0;
                         0     0     0     0     0              0               3  1];
            A = [A, specialA];
            B = [B, specialB];
        end
    end
end
