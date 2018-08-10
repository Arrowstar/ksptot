function [rVect,vVect]=getStatefromKeplerOld(sma, ecc, inc, longAscNode, ArgPeri, TrueAnom, muCB)
% getStatefromKepler() takes a set of Keplerian orbital elements and turns
% them into a set of state vectors (position and velocity vectors).
% 
% INPUTS
% sma - semi-major axis of the orbit.  Units: [km]
% ecc - eccentricity of the orbit.  Units: dimensionless
% inc - inclination angle of the orbit.  Units: radian
% longAscNode - Longitude of ascending node of the orbit.  Units: radian
% ArgPeri - Argument of periapse of the orbit.  Units: radian.
% TrueAnom - Current true anomaly of the spacecraft/body in the orbit.
% Units: radian
% muCB - the gravitational parameter of the central body.  Units: km^3/s^2
% ALL ANGLES EXPECTED BETWEEN 0 - 2*pi!  DO NOT USE NEGATIVE ANGLES!
% 
% OUTPUTS
% rVect - a 3x1 vector that contains the x,y,z components of the orbiting
% body's current position relative to the central body.  Units: [km]
% vVect - a 3x1 vector that contains the x,y,z components of the orbiting
% body's current velocity vector relative to the central body.  Units:
% [km/sec]

TransMatrix=Euler313(longAscNode,inc,ArgPeri+TrueAnom);

p=sma*(1-ecc^2);
r=p/(1+ecc*cos(TrueAnom));
rVect=r*TransMatrix(:,1);

h=sqrt(muCB*p);
hVect=h*TransMatrix(:,3);

v=sqrt(2*(muCB/r - muCB/(2*sma)));
FPA=real(acos(h/(r*v)));
if(TrueAnom>pi)
    FPA=-FPA;
end

vLocalVect=[v*sin(FPA); v*cos(FPA); 0];
vVect=TransMatrix*vLocalVect;
