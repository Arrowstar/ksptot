function m = vrrotvec2matReference(r, options)
%VRROTVEC2MATREFERENCE Bit-compatibility reference implementation of vrrotvec2mat.
%   Verbatim port of the Simulink 3D Animation vrrotvec2mat as shipped
%   through MATLAB R2024b (readable source) and verified bit-identical to
%   the obfuscated implementations shipped in R2025b, R2026a and R2026b
%   prereleases across randomized and adversarial input sets.
%
%   This reference exists ONLY so the unit tests can prove that the
%   production replacements (helper_methods/vrrotvec2mat.m,
%   helper_methods/vrrotvec2matBatch.m) remain bit-identical to the removed
%   toolbox behavior on every future MATLAB release.
%
%   Differences from the original are limited to error reporting: the
%   message catalog lookups (message('sl3d:...')) are replaced by literal
%   strings carrying the same identifiers and text. The computational path
%   is unchanged operation-for-operation.
%
%   Copyright 1998-2018 HUMUSOFT s.r.o. and The MathWorks, Inc.
%   Ported for KSPTOT regression testing, 2025.

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

n = sl3dnormalize(r(1:3), epsilon);

x = n(1);
y = n(2);
z = n(3);
m = [ ...
     t*x*x + c,    t*x*y - s*z,  t*x*z + s*y; ...
     t*x*y + s*z,  t*y*y + c,    t*y*z - s*x; ...
     t*x*z - s*y,  t*y*z + s*x,  t*z*z + c ...
    ];
end

function vec_n = sl3dnormalize(vec, maxzero)
%SL3DNORMALIZE Normalize a vector.
%   Y = SL3DNORMALIZE(X,MAXZERO) returns a unit vector Y parallel to the
%   input vector X. If the modulus of the input vector is <= MAXZERO, the
%   output is set to zeros(size(X)).

norm_vec = norm(vec);
if (norm_vec <= maxzero)
  vec_n = zeros(size(vec));
else
  vec_n = vec ./ norm_vec;
end
end
