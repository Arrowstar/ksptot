function r = vrrotvecReference(a, b, options)
%VRROTVECREFERENCE Bit-compatibility reference implementation of vrrotvec.
%   Verbatim port of the Simulink 3D Animation vrrotvec as shipped through
%   MATLAB R2024b (readable source) and verified bit-identical to the
%   obfuscated implementations shipped in R2025b, R2026a and R2026b
%   prereleases across randomized and adversarial input sets (see
%   generateVrRotGoldens.m).
%
%   This reference exists ONLY so the unit tests can prove that the
%   production replacements (helper_methods/vrrotvec.m,
%   helper_methods/vrrotvecBatch.m) remain bit-identical to the removed
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
an = sl3dnormalize(a, epsilon);
bn = sl3dnormalize(b, epsilon);

% test for zero input argument magnitude after normalize to take epsilon
% into account
if (~any(an) || ~any(bn))
  error('sl3d:vrdirorirot:argzeromagnitude', 'Input argument has zero magnitude.');
end

ax = sl3dnormalize(cross(an, bn), epsilon);
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
    ax = sl3dnormalize(cross(an, c), epsilon);
end

% Be tolerant to column vector arguments, produce a row vector
r = [ax(:)' angle];
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
