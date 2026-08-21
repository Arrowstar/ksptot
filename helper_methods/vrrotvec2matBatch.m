function M = vrrotvec2matBatch(R, epsilon)
%VRROTVEC2MATBATCH Batch axis-angle to rotation matrices.
%   M = VRROTVEC2MATBATCH(R) converts N axis-angle rotations to a 3x3xN
%   array of rotation matrix pages.
%
%   R may be given as an N-by-4 matrix (rows of [x y z theta]) or a 4-by-N
%   matrix (columns). For an unambiguous 4x4 input, it is interpreted as
%   four row rotations.
%
%   M = VRROTVEC2MATBATCH(R, EPSILON) overrides the default zero threshold
%   (1e-12), mirroring the 'epsilon' option of VRROTVEC2MAT.
%
%   Page M(:,:,k) is bit-identical to vrrotvec2mat(R(k,:)) (or R(:,k)) for
%   every k. Bit-compatibility notes:
%      - The trigonometry is computed vectorized, which is bit-identical
%        to scalar sin()/cos() calls (verified over randomized inputs in
%        double and single precision).
%      - Axis normalization uses norm() per column because MATLAB's vector
%        2-norm is NOT bit-identical to sqrt(sum(x.^2)) in general.
%      - Elementwise products follow the same left-to-right operation
%        order as the scalar implementation.
%
%   Limitations relative to VRROTVEC2MAT:
%      - R must be real floating-point (single or double).
%
%   Example:
%      r = [0 0 1 pi/2; 1 0 0 pi];         % 2-by-4
%      M = vrrotvec2matBatch(r);           % 3x3x2
%      vRot = M(:,:,1) * [1;0;0];
%
%   See also VRROTVEC2MAT, VRROTVEC, VRROTVECBATCH.

%   KSPTOT project, 2025.

if(nargin < 2)
    epsilon = 1e-12;
end

if(~isnumeric(R) || ~isreal(R) || ~isfloat(R))
    error('sl3d:vrdirorirot:argnotreal', 'Input argument contains non-real elements.');
end

if(ndims(R) ~= 2 || ~(size(R,1) == 4 || size(R,2) == 4))  %#ok<ISMAT> - either dimension may be 4 (rows or columns)
    error('sl3d:vrdirorirot:argbaddim', 'R must contain 4-element axis-angle rotations.');
end

if(size(R,1) == 4 && size(R,2) ~= 4)
    R = R.';  % accept 4-by-N columns, work with N-by-4 rows
end

if(size(R,2) ~= 4)
    error('sl3d:vrdirorirot:argbaddim', 'R must contain 4-element axis-angle rotations.');
end

numInputs = size(R, 1);

% normalize each axis with norm(), matching vrrotvec2mat bit-for-bit
nrm = zeros(1, numInputs, 'like', R);
for(k = 1:numInputs)
    nrm(k) = norm(R(k,1:3));
end

% build the rotation matrices (mirrors vrrotvec2mat exactly)
s = sin(R(:,4));
c = cos(R(:,4));
t = 1 - c;

n = R(:,1:3) ./ nrm.';      % zero-norm axes produce NaN rows, masked below
n(nrm <= epsilon, :) = 0;   % sl3dnormalize zero-magnitude semantics

x = n(:,1);
y = n(:,2);
z = n(:,3);

Mp = zeros(numInputs, 3, 3, 'like', R);
Mp(:,1,1) = t.*x.*x + c;    Mp(:,1,2) = t.*x.*y - s.*z;    Mp(:,1,3) = t.*x.*z + s.*y;
Mp(:,2,1) = t.*x.*y + s.*z; Mp(:,2,2) = t.*y.*y + c;      Mp(:,2,3) = t.*y.*z - s.*x;
Mp(:,3,1) = t.*x.*z - s.*y; Mp(:,3,2) = t.*y.*z + s.*x;   Mp(:,3,3) = t.*z.*z + c;

M = permute(Mp, [2 3 1]);
end
