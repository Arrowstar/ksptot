function [sma, ecc, inc, raan, arg, tru] = vect_getKeplerFromState(rVect,vVect,gmu, varargin)
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

numRV = size(rVect,2);

rVect = reshape(rVect,3,numRV);
vVect = reshape(vVect,3,numRV);

[sma, ecc, inc, raan, arg, tru] = vect_getKeplerFromState_Alg(rVect,vVect,gmu);

bool = ecc<1.0;

tru(bool)=AngleZero2Pi(tru(bool));
tru(~bool) = angleNegPiToPi(tru(~bool));

if(consistencyCheck)
    [rVect2,~]=vect_getStatefromKepler(sma, ecc, inc, raan, arg, tru, gmu, false);
    rDang = real(acos(dot(rVect,rVect2)./(sqrt(sum(abs(rVect).^2,1)) .* sqrt(sum(abs(rVect2).^2,1)) )));
    if(all(rDang < 1E-6))
        return;
    end
    
    [rVect3,~]=vect_getStatefromKepler(sma, ecc, inc, raan-rDang, arg+rDang, tru, gmu, false);
    rDang2 = real(acos(dot(rVect,rVect3)./(sqrt(sum(abs(rVect).^2,1)) .* sqrt(sum(abs(rVect3).^2,1)) )));
    if(any(rDang2 < 1E-6))
        raan(rDang2 < 1E-6) = raan(rDang2 < 1E-6) - rDang(rDang2 < 1E-6);
        arg(rDang2 < 1E-6)  = arg(rDang2 < 1E-6)  + rDang(rDang2 < 1E-6);
        raan = AngleZero2Pi(raan);
        arg = AngleZero2Pi(arg);
        
        if(all(rDang2 < 1E-6))
            return;
        end
    end

    [rVect4,~]=vect_getStatefromKepler(sma, ecc, inc, raan+rDang, arg-rDang, tru, gmu, false);
    rDang3 = real(acos(dot(rVect,rVect4)./(sqrt(sum(abs(rVect).^2,1)) .* sqrt(sum(abs(rVect4).^2,1)) )));
    if(any(rDang3 < 1E-6))
        raan(rDang3 < 1E-6) = raan(rDang3 < 1E-6) + rDang(rDang3 < 1E-6);
        arg(rDang3 < 1E-6)  = arg(rDang3 < 1E-6)  - rDang(rDang3 < 1E-6);
        raan = AngleZero2Pi(raan);
        arg = AngleZero2Pi(arg);
        
        if(all(rDang3 < 1E-6))
            return;
        end
    end

    [rVect5,~]=vect_getStatefromKepler(sma, ecc, inc, raan+rDang, arg+rDang, tru, gmu, false);
    rDang4 = real(acos(dot(rVect,rVect5)./(sqrt(sum(abs(rVect).^2,1)) .* sqrt(sum(abs(rVect5).^2,1)) )));
    if(any(rDang4 < 1E-6))
        raan(rDang4 < 1E-6) = raan(rDang4 < 1E-6) + rDang(rDang4 < 1E-6);
        arg(rDang4 < 1E-6)  = arg(rDang4 < 1E-6) + rDang(rDang4 < 1E-6);
        raan = AngleZero2Pi(raan);
        arg = AngleZero2Pi(arg);
        
        if(all(rDang4 < 1E-6))
            return;
        end
    end

    [rVect6,~]=vect_getStatefromKepler(sma, ecc, inc, raan-rDang, arg-rDang, tru, gmu, false);
    rDang5 = real(acos(dot(rVect,rVect6)./(sqrt(sum(abs(rVect).^2,1)) .* sqrt(sum(abs(rVect6).^2,1)) )));
    if(any(rDang5 < 1E-6))
        raan(rDang5 < 1E-6) = raan(rDang5 < 1E-6) - rDang(rDang5 < 1E-6);
        arg(rDang5 < 1E-6)  = arg(rDang5 < 1E-6) - rDang(rDang5 < 1E-6);
        raan = AngleZero2Pi(raan);
        arg = AngleZero2Pi(arg);
        
        if(all(rDang5 < 1E-6))
            return;
        end
    end
    
    [rVect7,~]=vect_getStatefromKepler(sma, ecc, inc, raan, arg, tru-rDang, gmu, false);
    rDang6 = real(acos(dot(rVect,rVect7)./(sqrt(sum(abs(rVect).^2,1)) .* sqrt(sum(abs(rVect7).^2,1)) )));
    if(any(rDang6 < 1E-6))
        tru(rDang6 < 1E-6) = tru(rDang6 < 1E-6) - rDang(rDang6 < 1E-6);
        
        if(all(rDang6 < 1E-6))
            return;
        end
    end
    
    [rVect8,~]=vect_getStatefromKepler(sma, ecc, inc, raan, arg, tru+rDang, gmu, false);
    rDang7 = real(acos(dot(rVect,rVect8)./(sqrt(sum(abs(rVect).^2,1)) .* sqrt(sum(abs(rVect8).^2,1)) )));
    if(any(rDang7 < 1E-6))
        tru(rDang7 < 1E-6) = tru(rDang7 < 1E-6) + rDang(rDang7 < 1E-6);
        
        if(all(rDang7 < 1E-6))
            return;
        end
    end
end