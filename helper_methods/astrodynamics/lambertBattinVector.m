function [v1, v2] = lambertBattinVector(r1, r2, dt, numRevs, gmu)
%lambertBattin Summary of this function goes here
%   Detailed explanation goes here
    if(size(r1,1) ~= 3)
        error('r1 not of length 3');
    end
    
    if(size(r2,1) ~= 3)
        error('r2 not of length 3');
    end
    
    r1Mag = sqrt(sum(abs(r1).^2,1));
    r2Mag = sqrt(sum(abs(r2).^2,1));
    
    tm = zeros(size(dt));
    if(any(dt(dt<0)))
        B = dt<0;
        tm(B) = -1.0;
    end
    if(any(dt(dt>0)))
        B = dt>0;
        tm(B) = 1.0;
    end
    if(any(dt(dt==0)))
        error('dt = 0; lambert cannot compute');
    end
    dt = abs(dt);
    
    cosDeltaTA = dot(r1,r2,1)./(r1Mag.*r2Mag);
    sinDeltaTA = tm .* sqrt(1 - cosDeltaTA.^2);
    deltaTA = atan2(sinDeltaTA,cosDeltaTA);
    deltaTA = AngleZero2Pi(deltaTA);
    
    c = sqrt(r1Mag.^2 + r2Mag.^2 - 2.*r1Mag.*r2Mag.*cosDeltaTA);
    s = (r1Mag + r2Mag + c)./2;
    epsilon = (r2Mag - r1Mag)./r1Mag;
    
    intemed1 = r2Mag./r1Mag;
    TanSqr2w = (epsilon.^2/4) ./ (sqrt(intemed1) + intemed1.*(2 + sqrt(intemed1)));
    
    sinSqrDeltaTAOver4 = (sin(deltaTA/4)).^2;
    cosSqrDeltaTAOver4 = (cos(deltaTA/4)).^2;
    rop = sqrt(r1Mag.*r2Mag) .* (cosSqrDeltaTAOver4 + TanSqr2w);
    
    l = zeros(size(tm));
    if(any(tm(tm==1.0)))
        bool = tm==1.0;
        l(bool) = (sinSqrDeltaTAOver4(bool) + TanSqr2w(bool))./(sinSqrDeltaTAOver4(bool) + TanSqr2w(bool) + cos(deltaTA(bool)/2));
    end
    if(any(tm(tm==-1.0)))
        bool = tm==-1.0;
        l(bool) = (cosSqrDeltaTAOver4(bool) + TanSqr2w(bool) - cos(deltaTA(bool)/2)) ./ (cosSqrDeltaTAOver4(bool) + TanSqr2w(bool));
    end
        
    m = (gmu .* dt.^2)./(8*rop.^3);
    
    x = l;
    x_change = 1;
    loops=0;
    while(any(x_change > 1E-6) && loops <= 30)
            ksi = computeKsi(x, 20);
            
            h1 = ((l+x).^2.*(1 + 3.*x + ksi)) ./ ((1+2.*x+l).*(4.*x + ksi.*(3+x)));
            h2 = (m.*(x - l + ksi)) ./ ((1+2.*x+l).*(4.*x + ksi.*(3+x)));
            
            B=27*h2./(4*(1+h1).^3);
            U=B./(2*(sqrt(1+B)+1));
            K_U=Kay(U);
            y=(1+h1)./3.*(2+sqrt(1+B)./(1+2*U.*K_U.^2));
            
            x_new = sqrt(((1-l)/2).^2 + m./(y.^2)) - (1+l)/2;
            x_change=abs(x-x_new);
            x = x_new;
            loops=loops+1;
    end
    a = (gmu .* dt.^2)./(16*(rop.^2).*x.*(y.^2));
    
    sinBetaEOver2 = zeros(size(a));
    betaE = zeros(size(a));
    amin = zeros(size(a));
    tmin = zeros(size(a));
    alphaE = zeros(size(a));
    deltaE = zeros(size(a));
    alphaH = zeros(size(a));
    betaH = zeros(size(a));
    deltaH = zeros(size(a));
    f = zeros(size(a));
    g = zeros(size(a));
    g_dot = zeros(size(a));
    if(any(a(a > 0.0)))
        bool = a > 0.0;
        
        sinBetaEOver2(bool) = sqrt((s(bool)-c(bool))./(2*a(bool)));
        betaE(bool) = real(2*asin(sinBetaEOver2(bool))); %real needed to prevent complex numbers from appearing
        
        if(any(deltaTA(bool) > pi))
            bool2 = bool & deltaTA > pi;
            betaE(bool2) = -betaE(bool2);
        end

        amin(bool) = s(bool)./2;
        tmin(bool) = sqrt(amin(bool).^3./gmu(bool)) .* (pi - betaE(bool) + sin(betaE(bool)));
        
        alphaE(bool) = real(2*asin(sqrt(s(bool)./(2*a(bool))))); %real needed to prevent complex numbers from appearing
        
        if(any(dt > tmin))
            bool2 = bool & dt > tmin;
            alphaE(bool2) = 2*pi - alphaE(bool2);
        end
        
        deltaE(bool) = alphaE(bool) - betaE(bool);
        
        f(bool)     = real(1 - (a(bool)./r1Mag(bool)) .* (1 - cos(deltaE(bool)))); %real() necessary to prevent complex doubles from forming
        g(bool)     = real(dt(bool) - sqrt(a(bool).^3./gmu(bool)) .* (deltaE(bool) - sin(deltaE(bool)))); %real() necessary to prevent complex doubles from forming
        g_dot(bool) = real(1 - (a(bool)./r2Mag(bool)) .* (1- cos(deltaE(bool))));  %real() necessary to prevent complex doubles from forming
    end
    if(any(a(a < 0.0)))
        bool = a < 0.0;
        
        alphaH(bool) = 2*asinh(sqrt(s(bool)./(-2*a(bool))));
        betaH(bool)  = 2*asinh(sqrt((s(bool)-c(bool))./(-2*a(bool))));
        deltaH(bool) = alphaH(bool)-betaH(bool);
        
        f(bool)     = real(1 - (a(bool)./r1Mag(bool)) .* (1 - cosh(deltaH(bool)))); %real() necessary to prevent complex doubles from forming
        g(bool)     = real(dt(bool) - sqrt(-(a(bool).^3)./gmu(bool)) .* (sinh(deltaH(bool)) - deltaH(bool))); %real() necessary to prevent complex doubles from forming
        g_dot(bool) = real(1 - (a(bool)./r2Mag(bool)) .* (1 - cosh(deltaH(bool)))); %real() necessary to prevent complex doubles from forming
    end
    if(any(a(a == 0.0)))
        error('a = 0.0');
    end
    
    v1 = bsxfun(@rdivide,r2 - bsxfun(@times,r1,f),g);
    v2 = bsxfun(@rdivide,bsxfun(@times,r2,g_dot) - r1,g);
end

function ksi = computeKsi(x, numLevels) 
    eta = x./(sqrt(1+x) + 1).^2;
    num = 8.*(sqrt(1+x) + 1);
    denom = 1;

    if(numLevels>0) 
        denom = 3 + 1./(eta + computeKsi(eta, numLevels-1));
    end
    ksi = num ./ denom;
%     disp(ksi);
end

function [K_U]=Kay(U)
    % setup the C variable
    c(1)=4/27;   %@n=0
    c(2)=8/27; %@n=1
    c(3)=208/891; %n=2
    c(4)=340/1287; %@n=3
    c(5)=700/2907;
    c(6)=928/3591;
    c(7)=296/1215;
    c(8)=1804/7047;
    c(9)=2548/10395;
    c(10)=2968/11655;
    c(11)=3904/15867;
    c(12)=884/3483;
    c(13)=5548/22491;
    c(14)=6160/24327;
    c(15)=7480/30267;
    c(16)=8188/32391;
    c(17)=1940/7839;
    c(18)=10504/41607;
    c(19)=12208/49275;
    c(20)=13108/51975;

    % sum up all the intermediate variables
    Z=1+c(20).*U;
    Z=1+c(19).*U./Z;
    Z=1+c(18).*U./Z;
    Z=1+c(17).*U./Z;
    Z=1+c(16).*U./Z;
    Z=1+c(15).*U./Z;
    Z=1+c(14).*U./Z;
    Z=1+c(13).*U./Z;
    Z=1+c(12).*U./Z;
    Z=1+c(11).*U./Z;
    Z=1+c(10).*U./Z;
    Z=1+c(9).*U./Z;
    Z=1+c(8).*U./Z;
    Z=1+c(7).*U./Z;
    Z=1+c(6).*U./Z;
    Z=1+c(5).*U./Z;
    Z=1+c(4).*U./Z;
    Z=1+c(3).*U./Z;
    Z=1+c(2).*U./Z;
    Z=1+c(1).*U./Z;

    K_U=1./(3*Z);
end