function axang = rotm2axangARH(R)
%ROTM2AXANG Convert rotation matrix to axis-angle representation
%   AXANG = ROTM2AXANG(R) converts a 3D rotation given as an orthonormal
%   rotation matrix, R, into the corresponding axis-angle representation, AXANG.
%   R is an 3-by-3-by-N matrix containing N rotation matrices. Each rotation 
%   matrix has a size of 3-by-3 and is orthonormal.
%   The output AXANG is an N-by-4 matrix of N axis-angle rotations.
%   The first three elements of every row specify the rotation axis and
%   the last element defines the rotation angle (in radians).
%
%   Example:
%      % Convert a rotation matrix into the axis-angle representation
%      R = [1 0 0 ; 0 -1 0; 0 0 -1]
%      axang = rotm2axang(R)
%
%    See also axang2rotm

%   Copyright 2014-2017 The MathWorks, Inc.

%#codegen

% Ortho-normality is not tested, since this validation is expensive
% robotics.internal.validation.validateRotationMatrix(R, 'rotm2axang', 'R');

% Compute theta
theta = real(acos(complex((1/2)*(R(1,1,:)+R(2,2,:)+R(3,3,:)-1))));

% Determine initial axis vectors from theta
v = [ R(3,2,:)-R(2,3,:),...
    R(1,3,:)-R(3,1,:),...
    R(2,1,:)-R(1,2,:)] ./ (repmat(2*sin(theta),[1,3]));

% Handle the degenerate cases where theta is divisible by pi or when the
% axis consists of all zeros
singularLogical = mod(theta, cast(pi,'like',R)) == 0 | all(v == 0, 2);
numSingular = sum(singularLogical,3);
assert(numSingular <= length(singularLogical));

if any(singularLogical)
    vspecial = zeros(3,numSingular,'like',R);
    
    inds = find(singularLogical);
    for i = 1:sum(singularLogical)
        [~,~,V] = svd(eye(3)-R(:,:,inds(i)));
        vspecial(:,i) = V(:,end);
    end
    v(1,:,singularLogical) = vspecial;
end

% Extract final values
theta = reshape(theta,[numel(theta) 1]);
v = reshape(v,[3, numel(v)/3]).';
v = robotics.internal.normalizeRows(v);

axang = cat(2, v, theta);

end