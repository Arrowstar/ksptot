function[V1,a,ecc,nfeval]=Gauss_Lambert(R1,R2,mu,dt,del_nu,tm)
%% Description
% Computes the solution to Lamber's problem using Gauss' method which needs
% an input of two position vectors and a time between them. This works for 
% elliptical AND Hyperbolic orbits. Works well for points that are less 
% than 10 degrees apart. This converges slowly but is robust 
% (singularity at 180 degrees) and you can use it when you don't know 
% anything about an orbit. See April 25 notes and Vallado 472 & 475 (key)

%% Inputs
% R1 (km) position vector at time=1
% R2 (km) position vector at time=2
% mu (km^3/s^2) gravitational constant of the body the object is orbiting
% around
% dt (sec) the time 
% del_nu (rad) angle between R1 and R2 

%% Output
% V1 - (km/s) velocity vector at R1
% nfeval - (dimensionless) the number of iterations required to reach the
% final result

%% Calculations
r1=norm(R1);
r2=norm(R2);

%del_nu=asin(tm*sqrt(1-cos(del_nu)^2)); %account for prograde/retrograde

m=(mu*dt^2)/(2*sqrt(r1*r2)*cos(del_nu/2))^3; %intermediate variable
l=(r1+r2)/(4*sqrt(r1*r2)*cos(del_nu/2))-1/2; %intermediate variable
if l<0.001
    disp('Warning: L may be too small')
end
%% Iterate to find Y 
y_old=0; %use to start loop
y_new=1; %assume as starting place

tol=1e-6;
nfeval=1;

while abs(y_new-y_old)>=tol
    y_old=y_new;
    x=m/y_old^2-l;
    X=4/3*(1+6/5*x+6*8*x^2/(5*7)+6*8*10*x^3/(5*7*9));
    y_new=1+X*(l+x);
    nfeval=nfeval+1;
    if nfeval>1000
        disp('Error: y not converging withing maximum iterations. L may be too small')
        disp('Exiting Gauss_Lambert.m')
        V1=0;
        a=0;
        ecc=0;
        return
    end
end
%% Use iterated variables to finalize values
rhs=1-2*x; %page 262 BMW
% del_EF is del_E when the orbit is elliptical and del_F =del_H when the
% orbit is hyperbolic. The different texts use different values when it is
% hyperbolic or elliptic but we will wrap it all up in one function and
% only use it after checking elliptic or hyperbolic. It represents the
% eccentric anomaly = del_E, del_F = hyperbolic anomaly 
%
% solve for p based on a and p see page 476 vallado
% we do this once at the end rather than checking it all the way through
% because that would slowdown the program.
if rhs>1; %hyperbolic
    del_EF=2*acosh(rhs); 
    p=r1*r2*(1-cos(del_nu))/(r1+r2-2*sqrt(r1*r2)*cos(del_nu/2)*cosH(del_EF/2));
    disp('Hyperbolic')
elseif rhs<=1 %elliptical / circular
    del_EF=2*acos(rhs);
    p=r1*r2*(1-cos(del_nu))/(r1+r2-2*sqrt(r1*r2)*cos(del_nu/2)*cos(del_EF/2));
    disp('Elliptical/Circular')
end

f=1-r1/p*(1-cos(del_nu));
g=r1*r2*sin(del_nu)/sqrt(mu*p);
V1=(R2-f*R1)/g;

%% Find eccentricity and semi-major axis
[ecc,a,nu,M,inc,RAAN,w]=RV2COE(R1,V1,mu);




