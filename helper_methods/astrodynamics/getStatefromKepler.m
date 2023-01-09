function [rVect,vVect]=getStatefromKepler(sma, ecc, inc, raan, arg, tru, gmu, varargin)
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
% body's current velocity vector relative to the central body.  Units: [km/sec]
if(~isempty(varargin))
    consistencyCheck = varargin{1};
else
    consistencyCheck = true;
end

[rVect, vVect] = getStatefromKepler_Alg(sma, ecc, inc, raan, arg, tru, gmu);

% specialCase = false;
% if((ecc >= 1E-10 && (inc < 1E-10 || abs(inc-pi) < 1E-10)) || ...
%    (ecc < 1E-10 && inc >= 1E-10 && abs(inc-pi) >= 1E-10)  || ...        
%    (ecc < 1E-10 && (inc < 1E-10 || abs(inc-pi) < 1E-10)))
%     specialCase = true;
% end

tol = 1E-6;
if(consistencyCheck)
    [sma2, ecc2, inc2, raan2, arg2, tru2] = getKeplerFromState_Alg(rVect,vVect,gmu);
    [rVect2,~]=getStatefromKepler(sma2, ecc2, inc2, raan2, arg2, tru2, gmu, false);
    rDang = real(acos(dotARH(rVect,rVect2)/(norm(rVect) * norm(rVect2))));
    if(rDang < tol)
        return;
    end

    [rVect3,vVect3]=getStatefromKepler(sma, ecc, inc, raan-rDang, arg+rDang, tru, gmu, false);
    rDang2 = real(acos(dotARH(rVect,rVect3)/(norm(rVect) * norm(rVect3))));
    if(rDang2 < tol)
        rVect = rVect3;
        vVect = vVect3;
        return;
    end
    
    [rVect4,vVect4]=getStatefromKepler(sma, ecc, inc, raan+rDang, arg-rDang, tru, gmu, false);
    rDang3 = real(acos(dotARH(rVect,rVect4)/(norm(rVect) * norm(rVect4))));
    if(rDang3 < tol)
        rVect = rVect4;
        vVect = vVect4;
        return;
    end

    [rVect5,vVect5]=getStatefromKepler(sma, ecc, inc, raan+rDang, arg+rDang, tru, gmu, false);
    rDang4 = real(acos(dotARH(rVect,rVect5)/(norm(rVect) * norm(rVect5))));
    if(rDang4 < tol)
        rVect = rVect5;
        vVect = vVect5;
        return;
    end

    [rVect6,vVect6]=getStatefromKepler(sma, ecc, inc, raan-rDang, arg-rDang, tru, gmu, false);
    rDang5 = real(acos(dotARH(rVect,rVect6)/(norm(rVect) * norm(rVect6))));
    if(rDang5 < tol)
        rVect = rVect6;
        vVect = vVect6;
        return;
    end
    
    [rVect7,vVect7]=getStatefromKepler(sma, ecc, inc, raan, arg, tru-rDang, gmu, false);
    rDang6 = real(acos(dotARH(rVect,rVect7)/(norm(rVect) * norm(rVect7))));
    if(rDang6 < tol)
        rVect = rVect7;
        vVect = vVect7;
        return;
    end
    
    [rVect8,vVect8]=getStatefromKepler(sma, ecc, inc, raan, arg, tru+rDang, gmu, false);
    rDang7 = real(acos(dotARH(rVect,rVect8)/(norm(rVect) * norm(rVect8))));
    if(rDang7 < tol)
        rVect = rVect8;
        vVect = vVect8;
        return;
    end
end

