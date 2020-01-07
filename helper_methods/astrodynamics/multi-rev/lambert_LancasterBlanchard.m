function [V1, V2, exitflag] = lambert_LancasterBlanchard(r1vec, r2vec, dt, m, gmu)
%{
LAMBERT_LANCASTERBLANCHARD       High-Thrust Lambert-targeter

lambert_LancasterBlanchard() uses the method developed by 
Lancaster & Blancard, as described in their 1969 paper. Initial values, 
and several details of the procedure, are provided by R.H. Gooding, 
as described in his 1990 paper. 
%}

% Please report bugs and inquiries to: 
%
% Name       : Rody P.S. Oldenhuis
% E-mail     : oldenhuis@gmail.com    (personal)
%              oldenhuis@luxspace.lu  (professional)
% Affiliation: LuxSpace sàrl
% Licence    : BSD


% If you find this work useful, please consider a donation:
% https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=6G3S5UYM7HJ3N
      
    % ADJUSTED FOR EML-COMPILATION 29/Sep/2009
    
    if(size(r1vec,1) ~= 3)
        error('r1 not of length 3');
    end
    
    if(size(r2vec,1) ~= 3)
        error('r2 not of length 3');
    end
       
    % manipulate input
    tol     = 1e-12;                            % optimum for numerical noise v.s. actual precision
    r1      = sqrt(sum(abs(r1vec).^2,1));       % magnitude of r1vec
    r2      = sqrt(sum(abs(r2vec).^2,1));       % magnitude of r2vec    
    r1unit  = bsxfun(@rdivide,r1vec,r1);        % unit vector of r1vec        
    r2unit  = bsxfun(@rdivide,r2vec,r2);        % unit vector of r2vec
    crsprod = cross(r1vec, r2vec, 1);           % cross product of r1vec and r2vec
    mcrsprd = sqrt(sum(abs(crsprod).^2,1));     % magnitude of that cross product
    crpunit = bsxfun(@rdivide,crsprod,mcrsprd); % unit vector of cross product
    th1unit = cross(crpunit, r1unit, 1);   % unit vectors in the tangential-directions
    th2unit = cross(crpunit, r2unit, 1);   
    
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
    
    cosDeltaTA = dot(r1vec,r2vec,1)./(r1.*r2);
    sinDeltaTA = tm .* sqrt(1 - cosDeltaTA.^2);
    deltaTA = atan2(sinDeltaTA,cosDeltaTA);
    deltaTA = AngleZero2Pi(deltaTA);
    
    % left-branch
    leftbranch = sign(m); m = abs(m);
    
    % define constants
    c  = sqrt(r1.^2 + r2.^2 - 2.*r1.*r2.*cos(deltaTA));
    s  = (r1 + r2 + c) / 2;
    T  = sqrt(8.*gmu./s.^3) .* dt;
    q  = sqrt(r1.*r2)./s .* cos(deltaTA/2);
    
    % general formulae for the initial values (Gooding)
    % -------------------------------------------------
    
    % some initial values
    T0  = LancasterBlanchard(zeros(size(q)), q, m);
    Td  = T0 - T;
    phr = mod(2*bsxfun(@atan2, 1 - q.^2, 2*q), 2*pi);
    
    % initial output is pessimistic
    V1 = NaN(size(r1vec));    V2 = V1; 
    
    x0 = zeros(size(m));
    
    % single-revolution case
    boolM = m == 0;
    boolNm = not(boolM);
    if (any(boolM))
        x01 = T0(boolM).*Td(boolM)/4./T(boolM);
        
        bool1 = Td(boolM) > 0;
        bool2 = not(bool1);
        if (any(bool1))
            x0(boolM & bool1) = x01(bool1);
        end
        if(bool2)
            x01(bool2) = Td(bool2)./(4 - Td(bool2));
            x02(bool2) = -sqrt( -Td(bool2)./(T(bool2)+T0(bool2)/2) );
            W   = x01 + 1.7*sqrt(2 - phr(bool2)/pi);
            
            bool3 = W >= 0;
            bool4 = not(bool3);
            x03 = zeros(size(x01));
            if (any(bool3))
                x03(bool3) = x01(bool3);
            else
                x03(bool4) = x01(bool4) + (-W).^(1/16).*(x02(bool4) - x01(bool4)); 
            end
            lambda = 1 + x03.*(1 + x01)/2 - 0.03*x03.^2.*sqrt(1 + x01);
            x0(boolM & bool2) = lambda.*x03;
        end
        
        % this estimate might not give a solution
        if (x0(boolM) < -1), exitflag = -1; return; end
        
    % multi-revolution case
    end
    if(any(boolNm))
        
        % determine minimum Tp(x)
        xMpi = 4./(3*pi*(2.*m(boolNm) + 1));
        
        phrM = phr(boolNm);
        
        bool1 = phrM < pi;
        bool2 = phrM > pi;
        bool3 = not(bool1 | bool2);
        xM0 = zeros(size(xMpi));
        if (any(bool1))
            xM0(bool1) = xMpi(bool1).*(phrM(bool1)/pi).^(1/8);
        end
        if(any(bool2))
            xM0(bool2) = xMpi(bool2).*(2 - (2 - phrM(boolNm & bool2)/pi).^(1/8));
        end
        if(any(bool3))
            xM0(bool3) = zeros(size(xMpi(bool3)));
        end
        
        % use Halley's method
        xM = xM0;  
        Tp = inf;  
        iterations = 0;
        bool1 = abs(Tp) > tol;
        while(any(bool1))            
            % iterations
            iterations = iterations + 1;  
            
            % compute first three derivatives
            [~, Tp, Tpp, Tppp] = LancasterBlanchard(xM, q, m(boolNm));  
            bool1 = abs(Tp) > tol;
            
            % new value of xM
            xMp = xM;
            xM  = xM - 2*Tp.*Tpp ./ (2*Tpp.^2 - Tp.*Tppp);   
            
            % escape clause
            if mod(iterations, 7), xM = (xMp+xM)/2; end
            
            % the method might fail. Exit in that case
            if (iterations > 25), exitflag = -2; return; end
        end
        
        % xM should be elliptic (-1 < x < 1)
        % (this should be impossible to go wrong)
        if any(xM < -1) || any(xM > 1), exitflag = -1; return; end
        
        % corresponding time
        TM = LancasterBlanchard(xM, q, m(boolNm));
        
        % T should lie above the minimum T
        if any(TM > T(boolNm)), exitflag = -1; return; end
        
        % find two initial values for second solution (again with lambda-type patch)
        % --------------------------------------------------------------------------
        
        % some initial values
        TmTM  = T(boolNm) - TM;   
        T0mTM = T0(boolNm) - TM;
        [~, Tp, Tpp] = LancasterBlanchard(xM, q(boolNm), m(boolNm));%#ok
                
        % first estimate (only if m > 0)
        %LEFT OFF HERE AT LINE 190!
        bool1 = leftbranch(boolNm) > 0;
        bool11 = boolNm & leftbranch > 0;
        bool2 = not(bool1);
        bool22 = boolNm & not(leftbranch > 0);
        if(any(bool1))
            x   = sqrt( TmTM(bool1) ./ (Tpp(bool1)/2 + TmTM(bool1)./(1-xM(bool1)).^2) );
            W   = xM(bool1) + x;
            W   = 4*W./(4 + TmTM(bool1)) + (1 - W).^2;
            x0(bool11)  = x.*(1 - (1 + m(bool11) + (deltaTA(bool11) - 1/2)) ./ (1 + 0.15*m(bool11)).*x.*(W/2 + 0.03*x.*sqrt(W))) + xM(bool1);
            
            % first estimate might not be able to yield possible solution
            if any(x0(bool11) > 1), exitflag = -1; return; end
            
        % second estimate (only if m > 0)
        end
        if(any(bool2))
            bool3 = Td(boolNm) > 0;
            bool4 = not(bool3);
            
            bool5 = bool22 & Td > 0;
            bool6 = bool22 & not(Td > 0);
            
            if (any(bool3))
                x0(bool5) = xM(bool3) - sqrt(TM(bool3)./(Tpp(bool3)/2 - TmTM(bool3).*(Tpp(bool3)/2./T0mTM(bool3) - 1./xM(bool3).^2)));
            end
            if(any(bool4))
                x00 = Td(bool6) ./ (4 - Td(bool6));
                W = x00 + 1.7*sqrt(abs(2*(1 - phr(bool6))));
                
                bool7 = W >= 0; %PROBABLY GOING TO BE AN ISSUE WITH THIS SEGMENT AND ALL THE DUMB BOOLEANS \/
                bool8 = not(bool7);
                x03 = zeros(size(x00));
                if (any(bool7))
                    x03(bool7) = x00(bool7);
                end
                if(any(bool8))
                    x03(bool8) = x00(bool8) - sqrt((-W(bool8)).^(1/8)).*(x00(bool8) + sqrt(-Td(bool8)./(1.5.*T0(bool8) - Td(bool8))));
                end
                W      = 4./(4 - Td(bool6));
                lambda = (1 + (1 + m(bool22) + 0.24*(deltaTA(bool22) - 1/2)) ./ (1 + 0.15.*m(bool22)).*x03.*(W/2 - 0.03.*x03.*sqrt(W)));
                x0(bool6)     = x03.*lambda;
            end
            
            % estimate might not give solutions
            if any(x0(bool1 | bool2) < -1), exitflag = -1; return; end
            
        end
    end
    
    % find root of Lancaster & Blancard's function
    % --------------------------------------------
    
    % (Halley's method)    
    x = x0; 
    Tx = inf; 
    iterations = 0;
    bool1 = abs(Tx) > tol;
    while any(bool1);        
        % iterations
        iterations = iterations + 1; 
        
        % compute function value, and first two derivatives
        [Tx, Tp, Tpp] = LancasterBlanchard(x, q, m);    
        
        % find the root of the *difference* between the
        % function value [T_x] and the required time [T]
        Tx = Tx - T;
        bool1 = abs(Tx) > tol;
        
        % new value of x
        xp = x;
        x  = x - 2*Tx.*Tp ./ (2*Tp.^2 - Tx.*Tpp); 
        
        % escape clause
        if mod(iterations, 7), x = (xp+x)/2; end  
        
        % Halley's method might fail
        if iterations > 100, exitflag = -2; return; end
    end   
    
    % calculate terminal velocities
    % -----------------------------
    
    % constants required for this calculation
    gamma = sqrt(gmu.*s/2);
    
    bool1 = c == 0;
    bool2 = not(bool1);
    sigma = zeros(size(x));
    rho = sigma;
    z = sigma;
    if (any(bool1))
        sigma(bool1) = ones(size(s(bool1)));
        rho(bool1)   = zeros(size(s(bool1)));
        z(bool1)     = abs(x(bool1));
    end
    if(any(bool2))
        sigma(bool2) = 2*sqrt(r1(bool2).*r2(bool2)./(c(bool2).^2)) .* sin(deltaTA(bool2)/2);
        rho(bool2)   = (r1(bool2) - r2(bool2))./c(bool2);
        z(bool2)     = sqrt(1 + q(bool2).^2.*(x(bool2).^2 - 1));
    end
    
    % radial component
    Vr1    = +gamma.*((q.*z - x) - rho.*(q.*z + x)) ./ r1;
    Vr1vec = bsxfun(@times, Vr1, r1unit);
    Vr2    = -gamma.*((q.*z - x) + rho.*(q.*z + x)) ./ r2;
    Vr2vec = bsxfun(@times, Vr2, r2unit);
    
    % tangential component
    Vtan1    = sigma .* gamma .* (z + q.*x) ./ r1;
    Vtan1vec = bsxfun(@times, Vtan1, th1unit);
    Vtan2    = sigma .* gamma .* (z + q.*x) ./ r2;
    Vtan2vec = bsxfun(@times, Vtan2, th2unit);
    
    % Cartesian velocity
    V1 = Vtan1vec + Vr1vec;
    V2 = Vtan2vec + Vr2vec;
    
    % exitflag
    exitflag = 1; % (success)    
end

% Lancaster & Blanchard's function, and three derivatives thereof
function [T, Tp, Tpp, Tppp] = LancasterBlanchard(x, q, m)
    
    % protection against idiotic input
    bool = x < -1;
    x(bool) = abs(x(bool)) - 2;
    
    bool = x == -1;
    x(bool) = x(bool) + eps;
    
    % compute parameter E
    E  = x.^2 - 1;    
    
    % T(x), T'(x), T''(x)
    T = zeros(size(x));
    Tp = T;
    Tpp = T;
    Tppp = T;
        
    bool1 = x == 1;
    bool2 = abs(x-1) < 1e-2;
    bool3 = not(bool1 | bool2);
    if(any(bool1)) % exactly parabolic; solutions known exactly
        
        % T(x)
        T(bool1) = 4/3*(1-q(bool1).^3);
        % T'(x)
        Tp(bool1) = 4/5*(q(bool1).^5 - 1);
        % T''(x)
        Tpp(bool1) = Tp(bool1) + 120/70*(1 - q(bool1).^7);
        % T'''(x)
        Tppp(bool1) = 3*(Tpp(bool1) - Tp(bool1)) + 2400/1080*(q(bool1).^9 - 1);
        
    end
    if(any(bool2)) % near-parabolic; compute with series
        
        % evaluate sigma
        [sig1, dsigdx1, d2sigdx21, d3sigdx31] = sigmax(-E(bool2));
        [sig2, dsigdx2, d2sigdx22, d3sigdx32] = sigmax(-E(bool2).*q(bool2).*q(bool2));        
        % T(x)
        T(bool2) = sig1 - q(bool2).^3.*sig2;
        % T'(x)
        Tp(bool2) = 2*x(bool2).*(q(bool2).^5.*dsigdx2 - dsigdx1);
        % T''(x)        
        Tpp(bool2) = Tp(bool2)./x(bool2) + 4*x(bool2).^2.*(d2sigdx21 - q(bool2).^7.*d2sigdx22);
        % T'''(x)
        Tppp(bool2) = 3*(Tpp(bool2)-Tp(bool2)./x(bool2))./x(bool2) + 8*x(bool2).*x(bool2).*(q(bool2).^9.*d3sigdx32 - d3sigdx31);
    end    
    if(any(bool3)) % all other cases
        
        % compute all substitution functions
        y  = sqrt(abs(E(bool3)));
        z  = sqrt(1 + q(bool3).^2.*E(bool3));
        f  = y.*(z - q(bool3).*x(bool3));
        g  = x(bool3).*z - q(bool3).*E(bool3);

        % BUGFIX: (Simon Tardivel) this line is incorrect for E==0 and f+g==0
        % d  = (E < 0)*(atan2(f, g) + pi*m) + (E > 0)*log( max(0, f + g) );
        % it should be written out like so: 
        bool4 = E<0;
        bool5 = E==0;
        bool6 = not(bool4 | bool5);
        
        d = zeros(size(y));
        if(any(bool4))
            d(bool4) = bsxfun(@atan2, f(bool4), g(bool4)) + pi*m(bool3 & bool4);
        end
        if(any(bool5))
            d(bool5) = zeros(size(y(bool5)));
        end
        if(any(bool6)) 
            dSum = bsxfun(@max, 0, f(bool6)+g(bool6));
            d(bool6) = log(dSum);
        end

        % T(x)
        T(bool3) = 2*(x(bool3) - q(bool3).*z - d./y)./E(bool3);
        %  T'(x)
        Tp(bool3) = (4 - 4*q(bool3).^3.*x(bool3)./z - 3*x(bool3).*T(bool3))./E(bool3);
        % T''(x)
        Tpp(bool3) = (-4*q(bool3).^3./z .* (1 - q(bool3).^2.*x(bool3).^2./z(bool3).^2) - 3.*T(bool3) - 3*x(bool3).*Tp)./E(bool3);
        % T'''(x) 
        Tppp(bool3) = (4*q(bool3).^3./z.^2.*((1 - q(bool3).^2.*x(bool3).^2./z.^2) + 2*q(bool3).^2.*x(bool3)./z.^2.*(z - x(bool3))) - 8*Tp(bool3) - 7*x(bool3).*Tpp(bool3))./E(bool3);     
        
    end
end

% series approximation to T(x) and its derivatives 
% (used for near-parabolic cases)
function [sig, dsigdx, d2sigdx2, d3sigdx3] = sigmax(y)
    
    % preload the factors [an] 
    % (25 factors is more than enough for 16-digit accuracy)    
    persistent an;
    if isempty(an)
        an = [
            4.000000000000000e-001;     2.142857142857143e-001;     4.629629629629630e-002
            6.628787878787879e-003;     7.211538461538461e-004;     6.365740740740740e-005
            4.741479925303455e-006;     3.059406328320802e-007;     1.742836409255060e-008
            8.892477331109578e-010;     4.110111531986532e-011;     1.736709384841458e-012
            6.759767240041426e-014;     2.439123386614026e-015;     8.203411614538007e-017
            2.583771576869575e-018;     7.652331327976716e-020;     2.138860629743989e-021
            5.659959451165552e-023;     1.422104833817366e-024;     3.401398483272306e-026
            7.762544304774155e-028;     1.693916882090479e-029;     3.541295006766860e-031
            7.105336187804402e-033];
    end
    
    % powers of y
    powers = bsxfun(@power, y, (1:25)');
    
    % sigma itself
    sig = 4/3 + vectDot(powers, an); %need dim
    
    % dsigma / dx (derivative)
    dsigdx = vectDot( ( bsxfun(@times, (1:25)', [ones(size(y)); powers(1:24,:)]) ) , an);
    
    % d2sigma / dx2 (second derivative)
    c = ((1:25).*(0:24))';
    oneOverY = bsxfun(@rdivide,1,y);
    d2sigdx2 = vectDot(( bsxfun(@times, c, [oneOverY; ones(size(y)); powers(1:23,:)]) ) , an);
    
    % d3sigma / dx3 (third derivative)
    c = ((1:25).*(0:24).*(-1:23))';
    oneOverYOverY = bsxfun(@rdivide, oneOverY, y);
    d3sigdx3 = vectDot(( bsxfun(@times, c, [oneOverYOverY; oneOverY; ones(size(y)); powers(1:22,:)]) ) , an);
    
end

function dots = vectDot(A, b)
    dots = sum(bsxfun(@times, A, b),1);
end