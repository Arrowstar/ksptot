function[crash]=Impact_Check(R1,V1,dt, mu, r_planet)
%% Description
% Given an initial position and velocity, and the parameters of the planet
% the object is orbiting around, will determin if the object hits the
% planet (or in the earth's case comes within 100km of the surface = burned
% up). This is ment as a quick check and uses an unpurturbed propagator for
% speed and simplicity and should not be used for long time periods
 
%% Inputs
% R1 (km) position vector at t=0
% V1 (km/s) veolocity at t=0
% dt (sec) time to propagate orbit
% mu (km^3/sec^2) gravitational constant of the body the orbject is orbiting
% around
% r_planet (km) the radius of the planet (add any atmosphere to this value
% before inputting to the program aka for earth Re=6378 + atmo=100km so
% r_planet = 6478

%% Outputs
% Crash (dimensionless) 
%    0 = has not crashed
%    1 = HAS CRASHED!


%% Calculations

t0=0;
tf=dt;

% propagate R and V forward in time
sys_con;
options = odeset('RelTol',1e-6,'AbsTol',10^-9);
[t1,f1]=ode45(@unperturbed,[t0:tf],[R1,V1],options,mu);
% check the norm of the Ro values to determine if you have crashed into the
% planet
crash=0; %by default
for i=1:length(f1)
    if norm(f1(i,1:3))<r_planet %if it has gone below the radius of the planet
        crash=1; %set crashed to yes
        return %don't evalue anything else
    end
end

end
