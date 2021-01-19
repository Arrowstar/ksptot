function R = axang2rotmARH( axang )
%AXANG2ROTM Convert axis-angle rotation representation to rotation matrix
%   R = AXANG2ROTM(AXANG) converts a 3D rotation given in axis-angle form,
%   AXANG, to an orthonormal rotation matrix, R. AXANG is an N-by-4
%   matrix of N axis-angle rotations. The first three elements of every
%   row specify the rotation axis and the last element defines the rotation
%   angle (in radians).
%   The output, R, is an 3-by-3-by-N matrix containing N rotation matrices. 
%   Each rotation matrix has a size of 3-by-3 and is orthonormal.
%
%   Example:
%      % Convert a rotation from axis-angle to rotation matrix
%      axang = [0 1 0 pi/2];
%      R = axang2rotm(axang)
%
%   See also rotm2axang

%   Copyright 2014-2015 The MathWorks, Inc.

%#codegen

robotics.internal.validation.validateNumericMatrix(axang, 'axang2rotm', 'axang', ...
    'ncols', 4);

% For a single axis-angle vector [ax ay az theta] the output rotation
% matrix R can be computed as follows:
% R =  [t*x*x + c	  t*x*y - z*s	   t*x*z + y*s
%       t*x*y + z*s	  t*y*y + c	       t*y*z - x*s
%       t*x*z - y*s	  t*y*z + x*s	   t*z*z + c]
% where,
% c = cos(theta)
% s = sin(theta)
% t = 1 - c
% x = normalized axis ax coordinate
% y = normalized axis ay coordinate
% z = normalized axis az coordinate

% Normalize the axis
v = normalizeRowsARH(axang(:,1:3));

% Extract the rotation angles and shape them in depth dimension
numInputs = size(axang,1);
theta = zeros(1,1,numInputs);
theta(1,1,:) = axang(:,4);

% Compute rotation matrices
cth = cos(theta);
sth = sin(theta);
vth = (1 - cth);

% Preallocate input vectors
vx = zeros(1,1,numInputs,'like',axang);
vy = vx;
vz = vx;

% Shape input vectors in depth dimension
vx(1,1,:) = v(:,1);
vy(1,1,:) = v(:,2);
vz(1,1,:) = v(:,3);

% Explicitly specify concatenation dimension
tempR = cat(1, vx.*vx.*vth+cth,     vy.*vx.*vth-vz.*sth, vz.*vx.*vth+vy.*sth, ...
               vx.*vy.*vth+vz.*sth, vy.*vy.*vth+cth,     vz.*vy.*vth-vx.*sth, ...
               vx.*vz.*vth-vy.*sth, vy.*vz.*vth+vx.*sth, vz.*vz.*vth+cth);

R = reshape(tempR, [3, 3, length(vx)]);
R = permute(R, [2 1 3]);

end