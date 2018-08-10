function [sma, ecc, inc, longAscNode, ArgPeri, TrueAnom] = getKeplerFromStateOld(rVect,vVect,muCB)
% getKeplerFromState() returns Keplerian orbital elements when provided
% with the state (cartesian position vector, cartesian velocity vector) of
% a spacecraft or celestial body.
%
% INPUTS
% rVect - a 3x1 vector that contains the x,y,z components of the orbiting
% body's current position relative to the central body.  Units: [km]
% vVect - a 3x1 vector that contains the x,y,z components of the orbiting
% body's current velocity vector relative to the central body.  Units:
% [km/sec]
% muCB - the gravitational parameter of the central body.  Units: km^3/s^2
%
%OUTPUTS
% sma - semi-major axis of the orbit.  Units: [km]
% ecc - eccentricity of the orbit.  Units: dimensionless
% inc - inclination angle of the orbit.  Units: radian
% longAscNode - Longitude of ascending node of the orbit.  Units: radian
% ArgPeri - Argument of periapse of the orbit.  Units: radian.
% TrueAnom - Current true anomaly of the spacecraft/body in the orbit.
% Units: radian

r=norm(rVect);
rUnitVect=rVect/r;
v=norm(vVect);

hVect=cross(rVect,vVect);
h=norm(hVect);
hUnitVect=hVect/h;
ThetaUnitVect=cross(hUnitVect,rUnitVect);

Energy=v^2/2 - muCB/r;
sma=-muCB/(2*Energy);

p=h^2/muCB;
ecc=real(sqrt(-p/sma + 1));

inc=AngleZero2Pi(real(acos(hUnitVect(3))));

i_hat = [1, 0, 0];
e_vect = (cross(vVect, hVect)/muCB) - rVect/r;
if(abs(inc)<=1E-10)
    cosLongPeri = dot(i_hat, e_vect) / (norm(i_hat) * norm(e_vect));
    if(e_vect(2) < 0)
        cosLongPeri = 2*pi - cosLongPeri;
    end  
    longAscNode = 0; %these two lines are my convention, hopefully they work
    ArgPeri = cosLongPeri;
else
    k_hat = [0, 0, 1];
    n_hat = cross(k_hat, hUnitVect);
    cosRAAN = dot(i_hat, n_hat)/(norm(i_hat) * norm(n_hat));
    raan = acos(cosRAAN);
    if(n_hat(2) < 0)
        raan = 2*pi - raan;
    end
    longAscNode = raan;

    cosArg = dot(n_hat, e_vect)/(norm(n_hat) * norm(e_vect));
    arg = acos(cosArg);
    if(e_vect(3) < 0)
        arg = 2*pi - arg;
    end
    ArgPeri = arg;    
end

  
if(ecc>0)
    cosTru = dot(e_vect, rVect) / (norm(e_vect) * norm(rVect));
    tru = acos(cosTru);
    if(dot(rVect,vVect)<0)
        tru=-tru;
    end
    TrueAnom = tru;
%     TrueAnom=real(acos((p/r - 1)/(ecc)));
%     if(dot(rVect,vVect)<0)
%         TrueAnom=-TrueAnom;
%     end
elseif(ecc==0 && inc>0)
    nVect = cross([0 0 1], hUnitVect)/norm(cross([0 0 1], hUnitVect));
    u = acos(dot(nVect,rVect)/(norm(nVect)*norm(rVect)));
%     if(dot(nVect,vVect)>0)
%         u = 2*pi - u;
%     end
    if(rVect(3) < 0)
        u = 2*pi - u;
    end
    TrueAnom = u;
elseif(ecc==0 && inc==0)
    l = acos(rVect(1)/norm(rVect));
%     if(vVect(1)>0)
%         l = 2*pi-l;
%     end
    if(rVect(2)<0)
        l = 2*pi-l;
    end
    TrueAnom = l;
end

if(ecc<1.0)
    TrueAnom=AngleZero2Pi(TrueAnom);
end

% longAscNode_1=AngleZero2Pi(asin(hUnitVect(1)/sin(inc)));
% longAscNode_2=AngleZero2Pi(pi-asin(hUnitVect(1)/sin(inc)));
% longAscNode_3=AngleZero2Pi(acos(-hUnitVect(2)/sin(inc)));
% longAscNode_4=AngleZero2Pi(-acos(-hUnitVect(2)/sin(inc)));
% 
% longAscNodeSet1=[longAscNode_1,longAscNode_2];
% longAscNodeSet2=[longAscNode_3,longAscNode_4];
% 
% [val,ia,ib]=intersect(round(1000*longAscNodeSet1)/1000,round(1000*longAscNodeSet2)/1000);
% if(isempty(val))
%     longAscNode=0;
% else
%     longAscNode=AngleZero2Pi(longAscNodeSet1(ia));
% end
% longAscNode = real(longAscNode);

% cosTru = dot(e_vect, rVect) / (norm(e_vect) * norm(rVect));
% tru = acos(cosTru);
% if(dot(rVect,vVect)<0)
%     tru=-tru;
% end
% TrueAnom = tru;

% Theta_1=AngleZero2Pi(asin(rUnitVect(3)/sin(inc)));
% Theta_2=AngleZero2Pi(pi-asin(rUnitVect(3)/sin(inc)));
% Theta_3=AngleZero2Pi(acos(ThetaUnitVect(3)/sin(inc)));
% Theta_4=AngleZero2Pi(-acos(ThetaUnitVect(3)/sin(inc)));
% 
% ThetaSet1=[Theta_1,Theta_2];
% ThetaSet2=[Theta_3,Theta_4];
% 
% [val,ia,ib]=intersect(round(1000*ThetaSet1)/1000,round(1000*ThetaSet2)/1000);
% if(isempty(val))
%     Theta=AngleZero2Pi(TrueAnom);
% else
%     Theta=AngleZero2Pi(ThetaSet1(ia));
% end
% 
% ArgPeri=real(AngleZero2Pi(Theta-TrueAnom));