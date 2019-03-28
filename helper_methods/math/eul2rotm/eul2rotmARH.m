function R = eul2rotmARH( eul, varargin )
%EUL2ROTM Convert Euler angles to rotation matrix
%   R = EUL2ROTM(EUL) converts a set of 3D Euler angles, EUL, into the
%   corresponding rotation matrix, R. EUL is an N-by-3 matrix of Euler rotation
%   angles. The output, R, is an 3-by-3-by-N matrix containing N rotation
%   matrices. Rotation angles are input in radians.
%
%   R = EUL2ROTM(EUL, SEQ) converts 3D Euler angles into a rotation matrix.
%   The Euler angles are specified by the body-fixed (intrinsic) axis rotation
%   sequence, SEQ.
%
%   The default rotation sequence is 'ZYX', where the order of rotation
%   angles is Z Axis Rotation, Y Axis Rotation, and X Axis Rotation.
%
%   The following rotation sequences, SEQ, are supported: 'ZYX', 'ZYZ', and
%   'XYZ'.
%
%   Example:
%      % Calculate the rotation matrix for a set of Euler angles
%      % By default, the ZYX axis order will be used.
%      angles = [0 pi/2 0];
%      R = eul2rotm(angles)
%
%      % Calculate the rotation matrix based on a ZYZ rotation
%      Rzyz = eul2rotm(angles, 'ZYZ')
%
%   See also rotm2eul

%   Copyright 2014-2017 The MathWorks, Inc.

%#codegen

% robotics.internal.validation.validateNumericMatrix(eul, 'eul2rotm', 'eul', ...
%     'ncols', 3);

% seq = robotics.internal.validation.validateEulerSequence(varargin{:});

if isempty(varargin)
    % Use default rotation sequence
    seq = 'ZYX';
    return;
else
    seq = upper(varargin{1});
end

R = zeros(3,3,size(eul,1),'like',eul);
ct = cos(eul);
st = sin(eul);

% The parsed sequence will be in all upper-case letters and validated
switch seq
    case 'ZYX'
        %     The rotation matrix R can be constructed as follows by
        %     ct = [cz cy cx] and st = [sy sy sx]
        %
        %     R = [  cy*cz   sy*sx*cz-sz*cx    sy*cx*cz+sz*sx
        %            cy*sz   sy*sx*sz+cz*cx    sy*cx*sz-cz*sx
        %              -sy            cy*sx             cy*cx]
        %       = Rz(tz) * Ry(ty) * Rx(tx)
        
        R(1,1,:) = ct(:,2).*ct(:,1);
        R(1,2,:) = st(:,3).*st(:,2).*ct(:,1) - ct(:,3).*st(:,1);
        R(1,3,:) = ct(:,3).*st(:,2).*ct(:,1) + st(:,3).*st(:,1);
        R(2,1,:) = ct(:,2).*st(:,1);
        R(2,2,:) = st(:,3).*st(:,2).*st(:,1) + ct(:,3).*ct(:,1);
        R(2,3,:) = ct(:,3).*st(:,2).*st(:,1) - st(:,3).*ct(:,1);
        R(3,1,:) = -st(:,2);
        R(3,2,:) = st(:,3).*ct(:,2);
        R(3,3,:) = ct(:,3).*ct(:,2);
        
    case 'ZYZ'
        %     The rotation matrix R can be constructed as follows by
        %     ct = [cz cy cz2] and st = [sz sy sz2]
        %
        %     R = [  cz2*cy*cz-sz2*sz   -sz2*cy*cz-cz2*sz    sy*cz
        %            cz2*cy*sz+sz2*cz   -sz2*cy*sz+cz2*cz    sy*sz
        %                     -cz2*sy              sz2*sy       cy]
        %       = Rz(tz) * Ry(ty) * Rz(tz2)
        
        R(1,1,:) = ct(:,1).*ct(:,3).*ct(:,2) - st(:,1).*st(:,3);
        R(1,2,:) = -ct(:,1).*ct(:,2).*st(:,3) - st(:,1).*ct(:,3);
        R(1,3,:) = ct(:,1).*st(:,2);
        R(2,1,:) = st(:,1).*ct(:,3).*ct(:,2) + ct(:,1).*st(:,3);
        R(2,2,:) = -st(:,1).*ct(:,2).*st(:,3) + ct(:,1).*ct(:,3);
        R(2,3,:) = st(:,1).*st(:,2);
        R(3,1,:) = -st(:,2).*ct(:,3);
        R(3,2,:) = st(:,2).*st(:,3);
        R(3,3,:) = ct(:,2);
        
    case 'XYZ'
        %     The rotation matrix R can be constructed as follows by
        %     ct = [cx cy cz] and st = [sx sy sz]
        %
        %     R = [            cy*cz,           -cy*sz,     sy]
        %         [ cx*sz + cz*sx*sy, cx*cz - sx*sy*sz, -cy*sx]
        %         [ sx*sz - cx*cz*sy, cz*sx + cx*sy*sz,  cx*cy]
        %       = Rx(tx) * Ry(ty) * Rz(tz)
        
        R(1,1,:) = ct(:,2).*ct(:,3);
        R(1,2,:) = -ct(:,2).*st(:,3);
        R(1,3,:) = st(:,2);
        R(2,1,:) = ct(:,1).*st(:,3) + ct(:,3).*st(:,1).*st(:,2);
        R(2,2,:) = ct(:,1).*ct(:,3) - st(:,1).*st(:,2).*st(:,3);
        R(2,3,:) = -ct(:,2).*st(:,1);
        R(3,1,:) = st(:,1).*st(:,3) - ct(:,1).*ct(:,3).*st(:,2);
        R(3,2,:) = ct(:,3).*st(:,1) + ct(:,1).*st(:,2).*st(:,3);
        R(3,3,:) = ct(:,1).*ct(:,2);
    otherwise
        error('Unknown sequence in eul2rotm()!');
end

end

