function[V1,a,ecc,nfeval]=Battin_Lambert(R1,R2,mu,dt,del_nu,tm)
%% Description
% This function calculates the solution to lambert's problem using Battin's
% method. This method is more robust than Universal Variables and Gauss
% because it can handle observations taking at 180 degrees apart
% (del_nu=180 degrees.) See Vallado page 491 for walkthrough. 
% See also: An introduct to the Mathematics and Methods of Astrodynamics
% by Batton: http://books.google.com/books?id=OjH7aVhiGdcC&lpg=PA295&ots=FewBNtmitd&dq=lambert's%20problem%20battin&pg=PA325#v=onepage&q=lambert's%20problem%20battin&f=false

% Validated with example 7-5 in vallado page 494 6/2/2012 -EDAH

%% Inputs
% R1 (km) position vector at time=1
% R2 (km) position vector at time=2
% mu (km^3/s^2) gravitational constant of the body the object is orbiting
% around
% dt (sec) the time 
% del_nu (rad) angle between R1 and R2 
% n_rev (dimensionless) the number of times the object revolves around the
% central body before getting to R2.

%% Output
% V1 - (km/s) velocity vector at R1
% a - (km/s) semi-major axis of orbit
% ecc - (dimensionless) eccentricity of orbit
% nfeval - (dimensionless) the number of iterations required to reach the
% final result

%% Calculations
r1=norm(R1);
r2=norm(R2);

%cosdtnu=dot(R1,R2)/(r1*r2);
%sindtnu=tm*sqrt(1-cosdtnu^2);
%del_nu=atan2(sindtnu,cosdtnu); %find del_nu in the proper quadrant (lambert.m code)

% the angle needs to be positive to work for the long way per vallado
% lambertb.m code and is probably also applicable to Universal varialbles
% and gauss.
if del_nu < 0.0
    del_nu=2.0*pi+del_nu;
end

chord=sqrt(r1^2+r2^2-2*r1*r2*cos(del_nu));
s=(r1+r2+chord)/2;
e=(r2-r1)/r1;

cossq_dnu4=cos(del_nu/4)^2;
sinsq_dnu4=sin(del_nu/4)^2;
cos_dnu2=cos(del_nu/2);
tansq_2w=e^2/4/(sqrt(r2/r1)+r2/r1*(2+sqrt(r2/r1)));

r1p=sqrt(r1*r2)*(cossq_dnu4+tansq_2w); %mean point radius of the parabola

if del_nu<pi
    L=(sinsq_dnu4+tansq_2w)/(sinsq_dnu4+tansq_2w+cos_dnu2);
else
    L=(cossq_dnu4+tansq_2w-cos_dnu2)/(cossq_dnu4+tansq_2w);
end

m=mu*dt^2/(8*r1p^3);

tol=1e-6;
x_new=L; %inital value to get into the loop
% If orbit is elliptical use x_new=L to get into the loop
% If orbit is parabolic or hyperbolic x_new=0

x=10;
nfeval=0;


% iterate on x
while abs(x-x_new)>tol
    x=x_new;
    n=x/(sqrt(1+x)+1)^2;
    Xi_x=Xi(x);
    h1=(L+x)^2*(1+3*x+Xi_x)/((1+2*x+L)*(4*x+Xi_x*(3+x)));
    h2=m*(x-L+Xi_x)/((1+2*x+L)*(4*x+Xi_x*(3+x)));
    % Solve the resulting cubic y^3-y^2-h1*y^2-h2=0
    B=27*h2/(4*(1+h1)^3);
    U=B/(2*(sqrt(1+B)+1));
    K_U=Kay(U);
    y=(1+h1)/3*(2+sqrt(1+B)/(1+2*U*K_U^2));
    x_new=sqrt(((1-L)/2)^2+m/y^2)-(1+L)/2;
    nfeval=nfeval+1;
end
x=x_new; %grab the last valid value of x

a=mu*dt^2/(16*r1p^2*x*y^2);

if a>0
    beta=2*asin(sqrt((s-chord)/(2*a)));
    if del_nu>pi
        beta=-beta;
    end
    a_min=s/2;
    t_min=sqrt(a_min^3/mu)*(pi-beta+sin(beta));
    alpha=2*asin(sqrt(s/(2*a)));
    if dt>t_min
        alpha=2*pi-alpha;
    end
    del_E=alpha-beta;
    f=1-a/r1*(1-cos(del_E));
    g=dt-sqrt(a^3/mu)*(del_E-sin(del_E));
    %g_dot=1-a/r2*(1-cos(del_E)); not required
elseif a<0
    alpha=2*asinh(sqrt(s/(-2*a)));
    beta=2*asinh(sqrt((s-chord)/(-2*a)));
    del_H=alpha-beta;
    f=1-a/r1*(1-cosh(del_H));
    g=dt-sqrt(-a^3/mu)*(sinh(del_H)-del_H);
    %g_dot=1-a/r1*(1-cosh(del_H)); not required
end
V1=(R2-f*R1)/g;
% V2=(g_dot*R2-R1)/g;  not required

%% Find eccentricity and semi-major axis
[ecc,a,nu,M,inc,RAAN,w]=RV2COE(R1,V1,mu);

end

