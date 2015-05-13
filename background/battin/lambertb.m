% ------------------------------------------------------------------------------
%
%                           function lambertb
%
%  this function solves lambert's problem using battins method. the method is
%    developed in battin (1987). it uses continued fractions to speed the
%    solution and has several parameters that are defined differently than
%    the traditional gaussian technique.
%
%  author        : david vallado                  719-573-2600    1 mar 2001
%
%  inputs          description                    range / units
%    ro          - ijk position vector 1          km
%    r           - ijk position vector 2          km
%    dm          - direction of motion            'l','s'
%    nrev        - number of revs to complete     0, 1, ...
%    dtsec       - time between r1 and r2         s
%
%  outputs       :
%    vo          - ijk velocity vector            km / s
%    v           - ijk velocity vector            km / s
%    error       - error flag                     'ok',...
%
%  locals        :
%    i           - index
%    loops       -
%    u           -
%    b           -
%    sinv        -
%    cosv        -
%    rp          -
%    x           -
%    xn          -
%    y           -
%    l           -
%    m           -
%    cosdeltanu  -
%    sindeltanu  -
%    dnu         -
%    a           -
%    tan2w       -
%    ror         -
%    h1          -
%    h2          -
%    tempx       -
%    eps         -
%    denom       -
%    chord       -
%    k2          -
%    s           -
%    f           -
%    g           -
%    gdot        -
%    am          -
%    ae          -
%    be          -
%    tm          -
%    arg1        -
%    arg2        -
%    tc          -
%    alpe        -
%    bete        -
%    alph        -
%    beth        -
%    de          -
%    dh          -
%
%  coupling      :
%    mag         - magnitude of a vector
%    arcsinh     - inverse hyperbolic sine
%    arccosh     - inverse hyperbolic cosine
%    sinh        - hyperbolic sine
%
%  references    :
%    vallado       2001, 464-467, ex 7-5
%
% [vo,v,errorb] = lambertb ( ro,r, dm,nrev, dtsec );
% ------------------------------------------------------------------------------

function [vo,v,errorb] = lambertb ( ro,r, dm,nrev, dtsec )

% -------------------------  implementation   -------------------------
        constmath;
        constastro;
        
        errorb = '      ok';
        y = 0.0;
        k2 = 0.0;
        u = 0.0;

        magr = mag(r);
        magro = mag(ro);

        cosdeltanu= dot(ro,r)/(magro*magr);
        rcrossr = cross( ro,r );
        magrcrossr = mag(rcrossr);
        if dm=='s'
            sindeltanu= magrcrossr/(magro*magr);
        else
            sindeltanu= -magrcrossr/(magro*magr);            
        end;
        dnu   = atan2( sindeltanu,cosdeltanu );

        % the angle needs to be positive to work for the long way
        if dnu < 0.0
            dnu=2.0*pi+dnu;
        end
   
        ror   = magr/magro;
        eps   = ror - 1.0;
        tan2w = 0.25*eps*eps / ( sqrt( ror ) + ror * ...
                                  ( 2.0 + sqrt( ror ) ) );
        rp    = sqrt( magro*magr )*( (cos(dnu*0.25))^2 + tan2w );

        if ( dnu < pi )
            l = ( (sin(dnu*0.25))^2 + tan2w ) / ...
               ( (sin(dnu*0.25))^2 + tan2w + cos( dnu*0.5 ) );
          else
            l = ( (cos(dnu*0.25))^2 + tan2w - cos( dnu*0.5 ) ) / ...
                 ( (cos(dnu*0.25))^2 + tan2w );
         end

        m    = mu * dtsec*dtsec / ( 8.0*rp*rp*rp );
        x    = 10.0;
        xn   = l;   %l    % 0.0 for par and hyp, l for ell
        chord= sqrt( magro*magro + magr*magr - 2.0*magro*magr*cos( dnu ) );
        s    = ( magro + magr + chord )*0.5;
        loops= 1;
        
        lim1 = sqrt(m/l);
        y1 = 0.0;
        
        while ((abs(xn-x) >= small) && (loops <= 30))
            x    = xn;
            tempx  = seebatt(x);
            denom= 1.0 / ( (1.0 + 2.0*x + l) * (4.0*x + tempx*(3.0 + x) ) );
            h1   = ( l + x )^2 * ( 1.0 + 3.0*x + tempx )*denom;
            h2   = m*( x - l + tempx )*denom;

            % ----------------------- evaluate cubic ------------------
            b = 0.25*27.0*h2 / ((1.0+h1)^3 );

            if b < -1.0 % reset the initial condition
                xn = 1.0 - 2.0*l;
            else
                if y1 > lim1
                    xn = xn * (lim1/y1);
                else
                    u  = 0.5*b / ( 1.0 + sqrt( 1.0 + b ) );
                    k2 = kbatt(u);
                    y  = ( ( 1.0+h1 ) / 3.0 )*( 2.0 + sqrt( 1.0+b ) / ( 1.0+2.0*u*k2*k2 ) );
                    xn= sqrt( ( (1.0-l)*0.5 )^2 + m/(y*y) ) - ( 1.0+l )*0.5;
%                    xn = sqrt(l*l + m/(y*y)) - (1.0 - l); alt, doesn't seem to work
                end;
            end;    

y1=  sqrt( m/((l+x)*(1.0+x)) );          
            loops = loops + 1;
%%% fprintf(1,' %3i y2 %11.6f x %11.6f k2 %11.6f b %11.6f u %11.6f y1 %11.7f \n',loops,y, x, k2, b, u, y1 );
            
          end

        a=  mu * dtsec*dtsec / (16.0*rp*rp*xn*y*y );

        % ------------------ find eccentric anomalies -----------------
        % ------------------------ hyperbolic -------------------------
        if ( a < -small )  
            arg1 = sqrt( s / ( -2.0*a ) );
            arg2 = sqrt( ( s-chord ) / ( -2.0*a ) );
            % ------- evaluate f and g functions --------
            alph = 2.0 * asinh( arg1 );
            beth = 2.0 * asinh( arg2 );
            dh   = alph - beth;
            f    = 1.0 - (a/magro)*(1.0 - cosh(dh) );
            gdot = 1.0 - (a/magr) *(1.0 - cosh(dh) );
            g    = dtsec - sqrt(-a*a*a/mu)*(sinh(dh)-dh);
          else
            % ------------------------ elliptical ---------------------
            if ( a > small )  
                arg1 = sqrt( s / ( 2.0*a ) );
                arg2 = sqrt( ( s-chord ) / ( 2.0*a ) );
                sinv = arg2;
                cosv = sqrt( 1.0 - (magro+magr-chord)/(4.0*a) );
                bete = 2.0*acos(cosv);
                bete = 2.0*asin(sinv);
                if ( dnu > pi )  
                    bete= -bete;
                end

                cosv= sqrt( 1.0 - s/(2.0*a) );
                sinv= arg1;

                am  = s*0.5;
                ae  = 2.0*nrev*pi;
                be  = 2.0*asin( sqrt( (s-chord)/s ) );
                tm  = sqrt(am*am*am/mu)*(ae - (be-sin(be)));
                if ( dtsec > tm )
                    alpe= 2.0*pi-2.0*asin( sinv );
                  else
                    alpe= 2.0*asin( sinv );
                  end
                de  = alpe - bete;
                f   = 1.0 - (a/magro)*(1.0 - cos(de) );
                gdot= 1.0 - (a/magr)* (1.0 - cos(de) );
                g   = dtsec - sqrt(a*a*a/mu)*(de - sin(de));             
              else
                % --------------------- parabolic ---------------------
                arg1 = 0.0;
                arg2 = 0.0;
                errorb= 'a = 0   ';
                f = 0.0;
                g = 0.0;
                gdot = 0.0;
                fdot = 0.0;
                fprintf(1,' a parabolic orbit \n');
              end
          end

        for i= 1 : 3
            vo(i)= ( r(i) - f*ro(i) )/g;
            v(i) = ( gdot*r(i) - ro(i) )/g;
          end

