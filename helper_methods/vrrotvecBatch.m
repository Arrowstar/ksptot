function AAng = vrrotvecBatch(A, B, epsilon)
%VRROTVECBATCH Batch rotation calculation between two sets of vectors.
%   AANG = VRROTVECBATCH(A, B) calculates the rotations needed to transform
%   each 3D column vector A(:,k) into the corresponding column vector B(:,k).
%   A and B must be real floating-point 3-by-N matrices.
%
%   AANG = VRROTVECBATCH(A, B, EPSILON) overrides the default zero threshold
%   (1e-12), mirroring the 'epsilon' option of VRROTVEC.
%
%   AANG is an N-by-4 matrix of axis-angle rotations. The first three
%   elements of every row specify the rotation axis and the last element
%   defines the angle of rotation. Row k is bit-identical to
%   vrrotvec(A(:,k), B(:,k)) for every k.
%
%   Bit-compatibility notes:
%      - Input validation is hoisted out of the loop; the per-column
%        arithmetic reproduces VRROTVEC operation-for-operation.
%      - norm(), cross() and dot() are called exactly as VRROTVEC calls
%        them. This matters for bit compatibility: MATLAB's vector norm()
%        and dot() are NOT bit-identical to sqrt(sum(x.^2)) / sum(x.*y)
%        in general, so naive vectorization would produce last-bit
%        differences.
%      - Columns whose magnitude is <= EPSILON raise the same error as
%        VRROTVEC ('sl3d:vrdirorirot:argzeromagnitude').
%
%   Example:
%      A = [1 0; 0 1; 0 0];      % two e_x columns
%      B = [0 0; 1 0; 0 1];      % e_y and e_z
%      axang = vrrotvecBatch(A, B);
%
%   See also VRROTVEC, VRROTVEC2MAT, VRROTVEC2MATBATCH.

%   KSPTOT project, 2025.

if(nargin < 3)
    epsilon = 1e-12;
end

if(~isnumeric(A) || ~isreal(A) || ~isfloat(A) || ~isnumeric(B) || ~isreal(B) || ~isfloat(B))
    error('sl3d:vrdirorirot:argnotreal', 'Input argument contains non-real elements.');
end

if(~isequal(size(A), size(B)))
    error('sl3d:vrdirorirot:argbaddim', 'Input argument must have 3 elements.');
end

if(size(A,1) ~= 3 || ndims(A) ~= 2)  %#ok<ISMAT> - explicit dims also enforce the 3-row batch layout
    error('sl3d:vrdirorirot:argbaddim', 'Input argument must have 3 elements.');
end

numInputs = size(A,2);

AAng = zeros(numInputs, 4, class(A));

for(k = 1:numInputs)
    a = A(:,k);
    b = B(:,k);

    % compute the rotation, vectors must be normalized (mirrors vrrotvec)
    an = a;
    normA = norm(a);
    if(normA <= epsilon)
        an(:) = 0;
    else
        an = a ./ normA;
    end

    bn = b;
    normB = norm(b);
    if(normB <= epsilon)
        bn(:) = 0;
    else
        bn = b ./ normB;
    end

    % test for zero input argument magnitude after normalize to take
    % epsilon into account
    if(~any(an) || ~any(bn))
        error('sl3d:vrdirorirot:argzeromagnitude', 'Input argument has zero magnitude.');
    end

    w = cross(an, bn);
    ax = w;
    normW = norm(w);
    if(normW <= epsilon)
        ax(:) = 0;
    else
        ax = w ./ normW;
    end

    % min to eliminate possible rounding errors that can lead to dot
    % product >1
    angle = acos(min(dot(an, bn), 1));

    % if cross(an, bn) is zero, vectors are parallel (angle = 0) or
    % antiparallel (angle = pi). In both cases it is necessary to provide a
    % valid axis - one that is perpendicular to both vectors, found by
    % crossing the first vector with the "least aligned" basis vector.
    if(~any(ax))
        absa = abs(an);
        [~, mind] = min(absa);
        cVec = zeros(1,3);
        cVec(mind) = 1;
        wc = cross(an, cVec);
        ax = wc;
        normWc = norm(wc);
        if(normWc <= epsilon)
            ax(:) = 0;
        else
            ax = wc ./ normWc;
        end
    end

    % be tolerant to column vector arguments, produce a row vector
    AAng(k,:) = [ax(:)' angle];
end
end
