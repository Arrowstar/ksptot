function[out]=Lamberts_Analysis(R1,R2,mu,dt,n_rev,tm)
%% Description
% This function solves Lambert's problem (two position vectors and the time
% between them) by determining which lambert angorithem to use and
% returning the results from the valid algorythims. The program will prompt
% the user to get better info on which methods to use.

%% Inputs
% R1 - (km) position of object at first sighting
% R2 - (km) position of oject at second sighting
% mu - (km^3/s^2) gravitational constant the object is orbiting around (so
% for objects spotted around earth use mu_earth and if you are doing an
% interplanetary from earth to mars use mu_sun
%
% dt - (sec) the time between sighting 1 and sighting 2
% n_rev - (dimensionles) the number of revolutions the object has made
% are the central body between the first and the second sightings
% n_rev=0 is typical and will use only a single rev solver, n_rev=1 or more
% will use a multi-revolution solver. n_rev='?' indicates you don't know how
% many revolutions have passed
%
% tm - (dimensionless) the direction of motion that the particle is going,
% prograge tm=1, retrograde tm=-1, or don't know tm='?', (if tm=0 we have to
% run the program for both tm=1 and tm=-1 and return both results)

%% Calculations
%% Find Del_NU for all cases
% Figure out del_nu (the angle between R1 and R2) in radians based on curtis page 264
sys_con; %load default variables

r1=norm(R1);
r2=norm(R2);
check=cross(R1,R2);
if check(3)>=0
    if tm==1 %prograde
        del_nu=acos(dot(R1,R2)/(r1*r2)); %first or 3rd quadrant 
    elseif tm==-1 %retrograde
        del_nu=2*pi-acos(dot(R1,R2)/(r1*r2));
    end
elseif check(3)<0
    if tm==1 %prograde
        del_nu=2*pi-acos(dot(R1,R2)/(r1*r2)); %second or 4th quadreant
    elseif tm==-1 %retrograde
        del_nu=acos(dot(R1,R2)/(r1*r2));
    end
end

% alternate way to find the angle
%cosdtnu=dot(R1,R2)/(r1*r2);
%sindtnu=tm*sqrt(1-cosdtnu^2);
%del_nu=atan2(sindtnu,cosdtnu); %find del_nu in the proper quadrant (lambert.m code)
%if del_nu < 0.0
%    del_nu=2.0*pi+del_nu;
%end


%% Use input variables , determin what optimizer you should run
if mu==mu_earth
    r_planet=r_earth+100; %burnup radius for impact check
else
    disp('Please define radius of planet impact in the code')
end

% When to run Gauss Solver
if del_nu<42/180*pi && n_rev==0 && tm==1 %less than 42 degrees
    disp('Search Type: Gauss Single Revolution')
    [V1,a,ecc,nfeval]=Gauss_Lambert(R1,R2,mu,dt,del_nu,tm) %execute the gauss lambert solver does not work for retrograde yet
    if norm(V1)~=0 %only do this if the program has run correctly
        disp('Verifying No Earth Impact')
        [crash]=Impact_Check(R1,V1,dt, mu,r_planet);
        if crash==0
            disp('Orbital path given by R1 and V1 does not impact planet within time "dt" given ')
        elseif crash==1
            disp('Orbital path given by R1 and V1 vector passes through planet and is invalid')
        end
    end
end

% When to run UV Solver
if del_nu~=pi
    disp('Search Type: Universal Variables')
    if n_rev>0
        disp('Multi-Revolution')
    else
        disp('Single Revolution')
    end
    [V1,a,ecc,nfeval]=UV_Lambert_b(R1,R2,mu,dt,del_nu,n_rev,tm) % works for retro and prograde
    if norm(V1)~=0 %only do this if the program has run correctly
        disp('Verifying No Earth Impact')
        [crash]=Impact_Check(R1,V1,dt, mu,r_planet);
        if crash==0
            disp('Orbital path given by R1 and V1 does not impact planet within time "dt" given ')
        elseif crash==1
            disp('Orbital path given by R1 and V1 vector passes through planet and is invalid')
        end
    end
end

% When to run Battin Solver
if n_rev==0
    disp('Search Type: Battin Single Revolution')
    [V1,a,ecc,nfeval]=Battin_Lambert_b(R1,R2,mu,dt,del_nu,tm) % works for retro and prograde
    if norm(V1)~=0 %only do this if the program has run correctly
        disp('Verifying No Earth Impact')
        [crash]=Impact_Check(R1,V1,dt, mu,r_planet);
        if crash==0
            disp('Orbital path given by R1 and V1 does not impact planet within time "dt" given ')
        elseif crash==1
            disp('Orbital path given by R1 and V1 vector passes through planet and is invalid')
        end
    end
end

out='Search Complete';



