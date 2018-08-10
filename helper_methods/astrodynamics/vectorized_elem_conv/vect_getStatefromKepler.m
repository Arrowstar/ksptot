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

tol = 1E-6;
if(consistencyCheck)
    [sma, ecc, inc, raan, arg, tru] = vect_getKeplerFromState(rVect,vVect,gmu, false);
    [rVect2,~]=vect_getStatefromKepler(sma, ecc, inc, raan, arg, tru, gmu, false);
    rDang = real(acos(dot(rVect,rVect2)./(sqrt(sum(abs(rVect).^2,1)) .* sqrt(sum(abs(rVect2).^2,1)) )));
    if(all(rDang < tol))
        return;
    end

    [rVect3,vVect3]=vect_getStatefromKepler(sma, ecc, inc, raan-rDang, arg+rDang, tru, gmu, false);
    rDang2 = real(acos(dot(rVect,rVect3)./(sqrt(sum(abs(rVect).^2,1)) .* sqrt(sum(abs(rVect3).^2,1)) )));
    if(any(rDang2 < tol))
        rVect(:,rDang2 < tol) = rVect3(:,rDang2 < tol);
        vVect(:,rDang2 < tol) = vVect3(:,rDang2 < tol);
        
        if(all(rDang2 < tol))
            return;
        end
    end
    
    [rVect4,vVect4]=vect_getStatefromKepler(sma, ecc, inc, raan+rDang, arg-rDang, tru, gmu, false);
    rDang3 = real(acos(dot(rVect,rVect4)./(sqrt(sum(abs(rVect).^2,1)) .* sqrt(sum(abs(rVect4).^2,1)) )));
    if(any(rDang3 < tol))
        rVect(:,rDang3 < tol) = rVect4(:,rDang3 < tol);
        vVect(:,rDang3 < tol) = vVect4(:,rDang3 < tol);
        
        if(all(rDang3 < tol))
            return;
        end
    end

    [rVect5,vVect5]=vect_getStatefromKepler(sma, ecc, inc, raan+rDang, arg+rDang, tru, gmu, false);
    rDang4 = real(acos(dot(rVect,rVect5)./(sqrt(sum(abs(rVect).^2,1)) .* sqrt(sum(abs(rVect5).^2,1)) )));
    if(any(rDang4 < tol))
        rVect(:,rDang4 < tol) = rVect5(:,rDang4 < tol);
        vVect(:,rDang4 < tol) = vVect5(:,rDang4 < tol);
        
        if(all(rDang4 < tol))
            return;
        end
    end

    [rVect6,vVect6]=vect_getStatefromKepler(sma, ecc, inc, raan-rDang, arg-rDang, tru, gmu, false);
    rDang5 = real(acos(dot(rVect,rVect6)./(sqrt(sum(abs(rVect).^2,1)) .* sqrt(sum(abs(rVect6).^2,1)) )));
    if(any(rDang5 < tol))
        rVect(:,rDang5 < tol) = rVect6(:,rDang5 < tol);
        vVect(:,rDang5 < tol) = vVect6(:,rDang5 < tol);
        
        if(all(rDang5 < tol))
            return;
        end
    end
    
    [rVect7,vVect7]=vect_getStatefromKepler(sma, ecc, inc, raan, arg, tru-rDang, gmu, false);
    rDang6 = real(acos(dot(rVect,rVect7)./(sqrt(sum(abs(rVect).^2,1)) .* sqrt(sum(abs(rVect7).^2,1)) )));
    if(any(rDang6 < tol))
        rVect(:,rDang6 < tol) = rVect7(:,rDang6 < tol);
        vVect(:,rDang6 < tol) = vVect7(:,rDang6 < tol);
        
        if(all(rDang6 < tol))
            return;
        end
    end
    
    [rVect8,vVect8]=vect_getStatefromKepler(sma, ecc, inc, raan, arg, tru+rDang, gmu, false);
    rDang7 = real(acos(dot(rVect,rVect8)./(sqrt(sum(abs(rVect).^2,1)) .* sqrt(sum(abs(rVect8).^2,1)) )));
    if(any(rDang7 < tol))
        rVect(:,rDang7 < tol) = rVect8(:,rDang7 < tol);
        vVect(:,rDang7 < tol) = vVect8(:,rDang7 < tol);
        
        if(all(rDang7 < tol))
            return;
        end
    end
end

