% -----------------------------------------------------------------
% Lancaster & Blanchard version, with improvements by Gooding
% Very reliable, moderately fast for both simple and complicated cases
% -----------------------------------------------------------------
function [V1, V2, extremal_distances, exitflag] = ...
        lambert_LancasterBlanchard_good(r1vec, r2vec, tf, m, muC)
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
    
    % manipulate input
    tol     = 1e-12;                            % optimum for numerical noise v.s. actual precision
    r1      = sqrt(r1vec*r1vec.');              % magnitude of r1vec
    r2      = sqrt(r2vec*r2vec.');              % magnitude of r2vec    
    r1unit  = r1vec/r1;                         % unit vector of r1vec        
    r2unit  = r2vec/r2;                         % unit vector of r2vec
    crsprod = cross(r1vec, r2vec, 2);           % cross product of r1vec and r2vec
    mcrsprd = sqrt(crsprod*crsprod.');          % magnitude of that cross product
    th1unit = cross(crsprod/mcrsprd, r1unit);   % unit vectors in the tangential-directions
    th2unit = cross(crsprod/mcrsprd, r2unit);   
    % make 100.4% sure it's in (-1 <= x <= +1)
    dth = acos( max(-1, min(1, (r1vec*r2vec.')/r1/r2)) ); % turn angle
        
    % if the long way was selected, the turn-angle must be negative
    % to take care of the direction of final velocity
    longway = sign(tf); tf = abs(tf);
    if (longway < 0), dth = dth-2*pi; end
    
    % left-branch
    leftbranch = sign(m); m = abs(m);
    
    % define constants
    c  = sqrt(r1^2 + r2^2 - 2*r1*r2*cos(dth));
    s  = (r1 + r2 + c) / 2;
    T  = sqrt(8*muC/s^3) * tf;
    q  = sqrt(r1*r2)/s * cos(dth/2);
    
    % general formulae for the initial values (Gooding)
    % -------------------------------------------------
    
    % some initial values
    T0  = LancasterBlanchard(0, q, m);
    Td  = T0 - T;
    phr = mod(2*atan2(1 - q^2, 2*q), 2*pi);
    
    % initial output is pessimistic
    V1 = NaN(1,3);    V2 = V1;    extremal_distances = [NaN, NaN];
    
    % single-revolution case
    if (m == 0)
        x01 = T0*Td/4/T;
        if (Td > 0)
            x0 = x01;
        else
            x01 = Td/(4 - Td);
            x02 = -sqrt( -Td/(T+T0/2) );
            W   = x01 + 1.7*sqrt(2 - phr/pi);

            if (W >= 0)
                x03 = x01;
            else
                x03 = x01 + (-W).^(1/16).*(x02 - x01);
            end
            lambda = 1 + x03*(1 + x01)/2 - 0.03*x03^2*sqrt(1 + x01);
            x0 = lambda*x03;
        end
        
        % this estimate might not give a solution
        if (x0 < -1), exitflag = -1; return; end
        
    % multi-revolution case
    else
        
        % determine minimum Tp(x)
        xMpi = 4/(3*pi*(2*m + 1));        
        if (phr < pi)
            xM0 = xMpi*(phr/pi)^(1/8);
        elseif (phr > pi)
            xM0 = xMpi*(2 - (2 - phr/pi)^(1/8));
        % EMLMEX requires this one
        else
            xM0 = 0;
        end
        
        % use Halley's method
        xM = xM0;  Tp = inf;  iterations = 0;
        while abs(Tp) > tol            
            % iterations
            iterations = iterations + 1;            
            % compute first three derivatives
            [dummy, Tp, Tpp, Tppp] = LancasterBlanchard(xM, q, m);%#ok            
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
        if (xM < -1) || (xM > 1), exitflag = -1; return; end
        
        % corresponding time
        TM = LancasterBlanchard(xM, q, m);
        
        % T should lie above the minimum T
        if (TM > T), exitflag = -1; return; end
        
        % find two initial values for second solution (again with lambda-type patch)
        % --------------------------------------------------------------------------
        
        % some initial values
        TmTM  = T - TM;   T0mTM = T0 - TM;
        [dummy, Tp, Tpp] = LancasterBlanchard(xM, q, m);%#ok
                
        % first estimate (only if m > 0)
        if leftbranch > 0
            x   = sqrt( TmTM / (Tpp/2 + TmTM/(1-xM)^2) );
            W   = xM + x;
            W   = 4*W/(4 + TmTM) + (1 - W)^2;
            x0  = x*(1 - (1 + m + (dth - 1/2)) / ...
                (1 + 0.15*m)*x*(W/2 + 0.03*x*sqrt(W))) + xM;
            
            % first estimate might not be able to yield possible solution
            if (x0 > 1), exitflag = -1; return; end
            
        % second estimate (only if m > 0)
        else
            if (Td > 0)
                x0 = xM - sqrt(TM/(Tpp/2 - TmTM*(Tpp/2/T0mTM - 1/xM^2)));
            else
                x00 = Td / (4 - Td);
                W = x00 + 1.7*sqrt(abs(2*(1 - phr)));
                if (W >= 0)
                    x03 = x00;
                else
                    x03 = x00 - sqrt((-W)^(1/8))*(x00 + sqrt(-Td/(1.5*T0 - Td)));
                end
                W      = 4/(4 - Td);
                lambda = (1 + (1 + m + 0.24*(dth - 1/2)) / ...
                    (1 + 0.15*m)*x03*(W/2 - 0.03*x03*sqrt(W)));
                x0     = x03*lambda;
            end
            
            % estimate might not give solutions
            if (x0 < -1), exitflag = -1; return; end
            
        end
    end
    
    % find root of Lancaster & Blancard's function
    % --------------------------------------------
    
    % (Halley's method)    
    x = x0; Tx = inf; iterations = 0;
    while abs(Tx) > tol        
        % iterations
        iterations = iterations + 1;        
        % compute function value, and first two derivatives
        [Tx, Tp, Tpp] = LancasterBlanchard(x, q, m);        
        % find the root of the *difference* between the
        % function value [T_x] and the required time [T]
        Tx = Tx - T;
        % new value of x
        xp = x;
        x  = x - 2*Tx*Tp ./ (2*Tp^2 - Tx*Tpp);                 
        % escape clause
        if mod(iterations, 7), x = (xp+x)/2; end        
        % Halley's method might fail
        if iterations > 25, exitflag = -2; return; end
    end   
    
    % calculate terminal velocities
    % -----------------------------
    
    % constants required for this calculation
    gamma = sqrt(muC*s/2);
    if (c == 0)
        sigma = 1;
        rho   = 0;
        z     = abs(x);
    else
        sigma = 2*sqrt(r1*r2/(c^2)) * sin(dth/2);
        rho   = (r1 - r2)/c;
        z     = sqrt(1 + q^2*(x^2 - 1));
    end
    
    % radial component
    Vr1    = +gamma*((q*z - x) - rho*(q*z + x)) / r1;
    Vr1vec = Vr1*r1unit;
    Vr2    = -gamma*((q*z - x) + rho*(q*z + x)) / r2;
    Vr2vec = Vr2*r2unit;
    
    % tangential component
    Vtan1    = sigma * gamma * (z + q*x) / r1;
    Vtan1vec = Vtan1 * th1unit;
    Vtan2    = sigma * gamma * (z + q*x) / r2;
    Vtan2vec = Vtan2 * th2unit;
    
    % Cartesian velocity
    V1 = Vtan1vec + Vr1vec;
    V2 = Vtan2vec + Vr2vec;
    
    % exitflag
    exitflag = 1; % (success)   
end

% Lancaster & Blanchard's function, and three derivatives thereof
function [T, Tp, Tpp, Tppp] = LancasterBlanchard(x, q, m)
    
    % protection against idiotic input
    if (x < -1) % impossible; negative eccentricity
        x = abs(x) - 2;
    elseif (x == -1) % impossible; offset x slightly
        x = x + eps;
    end
    
    % compute parameter E
    E  = x*x - 1;    
    
    % T(x), T'(x), T''(x)
    if x == 1 % exactly parabolic; solutions known exactly
        % T(x)
        T = 4/3*(1-q^3);
        % T'(x)
        Tp = 4/5*(q^5 - 1);
        % T''(x)
        Tpp = Tp + 120/70*(1 - q^7);
        % T'''(x)
        Tppp = 3*(Tpp - Tp) + 2400/1080*(q^9 - 1);
        
    elseif abs(x-1) < 1e-2 % near-parabolic; compute with series
        % evaluate sigma
        [sig1, dsigdx1, d2sigdx21, d3sigdx31] = sigmax(-E);
        [sig2, dsigdx2, d2sigdx22, d3sigdx32] = sigmax(-E*q*q);        
        % T(x)
        T = sig1 - q^3*sig2;
        % T'(x)
        Tp = 2*x*(q^5*dsigdx2 - dsigdx1);
        % T''(x)        
        Tpp = Tp/x + 4*x^2*(d2sigdx21 - q^7*d2sigdx22);
        % T'''(x)
        Tppp = 3*(Tpp-Tp/x)/x + 8*x*x*(q^9*d3sigdx32 - d3sigdx31);
        
    else % all other cases
        % compute all substitution functions
        y  = sqrt(abs(E));
        z  = sqrt(1 + q^2*E);
        f  = y*(z - q*x);
        g  = x*z - q*E;

        % BUGFIX: (Simon Tardivel) this line is incorrect for E==0 and f+g==0
        % d  = (E < 0)*(atan2(f, g) + pi*m) + (E > 0)*log( max(0, f + g) );
        % it should be written out like so:
        if (E<0)
            d = atan2(f, g) + pi*m;
        elseif (E==0)
            d = 0;
        else 
            d = log(max(0, f+g));
        end

        % T(x)
        T = 2*(x - q*z - d/y)/E;
        %  T'(x)
        Tp = (4 - 4*q^3*x/z - 3*x*T)/E;
        % T''(x)
        Tpp = (-4*q^3/z * (1 - q^2*x^2/z^2) - 3*T - 3*x*Tp)/E;
        % T'''(x) 
        Tppp = (4*q^3/z^2*((1 - q^2*x^2/z^2) + 2*q^2*x/z^2*(z - x)) - 8*Tp - 7*x*Tpp)/E;     
        
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
    powers = y.^(1:25);
    
    % sigma itself
    sig = 4/3 + powers*an;
    
    % dsigma / dx (derivative)
    dsigdx = ( (1:25).*[1, powers(1:24)] ) * an;
    
    % d2sigma / dx2 (second derivative)
    d2sigdx2 = ( (1:25).*(0:24).*[1/y, 1, powers(1:23)] ) * an;
    
    % d3sigma / dx3 (third derivative)
    d3sigdx3 = ( (1:25).*(0:24).*(-1:23).*[1/y/y, 1/y, 1, powers(1:22)] ) * an;
    
end