% rodrigues_rot - Rotates array of 3D vectors by an angle theta about vector k.
% Direction is determined by the right-hand (screw) rule.
%
% Syntax:  v_rot = rodrigues(v,k,theta)
%
% Inputs:
%    v - Array of three dimensional vectors to rotate. Array can be 
%           composed of N rows of 3D row vectors or N columns of 3D column
%           vectors. If v is 3x3 array, it is assumed that it is 3 rows of
%           3 3D row vectors.
%    k - Rotation axis (does not need to be unit vector)
%    theta - Rotation angle in radians; positive according to right-hand
%           (screw) rule
%
%   Note: k and individual 3D vectors in v array must be same orientation.
%           
%
% Outputs:
%    v_rot - Array of rotated vectors.
%
% Other m-files required: dot.m (built-in MATLAB)
% Subfunctions: none
% MAT-files required: none
%
% Author: Ismail Hameduddin
%           Mechanical Engineering, Purdue University
% email: ihameduddin@gmail.com
% Website: http://www.ismailh.com
% January 2011; Last revision: 2-January-2012

%------------- BEGIN CODE --------------

function v_rot = rodrigues_rot_vect(v,k,theta)
    [m,n] = size(v);
    if (m ~= 3 && n ~= 3)
        error('input vector is/are not three dimensional'), end
    if (size(v) ~= size(k)) 
        error('rotation vector v and axis k have different dimensions'),end

    kNorm = sqrt(sum(abs(k).^2,1));
    k = bsxfun(@rdivide,k,kNorm);

    crosskv = cross(k,v);
    mult1 = bsxfun(@times,cos(theta),v);
    mult2 = bsxfun(@times,crosskv,sin(theta));
    mult3_1 = dot(k,v,1);
    mult3_2 = bsxfun(@times,k,mult3_1);
    mult3 = bsxfun(@times, mult3_2, 1 - cos(theta));
    v_rot = mult1 + mult2 + mult3;
end

%------------- END OF CODE --------------
