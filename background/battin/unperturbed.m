function[out]=unperturbed(time,x0,mu)
% Output [t,f] is listed as follows:
% t = @time
% f(1:3) = position
% f(4:6) = velocity

%x0 = the x,y,z,Vx,Vy,Vz of the s/c
%Construct the Xdot=A*x matrix
% |Vx|   |0 0 0 1 0 0|   |x |   | 0                |
% |Vy|   |0 0 0 0 1 0|   |y |   | 0                |
% |Vz| = |0 0 0 0 0 1| * |z | + | 0                |
% |Ax|   |0 0 0 0 0 0|   |Vx|   | -G*sunm/r^2*|Rx| |
% |Ay|   |0 0 0 0 0 0|   |Vy|   | -G*sunm/r^2*|Ry| |
% |Az|   |0 0 0 0 0 0|   |Vz|   | -G*sunm/r^2*|Rz| |
% idot =      A1       * input   +     A2(input)
% where |Rx| is the unit vector of R in the x direction
% where R=sqrt(x^2+y^2+z^2);


Vx=x0(4);
Vy=x0(5);
Vz=x0(6);
R=[x0(1);x0(2);x0(3)]; %the radius vector
r=norm(R); %the 2 norm of the radius
Ax=-mu/r^3*R(1);
Ay=-mu/r^3*R(2);
Az=-mu/r^3*R(3);

out=[Vx;Vy;Vz;Ax;Ay;Az];