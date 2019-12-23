clc; close all;

rVectECI = [1000;0;0];
vVectECI = [0;2;0];
bodyInfo = celBodyData.kerbin;
ut = 0;

hFig = figure(234);

hold on;
[X,Y,Z] = sphere(30);
radius = bodyInfo.radius;
surf(radius*X,radius*Y,radius*Z);

line('XData',[0 2*radius],'YData',[0 0],'ZData',[0 0]);
line('XData',[0 0],'YData',[0 2*radius],'ZData',[0 0]);
line('XData',[0 0],'YData',[0 0],'ZData',[0 2*radius]);

[~, ~, REci2Ecef] = getFixedFrameVectFromInertialVect(ut, rVectECI, bodyInfo);
REci2Ecef = 2*radius*REci2Ecef;
line('XData',[0 REci2Ecef(1,1)],'YData',[0 REci2Ecef(2,1)],'ZData',[0 REci2Ecef(3,1)], 'Color','red', 'LineStyle','--');
line('XData',[0 REci2Ecef(1,2)],'YData',[0 REci2Ecef(2,2)],'ZData',[0 REci2Ecef(3,2)], 'Color','red', 'LineStyle','--');
line('XData',[0 REci2Ecef(1,3)],'YData',[0 REci2Ecef(2,3)],'ZData',[0 REci2Ecef(3,3)], 'Color','red', 'LineStyle','--');

[R_ned_2_inert, ned_x, ned_y, ned_z] = computeNedFrame(ut, rVectECI, bodyInfo);
R_ned_2_inert = 2*radius*R_ned_2_inert;
line('XData',[rVectECI(1), rVectECI(1)+R_ned_2_inert(1,1)],'YData',[rVectECI(2), rVectECI(2)+R_ned_2_inert(2,1)],'ZData',[rVectECI(3), rVectECI(3)+R_ned_2_inert(3,1)], 'Color','green', 'LineStyle','-');
line('XData',[rVectECI(1), rVectECI(1)+R_ned_2_inert(1,2)],'YData',[rVectECI(2), rVectECI(2)+R_ned_2_inert(2,2)],'ZData',[rVectECI(3), rVectECI(3)+R_ned_2_inert(3,2)], 'Color','green', 'LineStyle','-');
line('XData',[rVectECI(1), rVectECI(1)+R_ned_2_inert(1,3)],'YData',[rVectECI(2), rVectECI(2)+R_ned_2_inert(2,3)],'ZData',[rVectECI(3), rVectECI(3)+R_ned_2_inert(3,3)], 'Color','green', 'LineStyle','-');

% [R_vvlh_2_inert, ~, ~, ~] = computeVvlhFrame(rVectECI, vVectECI);
% R_vvlh_2_inert = 2*radius*R_vvlh_2_inert;
% line('XData',[rVectECI(1), rVectECI(1)+R_vvlh_2_inert(1,1)],'YData',[rVectECI(2), rVectECI(2)+R_vvlh_2_inert(2,1)],'ZData',[rVectECI(3), rVectECI(3)+R_vvlh_2_inert(3,1)], 'Color','blue', 'LineStyle','-');
% line('XData',[rVectECI(1), rVectECI(1)+R_vvlh_2_inert(1,2)],'YData',[rVectECI(2), rVectECI(2)+R_vvlh_2_inert(2,2)],'ZData',[rVectECI(3), rVectECI(3)+R_vvlh_2_inert(3,2)], 'Color','blue', 'LineStyle','-');
% line('XData',[rVectECI(1), rVectECI(1)+R_vvlh_2_inert(1,3)],'YData',[rVectECI(2), rVectECI(2)+R_vvlh_2_inert(2,3)],'ZData',[rVectECI(3), rVectECI(3)+R_vvlh_2_inert(3,3)], 'Color','blue', 'LineStyle','-');

hold off;
grid on;
axis equal;
xlabel('X');
ylabel('Y');
zlabel('Z');
view(3);