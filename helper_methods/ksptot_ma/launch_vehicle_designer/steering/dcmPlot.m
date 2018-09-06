clc; clear variables; format long g; close all;

% rVect = [0;6500;0];
% vVect = [-7;0;0];

% rVect = [-1450.890504;5491.596657;3242.83652];
% vVect = [-8.004587;-1.747801;0.401527];

% TA = 1
% rVect = [ 1.27543303578052437E+04;	 2.22627664511427128E+02;	 0.00000000000000000E+00];
% vVect = [-9.75578671137836695E-02;	 5.58908646372739337E+00;	 0.00000000000000000E+00];

% TA = 45
% rVect = [ 9.02004728238822099E+03;	 9.02004728238821917E+03;	 0.00000000000000000E+00];
% vVect = [-3.95268295189840391E+00;	 3.95268295189840480E+00;	 0.00000000000000000E+00];

% Elliptical at apogee
rVect = [-4.21641365999999907E+04;	 5.16361749260017546E-12;	 0.00000000000000000E+00];
vVect = [-7.20051264852469309E-16;	-1.60783689892893555E+00;	 0.00000000000000000E+00];

% Elliptical at TA=90
% rVect = [ 7.06014292670830499E-13;	 1.15300884003842602E+04;	 0.00000000000000000E+00];
% vVect = [-5.87966477643837404E+00;	 4.27182787750943938E+00;	 0.00000000000000000E+00];

%%Test Roll/Pitch/Yaw
rollAng = deg2rad(5);
pitchAng = deg2rad(-30);
yawAng = deg2rad(10);

[bodyEulerX, bodyEulerY, bodyEulerZ] = computeBodyAxesFromEuler(rVect, vVect, rollAng, pitchAng, yawAng);
[bankAngE,angOfAttackE,angOfSideslipE] = computeAeroAnglesFromBodyAxes(rVect, vVect, bodyEulerX, bodyEulerY, bodyEulerZ);

%%Test AoA/Slip/Bank Conversions
bankAng = bankAngE;
angOfAttack = angOfAttackE;
angOfSideslip = angOfSideslipE;

[bodyAeroX, bodyAeroY, bodyAeroZ] = computeBodyAxesFromAeroAngles(rVect, vVect, angOfAttack, angOfSideslip, bankAng);
[rollAngle, pitchAngle, yawAngle] = computeEulerAnglesFromInertialBodyAxes(rVect, vVect, bodyAeroX, bodyAeroY, bodyAeroZ);

%Plot stuff
figure()
hold on;

plot3([0,1],[0,0],[0,0],'k');
plot3([0,0],[0,1],[0,0],'k--');
plot3([0,0],[0,0],[0,1],'k--');

rHat = rVect/norm(rVect);
plot3([0,-rHat(1)],[0,-rHat(2)],[0,-rHat(3)],'g');

vHat = vVect/norm(vVect);
plot3([0,vHat(1)],[0,vHat(2)],[0,vHat(3)],'c');

plot3([0,bodyEulerX(1)],[0,bodyEulerX(2)],[0,bodyEulerX(3)],'r');
plot3([0,bodyEulerY(1)],[0,bodyEulerY(2)],[0,bodyEulerY(3)],'r--');
plot3([0,bodyEulerZ(1)],[0,bodyEulerZ(2)],[0,bodyEulerZ(3)],'r--');

plot3([0,bodyAeroX(1)],[0,bodyAeroX(2)],[0,bodyAeroX(3)],'b');
plot3([0,bodyAeroY(1)],[0,bodyAeroY(2)],[0,bodyAeroY(3)],'b--');
plot3([0,bodyAeroZ(1)],[0,bodyAeroZ(2)],[0,bodyAeroZ(3)],'b--');

[~, vvlh_x, vvlh_y, ~] = computeVvlhFrame(rVect,vVect);
patch('XData', [vvlh_x(1) vvlh_y(1) -vvlh_x(1) -vvlh_y(1)], ...
      'YData', [vvlh_x(2) vvlh_y(2) -vvlh_x(2) -vvlh_y(2)], ...
      'ZData', [vvlh_x(3) vvlh_y(3) -vvlh_x(3) -vvlh_y(3)], ...
      'FaceColor', 'g', 'FaceAlpha', 0.2);

view(3);
grid on;
axis equal;
hold off;