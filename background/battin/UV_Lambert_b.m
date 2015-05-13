function[V1,a,ecc,nfeval,dt_actual]=UV_Lambert(R1,R2,mu,dt,del_nu,n_rev,tm)
%% Description
% This function calculates the solution to Lambert's problem using
% Universal Variables (April 25, 2012 notes) and Vallado 485.

%% Inputs
% R1 (km) position vector at time=1
% R2 (km) position vector at time=2
% mu (km^3/s^2) gravitational constant of the body the object is orbiting
% around
% dt (sec) the time 
% del_nu (rad) angle between R1 and R2 
% n_rev (dimensionless) the number of times the object revolves around the
% central body before getting to R2.


%% Outputs
% V1 (km/s) velocity at time=1
% a (km) semimajor axis of orbit
% ecc (dimensionless) eccentricity of orbit
% nfeval (dimensionless) the number of function evaluations required to
% reach this result
% dt_actual (sec) calculated transfer time should match closely to dt

%% Calculations
r1=norm(R1);
r2=norm(R2);


A=tm*sqrt(r1*r2*(1+cos(del_nu))); %Works for +tm multiren and single rev
%both ways

%A=sqrt(r1*r2*(1+cos(del_nu))); %<- might work for multi-rev
% A=sqrt(r1*r2)*sin(del_nu)/sqrt(1-cos(del_nu)); % Where did this come
% from???

if A==0
    disp('Error: A=0, can"t calculate orbit - vallado pg 489')
end

z_new=0;
tol=1e-6;
error=2; %kickstart loop
dt_new=dt;

% establish valid upper and lower bounds for z. We will use the bisection
% technique (see Vallado's program 'lambertu.m'). The bounds changes
% based on the number of revolutions.
if n_rev==0
    zupp=4*pi^2; 
    zlow=-4*pi;
elseif n_rev==1
    zupp=16*pi^2; 
    zlow=4*pi^2;
elseif n_rev>1
    zupp=32*pi^2; 
    zlow=16*pi^2;
end

factor=0.8;

fy = @(z,S,C) r1+r2-A*(1-z*S)/sqrt(C);

nfeval=0;

% update z based on Bisection method highlighted in vallado and vallado's
% computer code
while error>=tol
    z_old=z_new;
    dt_old=dt_new;
    S=stumpffS(z_old); %call the two stumpff functions
    C=stumpffC(z_old);
    if C>0.0001 %only use this function when C is not close to zero (singular)
        y=fy(z_old,S,C);
    else
        y=r1+r2; %Use this when C is close to zero
    end
    nfeval=nfeval+1;
    if A>0 && y<0
        % Now we must update the value of y by iterating on z. HOWEVER, we
        % are only going to allow a certain number of iterations. The
        % number of iterations describes how accurate of a cut to make on
        % the lower boundry. After yctr>5, we may still have a negative y
        % value, but we must continue on through the rest of the code. This
        % is alright because iterating in the following loop cuts down the
        % possible z values in the lower boundry region.
        yctr=1; 
        while y<0 && yctr<10
            zlow=z_old; %limit the future values of z by cutting off all values lower than and including the current z value
            z_new=factor/S*(1-(r1+r2)*sqrt(C)/A);
            S=stumpffS(z_new); %update based on new Z
            C=stumpffC(z_new); %update based on new Z
            z_old=z_new;
            y=fy(z_old,S,C);
            nfeval=nfeval+1;
            yctr=yctr+1;
        end
    end
    %update Ki
    if y<=0 || C<0.0001
        KI=0; %so that we don't get imaginary terms
    else
        KI=sqrt(y/C);
    end
    %update dt
    dt_new=(KI^3*S+A*sqrt(y))/sqrt(mu); %we can compair imaginary and imaginary terms here
    error=abs(dt_new-dt_old);
    %update the boundry for z
    if dt_new>dt
        zupp=z_old; %reduce the size of the upper boundry
    elseif dt_new<dt
        zlow=z_old;
    end
    %update z
    z_new=(zupp+zlow)/2;
end
dt_actual=dt_new;
f=1-y/r1;
g=A*sqrt(y/mu);
V1=(R2-f*R1)/g;

%use kepler to find the rest of the values
[ecc,a,nu,M,inc,RAAN,w]=RV2COE(R1,V1,mu);
