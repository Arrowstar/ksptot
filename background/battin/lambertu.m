% ------------------------------------------------------------------------------
%
%                           function lambertu
%
%  this function solves the lambert problem for orbit determination and returns
%    the velocity vectors at each of two given position vectors.  the solution
%    uses universal variables for calculation and a bissection technique
%    updating psi.
%
%  author        : david vallado                  719-573-2600    1 mar 2001
%
%  inputs          description                    range / units
%    r1          - ijk position vector 1          km
%    r2          - ijk position vector 2          km
%    dm          - direction of motion            'l','s'
%    dtsec       - time between r1 and r2         s
%    nrev        - multiple revoluions            0, 1, ...
%
%  outputs       :
%    v1          - ijk velocity vector            km / s
%    v2          - ijk velocity vector            km / s
%    error       - error flag                     'ok', ...
%
%  locals        :
%    vara        - variable of the iteration,
%                  not the semi-axis
%    y           - area between position vectors
%    upper       - upper bound for z
%    lower       - lower bound for z
%    cosdeltanu  - cosine of true anomaly change  rad
%    f           - f expression
%    g           - g expression
%    gdot        - g dot expression
%    xold        - old universal variable x
%    xoldcubed   - xold cubed
%    zold        - old value of z
%    znew        - new value of z
%    c2new       - c2(z) function
%    c3new       - c3(z) function
%    timenew     - new time                       s
%    small       - tolerance for roundoff errors
%    i, j        - index
%
%  coupling      :
%    mag         - magnitude of a vector
%    dot         - dot product of two vectors
%    findc2c3    - find c2 and c3 functions
%
%  references    :
%    vallado       2001, 459-464, alg 55, ex 7-5
%
% [vo,v,errorl] = lambertu ( ro,r, dm, nrev, dtsec );
% ------------------------------------------------------------------------------

%function [vo,v,errorl] = lambertu ( ro,r, dm, nrev, dtsec );
function [vo,v,errorl] = lambertu ( ro,r, dm, nrev, dtsec,fid )

% -------------------------  implementation   -------------------------
        constmath;
        constastro;
small = 0.00001; % can affect cases where znew is multiples of 2pi^2
        numiter= 40;
        errorl  = '      ok';
        psinew = 0.0;

        magro = mag(ro);
        magr  = mag(r);
        for i= 1 : 3
            vo(i)= 0.0;
            v(i) = 0.0;
        end

        cosdeltanu= nrev + dot(ro,r)/(magro*magr);
        if ( dm == 'l' )  
            vara = -sqrt( magro*magr*(1.0+cosdeltanu) );
        else
            vara =  sqrt( magro*magr*(1.0+cosdeltanu) );
        end
 %fprintf(1,'%11.7f %11.7f nrev %3i %1c \n',cosdeltanu*rad, vara , nrev, dm);

        % ---------------  form initial guesses   ---------------------
        psiold = 0.0;
        psinew = 0.0;
        xold   = 0.0;
        c2new  = 0.5;
        c3new  = 1.0/6.0;

        % --------- set up initial bounds for the bissection ----------
        if ( nrev == 0 )  
            upper=  4.0*pi*pi;
            lower= -4.0*twopi*pi;
            nrev = 0;
        else
            if nrev == 1  
                upper=   16.0*pi*pi; 
                lower=    4.0*pi*pi;   
            else
                upper=  36.0*pi*pi; 
                lower=  16.0*pi*pi;     
            end    
        end

%        chord = sqrt( magro^2 + magr^2 - 2.0*magro*magr*cosdeltanu );
%            nrev = 1;
%        chord = sqrt( magro^2 + magr^2 - 2.0*magro*magr*cosdeltanu );
%        s     = ( magro + magr + chord )*0.5;
%        betam = 2.0* asin( sqrt((s-chord)/chord) );  % comes out imaginary?? jst for hyperbolic??
%        tmin  = ((2.0*nrev+1.0)*pi-betam + sin(betam))/sqrt(mu);

        % -------  determine if  the orbit is possible at all ---------
        if ( abs( vara ) > small )  
            loops  = 0;
            ynegktr= 1;  % y neg ktr
            dtnew = -10.0;
            while ((abs(dtnew-dtsec) >= small) && (loops < numiter) && (ynegktr <= 10))
%       fprintf(1,'%3i  dtnew-dtsec %11.7f yneg %3i \n',loops,dtnew-dtsec,ynegktr );
                if ( abs(c2new) > small )
                    y= magro + magr - ( vara*(1.0-psiold*c3new)/sqrt(c2new) );
                else
                    y= magro + magr;
                end
                % ----------- check for negative values of y ----------
                if (  ( vara > 0.0 ) && ( y < 0.0 ) )  % ( vara > 0.0 ) &
                    ynegktr= 1;
                    while (( y < 0.0 ) && ( ynegktr < 10 ))
                        psinew= 0.8*(1.0/c3new)*( 1.0 ...
                                - (magro+magr)*sqrt(c2new)/vara  );  
                        % -------- find c2 and c3 functions -----------
                        [c2new,c3new] = findc2c3( psinew );
                        psiold = psinew;
                        lower  = psiold;
                        if ( abs(c2new) > small )
                            y= magro + magr - ( vara*(1.0-psiold*c3new)/sqrt(c2new) );
                        else
                            y= magro + magr;
                        end
  %         fprintf(1,'%3i  y %11.7f lower %11.7f c2new %11.7f psinew %11.7f yneg %3i \n',loops,y,lower,c2new,psinew,ynegktr );

                        ynegktr = ynegktr + 1;
                    end % while
                end  % if  y neg

                if ( ynegktr < 10 )  
                    if ( abs(c2new) > small )  
                        xold= sqrt( y/c2new );
                    else
                        xold= 0.0;
                    end
                    xoldcubed= xold*xold*xold;
                    dtnew    = (xoldcubed*c3new + vara*sqrt(y))/sqrt(mu);

                    % --------  readjust upper and lower bounds -------
                    if ( dtnew < dtsec )
                        lower= psiold;
                    end
                    if ( dtnew > dtsec )
                        upper= psiold;
                    end
                    psinew= (upper+lower) * 0.5;

                    % ------------- find c2 and c3 functions ----------
                    [c2new,c3new] = findc2c3( psinew );
                    psiold = psinew;
                    loops = loops + 1;

                    % --- make sure the first guess isn't too close ---
                    if ( (abs(dtnew - dtsec) < small) && (loops == 1) );
                        dtnew= dtsec-1.0;
                    end
                end  % if  ynegktr < 10
%              fprintf(1,'%3i  y %11.7f xold %11.7f dtnew %11.7f psinew %11.7f \n',loops,y,xold,dtnew,psinew );
 %%%             fprintf(1,'%3i  y %11.7f xold %11.7f dtnew %11.7f psinew %11.7f \n',loops,y/re,xold/sqrt(re),dtnew/tusec,psinew );
%              fprintf(1,'%3i  y %11.7f xold %11.7f dtnew %11.7f psinew %11.7f \n',loops,y/re,xold/sqrt(re),dtnew/60.0,psinew );
            end % while loop

            if ( (loops >= numiter) || (ynegktr >= 10) )
                errorl= 'gnotconv';
                if ( ynegktr >= 10 )
                    errorl= 'y negati';
                end
            else
                % --- use f and g series to find velocity vectors -----
                f   = 1.0 - y/magro;
                gdot= 1.0 - y/magr;
                g   = 1.0 / (vara*sqrt( y/mu ));  % 1 over g
                for i= 1 : 3
                    vo(i)= ( r(i) - f*ro(i) )*g;
                    v(i) = ( gdot*r(i) - ro(i) )*g;
                end
            end   % if  the answer has converged
        else
            error= 'impos180';
        end  % if  var a > 0.0
          
%       fprintf( fid,'psinew %11.5f  %11.5f %11.5f  \n',psinew, dtsec/60.0, xold/rad);
       if errorl ~= '      ok'
           fprintf( fid,'%s ',errorl );
       end;
          
