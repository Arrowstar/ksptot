function [v1, v2] = lambertBattin(r1, r2, dt, numRevs, gmuXfr)
%lambertBattin Summary of this function goes here
%   Detailed explanation goes here
    if(length(r1) == 3)
        r1 = reshape(r1, 3,1);
    else 
        error('r1 not of length 3');
    end
    
    if(length(r2) == 3)
        r2 = reshape(r2, 3,1);
    else
        error('r2 not of length 3');
    end
    
    r1Mag = norm(r1);
    r2Mag = norm(r2);
    
    if(dt<0)
        tm=-1.0;%long way
    elseif(dt>0)
        tm=1.0; %short way
    else
        error('dt = 0; lambert cannot compute');
    end
    dt = abs(dt);
    
    cosDeltaTA = (dot(r1,r2))/(r1Mag*r2Mag);
    sinDeltaTA = tm * sqrt(1 - cosDeltaTA^2);
    deltaTA = atan2(sinDeltaTA,cosDeltaTA);
    deltaTA = AngleZero2Pi(deltaTA);
    
    c=sqrt(r1Mag^2 + r2Mag^2 - 2*r1Mag*r2Mag*cosDeltaTA);
    s = (r1Mag + r2Mag + c)/2;
    epsilon = (r1Mag - r2Mag)/r1Mag;
    
    intemed1 = r2Mag/r1Mag;
    TanSqr2w = (epsilon^2/4) / (sqrt(intemed1) + intemed1*(2 + sqrt(intemed1)));
    
    sinSqrDeltaTAOver4 = (sin(deltaTA/4))^2;
    cosSqrDeltaTAOver4 = (cos(deltaTA/4))^2;
    rop = sqrt(r1Mag*r2Mag) * (cosSqrDeltaTAOver4 + TanSqr2w);
    
    if(tm==1.0)
        l = (sinSqrDeltaTAOver4 + TanSqr2w)/(sinSqrDeltaTAOver4 + TanSqr2w + cos(deltaTA/2));
    elseif(tm==-1.0)
        l = (cosSqrDeltaTAOver4 + TanSqr2w - cos(deltaTA/2)) / (cosSqrDeltaTAOver4 + TanSqr2w);
    end
    
    m = (gmuXfr * dt^2)/(8*rop^3);
    
    x = l;
    x_change = 1;
    loops=0;
    
    while(x_change > 10E-6 && loops <= 30)
            ksi = computeKsi(x, 8);
            
            h1 = ((l+x)^2*(1 + 3*x + ksi)) / ((1+2*x+l)*(4*x + ksi*(3+x)));
            h2 = (m*(x - l + ksi)) / ((1+2*x+l)*(4*x + ksi*(3+x)));
            
            yEqn = @(y) y^3 - y^2 - h1*y^2 - h2;
            y = fzero(yEqn,0); %may want to change the inital guess here
            
            x_new = sqrt(((1-l)/2)^2 + m/(y^2)) - (1+l)/2;
            x_change=abs(x-x_new);
            x = x_new;
            loops=loops+1;
    end

    a = (gmuXfr * dt^2)/(16*(rop^2)*x*(y^2));
    
    if(a > 0.0)
        sinBetaEOver2 = sqrt((s-c)/(2*a));
        betaE = 2*asin(sinBetaEOver2);
        if(deltaTA > pi)
            betaE = -betaE;
        end
        amin = s/2;
        tmin = sqrt(amin^3/gmuXfr) * (pi - betaE + sin(betaE));
        
        alphaE = 2*asin(sqrt(s/(2*a)));
        
        if(dt > tmin)
            alphaE = 2*pi - alphaE;
        end
        
        deltaE = alphaE - betaE;
        
        f = 1 - (a/r1Mag) * (1 - cos(deltaE));
        g = dt - sqrt(a^3/gmuXfr) * (deltaE - sin(deltaE));
        g_dot = 1 - (a/r2Mag) * (1- cos(deltaE));  
    elseif(a < 0.0)
        alphaH = 2*asinh(sqrt(s/(-2*a)));
        betaH = 2*asinh(sqrt((s-c)/(-2*a)));
        deltaH = alphaH-betaH;
        
        f = 1 - (a/r1Mag) * (1 - cosh(deltaH));
        g = dt - sqrt(-(a^3)/gmuXfr) * (sinh(deltaH) - deltaH);
        g_dot = 1 - (a/r2Mag) * (1 - cosh(deltaH));
    else
        error('a = 0.0');
    end

    v1 = (r2 - f*r1)/g;
    v2 = (g_dot*r2-r1)/g;  
    
    v1 = v1';
    v2 = v2';
end

function ksi = computeKsi(x, numLevels) 
    eta = x/(sqrt(1+x) + 1)^2;
    num = 8*(sqrt(1+x) + 1);
    denom = 1;

    if(numLevels>0) 
        denom = 3 + 1/(eta + computeKsi(eta, numLevels-1));
    end
    ksi = num / denom;
%     disp(ksi);
end


