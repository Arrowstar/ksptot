function [rVect,vVect]=vect_getStatefromKepler(sma, ecc, inc, raan, arg, tru, gmu, varargin)
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
if(~isempty(varargin))
    consistencyCheck = varargin{1};
else
    consistencyCheck = true;
end

[rVect, vVect] = vect_getStatefromKepler_Alg(sma, ecc, inc, raan, arg, tru, gmu);

if(consistencyCheck)
    [sma, ecc, inc, raan, arg, tru] = vect_getKeplerFromState(rVect,vVect,gmu, false);
    [rVect2,~]=vect_getStatefromKepler(sma, ecc, inc, raan, arg, tru, gmu, false);
    rDang = real(acos(dot(rVect,rVect2)./(sqrt(sum(abs(rVect).^2,1)) .* sqrt(sum(abs(rVect2).^2,1)) )));
    if(all(rDang < 1E-6))
        return;
    end

    [rVect3,vVect3]=vect_getStatefromKepler(sma, ecc, inc, raan-rDang, arg+rDang, tru, gmu, false);
    rDang2 = real(acos(dot(rVect,rVect3)./(sqrt(sum(abs(rVect).^2,1)) .* sqrt(sum(abs(rVect3).^2,1)) )));
    if(any(rDang2 < 1E-6))
        rVect(:,rDang2 < 1E-6) = rVect3(:,rDang2 < 1E-6);
        vVect(:,rDang2 < 1E-6) = vVect3(:,rDang2 < 1E-6);
        
        if(all(rDang2 < 1E-6))
            return;
        end
    end
    
    [rVect4,vVect4]=vect_getStatefromKepler(sma, ecc, inc, raan+rDang, arg-rDang, tru, gmu, false);
    rDang3 = real(acos(dot(rVect,rVect4)./(sqrt(sum(abs(rVect).^2,1)) .* sqrt(sum(abs(rVect4).^2,1)) )));
    if(any(rDang3 < 1E-6))
        rVect(:,rDang3 < 1E-6) = rVect4(:,rDang3 < 1E-6);
        vVect(:,rDang3 < 1E-6) = vVect4(:,rDang3 < 1E-6);
        
        if(all(rDang3 < 1E-6))
            return;
        end
    end

    [rVect5,vVect5]=vect_getStatefromKepler(sma, ecc, inc, raan+rDang, arg+rDang, tru, gmu, false);
    rDang4 = real(acos(dot(rVect,rVect5)./(sqrt(sum(abs(rVect).^2,1)) .* sqrt(sum(abs(rVect5).^2,1)) )));
    if(any(rDang4 < 1E-6))
        rVect(:,rDang4 < 1E-6) = rVect5(:,rDang4 < 1E-6);
        vVect(:,rDang4 < 1E-6) = vVect5(:,rDang4 < 1E-6);
        
        if(all(rDang4 < 1E-6))
            return;
        end
    end

    [rVect6,vVect6]=vect_getStatefromKepler(sma, ecc, inc, raan-rDang, arg-rDang, tru, gmu, false);
    rDang5 = real(acos(dot(rVect,rVect6)./(sqrt(sum(abs(rVect).^2,1)) .* sqrt(sum(abs(rVect6).^2,1)) )));
    if(any(rDang5 < 1E-6))
        rVect(:,rDang5 < 1E-6) = rVect6(:,rDang5 < 1E-6);
        vVect(:,rDang5 < 1E-6) = vVect6(:,rDang5 < 1E-6);
        
        if(all(rDang5 < 1E-6))
            return;
        end
    end
    
    [rVect7,vVect7]=vect_getStatefromKepler(sma, ecc, inc, raan, arg, tru-rDang, gmu, false);
    rDang6 = real(acos(dot(rVect,rVect7)./(sqrt(sum(abs(rVect).^2,1)) .* sqrt(sum(abs(rVect7).^2,1)) )));
    if(any(rDang6 < 1E-6))
        rVect(:,rDang6 < 1E-6) = rVect7(:,rDang6 < 1E-6);
        vVect(:,rDang6 < 1E-6) = vVect7(:,rDang6 < 1E-6);
        
        if(all(rDang6 < 1E-6))
            return;
        end
    end
    
    [rVect8,vVect8]=vect_getStatefromKepler(sma, ecc, inc, raan, arg, tru+rDang, gmu, false);
    rDang7 = real(acos(dot(rVect,rVect8)./(sqrt(sum(abs(rVect).^2,1)) .* sqrt(sum(abs(rVect8).^2,1)) )));
    if(any(rDang7 < 1E-6))
        rVect(:,rDang7 < 1E-6) = rVect8(:,rDang7 < 1E-6);
        vVect(:,rDang7 < 1E-6) = vVect8(:,rDang7 < 1E-6);
        
        if(all(rDang7 < 1E-6))
            return;
        end
    end
end

