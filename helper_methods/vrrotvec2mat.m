function m = vrrotvec2mat(r, options)
%VRROTVEC2MAT Convert rotation from axis-angle to matrix representation.
%   M = VRROTVEC2MAT(R) returns a matrix representation of rotation
%   defined by the axis-angle rotation vector R.
%
%   M = VRROTVEC2MAT(R, OPTIONS) returns a matrix representation of rotation
%   defined by the axis-angle rotation vector R, with the default
%   algorithm parameters replaced by values defined in the structure
%   OPTIONS.
%
%   The OPTIONS structure contains the following parameters:
%
%     'epsilon'
%        Minimum value to treat a number as zero.
%        Default value of 'epsilon' is 1e-12.
%
%   The rotation vector R is a row vector of 4 elements,
%   where the first three elements specify the rotation axis
%   and the last element defines the angle.
%
%   To rotate a column vector of 3 elements, multiply the rotation
%   matrix by it. To rotate a row vector of 3 elements, multiply it
%   by the transposed rotation matrix.
%
%   This function is a self-contained, bit-compatible replacement for the
%   vrrotvec2mat function that shipped with Simulink 3D Animation and was
%   removed in MATLAB R2026b. It reproduces the removed function's
%   arithmetic operation-for-operation (same operations, same order), so
%   results are bit-identical for identical inputs. Errors use the same
%   message identifiers as the removed original.
%
%   For vectorized evaluation of many rotations at once, see
%   VRROTVEC2MATBATCH, which produces bit-identical results with much less
%   per-call overhead.
%
%   See also VRROTVEC, VRROTVECBATCH, VRROTVEC2MATBATCH, MAKEHGTFORM.

%   Drop-in replacement for the Simulink 3D Animation function
%   Copyright 1998-2018 HUMUSOFT s.r.o. and The MathWorks, Inc.
%   Replacement port: KSPTOT project, 2025.

% test input arguments
narginchk(1, 2);

if ~isnumeric(r) || ~isreal(r)
  error('sl3d:vrdirorirot:argnotreal', 'Input argument contains non-real elements.');
end

if (length(r) ~= 4)
  error('sl3d:vrdirorirot:argbaddim', 'Input argument must have 4 elements.');
end

if nargin == 1
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

% build the rotation matrix
s = sin(r(4));
c = cos(r(4));
t = 1 - c;

n = ksptotSlNormalize(r(1:3), epsilon);

x = n(1);
y = n(2);
z = n(3);
m = [ ...
     t*x*x + c,    t*x*y - s*z,  t*x*z + s*y; ...
     t*x*y + s*z,  t*y*y + c,    t*y*z - s*x; ...
     t*x*z - s*y,  t*y*z + s*x,  t*z*z + c ...
    ];
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
