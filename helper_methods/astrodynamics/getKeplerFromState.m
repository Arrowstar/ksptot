function [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(rVect,vVect,gmu, varargin)
% getKeplerFromState() returns Keplerian orbital elements when provided
% with the state (cartesian position vector, cartesian velocity vector) of
% a spacecraft or celestial body.
%
%INPUTS
% rVect - a 3x1 vector that contains the x,y,z components of the orbiting
% body's current position relative to the central body.  Units: [km]
% vVect - a 3x1 vector that contains the x,y,z components of the orbiting
% body's current velocity vector relative to the central body.  Units: [km/sec]
% muCB - the gravitational parameter of the central body.  Units: km^3/s^2
%
%OUTPUTS
% sma - semi-major axis of the orbit.  Units: [km]
% ecc - eccentricity of the orbit.  Units: dimensionless
% inc - inclination angle of the orbit.  Units: radian
% raan - Longitude of ascending node of the orbit.  Units: radian
% arg - Argument of periapse of the orbit.  Units: radian.
% tru - Current true anomaly of the spacecraft/body in the orbit.
% Units: radian
if(~isempty(varargin))
    consistencyCheck = varargin{1};
else
    consistencyCheck = true;
end

rVect = reshape(rVect,3,1);
vVect = reshape(vVect,3,1);

[sma, ecc, inc, raan, arg, tru] = getKeplerFromState_Alg(rVect,vVect,gmu);

if(ecc<1.0)
    tru=AngleZero2Pi(tru);
else
    tru = angleNegPiToPi(tru);
end

% specialCase = false;
% if((ecc >= 1E-10 && (inc < 1E-10 || abs(inc-pi) < 1E-10)) || ...
%    (ecc < 1E-10 && inc >= 1E-10 && abs(inc-pi) >= 1E-10)  || ...        
%    (ecc < 1E-10 && (inc < 1E-10 || abs(inc-pi) < 1E-10)))
%     specialCase = true;
% end

tol = 1E-6;
if(consistencyCheck)
    [rVect2,~]=getStatefromKepler(sma, ecc, inc, raan, arg, tru, gmu, false);
    rDang = real(acos(dotARH(rVect,rVect2)/(norm(rVect) * norm(rVect2))));
    if(rDang < tol)
        return;
    end
    
    [rVect3,~]=getStatefromKepler(sma, ecc, inc, raan-rDang, arg+rDang, tru, gmu, false);
    rDang2 = real(acos(dotARH(rVect,rVect3)/(norm(rVect) * norm(rVect3))));
    if(rDang2 < tol)
        raan = raan-rDang;
        arg  = arg+rDang;
        raan = AngleZero2Pi(raan);
        arg = AngleZero2Pi(arg);
        return;
    end

    [rVect4,~]=getStatefromKepler(sma, ecc, inc, raan+rDang, arg-rDang, tru, gmu, false);
    rDang3 = real(acos(dotARH(rVect,rVect4)/(norm(rVect) * norm(rVect4))));
    if(rDang3 < tol)
        raan = raan+rDang;
        arg  = arg-rDang;
        raan = AngleZero2Pi(raan);
        arg = AngleZero2Pi(arg);
        return;
    end

    [rVect5,~]=getStatefromKepler(sma, ecc, inc, raan+rDang, arg+rDang, tru, gmu, false);
    rDang4 = real(acos(dotARH(rVect,rVect5)/(norm(rVect) * norm(rVect5))));
    if(rDang4 < tol)
        raan = raan+rDang;
        arg  = arg+rDang;
        raan = AngleZero2Pi(raan);
        arg = AngleZero2Pi(arg);
        return;
    end

    [rVect6,~]=getStatefromKepler(sma, ecc, inc, raan-rDang, arg-rDang, tru, gmu, false);
    rDang5 = real(acos(dotARH(rVect,rVect6)/(norm(rVect) * norm(rVect6))));
    if(rDang5 < tol)
        raan = raan-rDang;
        arg  = arg-rDang;
        raan = AngleZero2Pi(raan);
        arg = AngleZero2Pi(arg);
        return;
    end
    
    [rVect7,~]=getStatefromKepler(sma, ecc, inc, raan, arg, tru-rDang, gmu, false);
    rDang6 = real(acos(dotARH(rVect,rVect7)/(norm(rVect) * norm(rVect7))));
    if(rDang6 < tol)
        tru = tru-rDang;
        return;
    end
    
    [rVect8,~]=getStatefromKepler(sma, ecc, inc, raan, arg, tru+rDang, gmu, false);
    rDang7 = real(acos(dotARH(rVect,rVect8)/(norm(rVect) * norm(rVect8))));
    if(rDang7 < tol)
        tru = tru+rDang;
        return;
    end
end