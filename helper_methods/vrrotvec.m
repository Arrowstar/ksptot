function r = vrrotvec(a, b, options)
%VRROTVEC Calculate a rotation between two vectors.
%   R = VRROTVEC(A, B) calculates a rotation needed to transform
%   a 3D vector A to a 3D vector B.
%
%   R = VRROTVEC(A, B, OPTIONS) calculates the rotation with the default
%   algorithm parameters replaced by values defined in the structure
%   OPTIONS.
%
%   The OPTIONS structure contains the following parameters:
%
%     'epsilon'
%        Minimum value to treat a number as zero.
%        Default value of 'epsilon' is 1e-12.
%
%   The result R is a 4-element axis-angle rotation row vector.
%   First three elements specify the rotation axis, the last element
%   defines the angle of rotation.
%
%   This function is a self-contained, bit-compatible replacement for the
%   vrrotvec function that shipped with Simulink 3D Animation and was
%   removed in MATLAB R2026b. It reproduces the removed function's
%   arithmetic operation-for-operation (same operations, same order), so
%   results are bit-identical for identical inputs. Errors use the same
%   message identifiers as the removed original.
%
%   For vectorized evaluation of many vector pairs at once, see
%   VRROTVECBATCH, which produces bit-identical results with much less
%   per-call overhead.
%
%   See also VRROTVEC2MAT, VRROTVECBATCH, VRROTVEC2MATBATCH, AXANG2ROTMARH,
%   MAKEHGTFORM.

%   Drop-in replacement for the Simulink 3D Animation function
%   Copyright 1998-2018 HUMUSOFT s.r.o. and The MathWorks, Inc.
%   Replacement port: KSPTOT project, 2025.

% test input arguments
narginchk(2, 3);

if ~isnumeric(a) || ~isreal(a)
  error('sl3d:vrdirorirot:argnotreal', 'Input argument contains non-real elements.');
end

if (length(a) ~= 3)
  error('sl3d:vrdirorirot:argbaddim', 'Input argument must have 3 elements.');
end

if ~isnumeric(b) || ~isreal(b)
  error('sl3d:vrdirorirot:argnotreal', 'Input argument contains non-real elements.');
end

if (length(b) ~= 3)
  error('sl3d:vrdirorirot:argbaddim', 'Input argument must have 3 elements.');
end

if nargin == 2
  % default options values
  epsilon = 1e-12;
else
  if ~isstruct(options)
     error('sl3d:vrdirorirot:optsnotstruct', 'OPTIONS must be a structure.');
  else
    % check / read the 'epsilon' option
    if ~isfield(options,'epsilon')
      error('sl3d:vrdirorirot:optsfieldnameinvalid', 'Invalid OPTIONS field name(s).');
    elseif (~isreal(options.epsilon) || ~isnumeric(options.epsilon) || options.epsilon < 0)
      error('sl3d:vrdirorirot:optsfieldvalueinvalid', 'Invalid OPTIONS field(s).');
    else
      epsilon = options.epsilon;
    end
  end
end

% compute the rotation, vectors must be normalized
an = ksptotSlNormalize(a, epsilon);
bn = ksptotSlNormalize(b, epsilon);

% test for zero input argument magnitude after normalize to take epsilon
% into account
if (~any(an) || ~any(bn))
  error('sl3d:vrdirorirot:argzeromagnitude', 'Input argument has zero magnitude.');
end

ax = ksptotSlNormalize(cross(an, bn), epsilon);
% min to eliminate possible rounding errors that can lead to dot product >1
angle = acos(min(dot(an, bn), 1));

% if cross(an, bn) is zero, vectors are parallel (angle = 0) or antiparallel
% (angle = pi). In both cases it is necessary to provide a valid axis. Let's
% select one that satisfies both cases - an axis that is perpendicular to
% both vectors. We find this vector by cross product of the first vector
% with the "least aligned" basis vector.
if ~any(ax)
    absa = abs(an);
    [~, mind] = min(absa);
    c = zeros(1,3);
    c(mind) = 1;
    ax = ksptotSlNormalize(cross(an, c), epsilon);
end

% Be tolerant to column vector arguments, produce a row vector
r = [ax(:)' angle];
end

function vec_n = ksptotSlNormalize(vec, maxzero)
%KSPOTSLNORMALIZE Normalize a vector, treating small magnitudes as zero.
%   Y = KSPOTSLNORMALIZE(X,MAXZERO) returns a unit vector Y parallel to the
%   input vector X. If the modulus of the input vector is <= MAXZERO, the
%   output is set to zeros(size(X)).
%
%   Port of the removed Simulink 3D Animation internal sl3dnormalize. The
%   norm() call is intentional: MATLAB's vector 2-norm is not always
%   bit-identical to sqrt(sum(x.^2)), and bit compatibility with the
%   removed function requires using norm() itself.

norm_vec = norm(vec);
if (norm_vec <= maxzero)
  vec_n = zeros(size(vec));
else
  vec_n = vec ./ norm_vec;
end
end
