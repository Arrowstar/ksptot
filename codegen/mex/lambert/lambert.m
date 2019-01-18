% LAMBERT            Lambert-targeter for ballistic flights
%                    (Izzo, and Lancaster, Blanchard & Gooding)
%
% Usage:
%    [V1, V2, extremal_distances, exitflag] = lambert(r1, r2, tf, m, GM_central)
%
% Dimensions:
%             r1, r2 ->  [1x3]
%             V1, V2 ->  [1x3]
% extremal_distances ->  [1x2]
%              tf, m ->  [1x1]
%         GM_central ->  [1x1]
%
% This function solves any Lambert problem *robustly*. It uses two separate
% solvers; the first one tried is a new and unpublished algorithm developed
% by Dr. D. Izzo from the European Space Agency [1]. This version is extremely
% fast, but especially for larger [m] it still fails quite frequently. In such
% cases, a MUCH more robust algorithm is started (the one by Lancaster &
% Blancard [2], with modifcations, initial values and other improvements by
% R.Gooding [3]), which is a lot slower partly because of its robustness.
%
% INPUT ARGUMENTS:
% ======================================================================
%    name        units    description
% ======================================================================
%   r1, r1       [km]     position vectors of the two terminal points.
%     tf        [days]    time of flight to solve for
%      m          [-]     specifies the number of complete orbits to complete
%                         (should be an integer)
% GM_central   [km3/s2]   std. grav. parameter (G�M = mu) of the central body
%
% OUTPUT ARGUMENTS:
% ======================================================================
%   name             units   description
% ======================================================================
%  V1, V2             [km/s]  terminal velocities at the end-points
%  extremal_distances  [km]   minimum(1) and maximum(2) distance of the
%                             spacecraft to the central body.
%  exitflag             [-]   Integer containing information on why the
%                             routine terminated. A value of +1 indicates
%                             success; a normal exit. A value of -1
%                             indicates that the given problem has no
%                             solution and cannot be solved. A value of -2
%                             indicates that both algorithms failed to find
%                             a solution. This should never occur since
%                             these problems are well-defined, and at the
%                             very least it can be determined that the
%                             problem has no solution. Nevertheless, it
%                             still occurs sometimes for accidental
%                             erroneous input, so it provides a basic
%                             mechanism to check any application using this
%                             algorithm.
%
% This routine can be compiled to increase its speed by a factor of about
% 10-15, which is certainly advisable when the complete application requires
% a great number of Lambert problems to be solved. The entire routine is
% written in embedded MATLAB, so it can be compiled with the emlmex()
% function (older MATLAB) or codegen() function (MATLAB 2011a and later).
%
% To do this using emlmex(), make sure MATLAB's current directory is equal
% to where this file is located. Then, copy-paste and execute the following
% commands to the command window:
%
%    example_input = {...
%         [0.0, 0.0, 0.0], ...% r1vec
%         [0.0, 0.0, 0.0], ...% r2vec
%          0.0, ...           % tf
%          0.0, ...           % m
%          0.0};              % muC
%    emlmex -eg example_input lambert.m
%
% This is of course assuming your compiler is configured correctly. See the
% documentation of emlmex() on how to do that.
%
% Using codegen(), the syntax is as follows:
%
%    example_input = {...
%         [0.0, 0.0, 0.0], ...% r1vec
%         [0.0, 0.0, 0.0], ...% r2vec
%          0.0, ...           % tf
%          0.0, ...           % m
%          0.0};              % muC
%    codegen lambert.m -args example_input
%
% Note that in newer MATLAB versions, the code analyzer will complain about
% the pragma "%#eml" after the main function's name, and possibly, issue
% subsequent warnings related to this issue. To get rid of this problem, simply
% replace the "%#eml" directive with "%#codegen".
%
%
%
% References:
%
% [1] Izzo, D. ESA Advanced Concepts team. Code used available in MGA.M, on
%     http://www.esa.int/gsp/ACT/inf/op/globopt.htm. Last retreived Nov, 2009.
% [2] Lancaster, E.R. and Blanchard, R.C. "A unified form of Lambert's theorem."
%     NASA technical note TN D-5368,1969.
% [3] Gooding, R.H. "A procedure for the solution of Lambert's orbital boundary-value
%     problem. Celestial Mechanics and Dynamical Astronomy, 48:145�165,1990.
%
% See also lambert_low_ExpoSins.


% Please report bugs and inquiries to:
%
% Name       : Rody P.S. Oldenhuis
% E-mail     : oldenhuis@gmail.com
% Licence    : 2-clause BSD (see License.txt)


% If you find this work useful, please consider a donation:
% https://www.paypal.me/RodyO/3.5

% If you want to cite this work in an academic paper, please use
% the following template:
%
% Rody Oldenhuis, orcid.org/0000-0002-3162-3660. "Lambert" <version>,
% <date you last used it>. MATLAB Robust solver for Lambert's
% orbital-boundary value problem.
% https://nl.mathworks.com/matlabcentral/fileexchange/26348



% -----------------------------------------------------------------
% Izzo's version:
% Very fast, but not very robust for more complicated cases
% -----------------------------------------------------------------
function [V1,...
          V2, ...
          extremal_distances,...
          exitflag] = lambert(r1vec,...
                              r2vec,...
                              tf,...
                              m,...
                              muC) %#coder

% original documentation:
%{
 This routine implements a new algorithm that solves Lambert's problem. The
 algorithm has two major characteristics that makes it favorable to other
 existing ones.

 1) It describes the generic orbit solution of the boundary condition
 problem through the variable X=log(1+cos(alpha/2)). By doing so the
 graph of the time of flight become defined in the entire real axis and
 resembles a straight line. Convergence is granted within few iterations
 for all the possible geometries (except, of course, when the transfer
 angle is zero). When multiple revolutions are considered the variable is
 X=tan(cos(alpha/2)*pi/2).

 2) Once the orbit has been determined in the plane, this routine
 evaluates the velocity vectors at the two points in a way that is not
 singular for the transfer angle approaching to pi (Lagrange coefficient
 based methods are numerically not well suited for this purpose).

 As a result Lambert's problem is solved (with multiple revolutions
 being accounted for) with the same computational effort for all
 possible geometries. The case of near 180 transfers is also solved
 efficiently.

  We note here that even when the transfer angle is exactly equal to pi
 the algorithm does solve the problem in the plane (it finds X), but it
 is not able to evaluate the plane in which the orbit lies. A solution
 to this would be to provide the direction of the plane containing the
 transfer orbit from outside. This has not been implemented in this
 routine since such a direction would depend on which application the
 transfer is going to be used in.

 please report bugs to dario.izzo@esa.int
%}

% adjusted documentation:
%{
 By default, the short-way solution is computed. The long way solution
 may be requested by giving a negative value to the corresponding
 time-of-flight [tf].

 For problems with |m| > 0, there are generally two solutions. By
 default, the right branch solution will be returned. The left branch
 may be requested by giving a negative value to the corresponding
 number of complete revolutions [m].
%}

% Authors
% .-`-.-`-.-`-.-`-.-`-.-`-.-`-.-`-.-`-.-`-.-`-.-`-.-`-.-`-.-`-.
% Name       : Dr. Dario Izzo
% E-mail     : dario.izzo@esa.int
% Affiliation: ESA / Advanced Concepts Team (ACT)

% Made more readible and optimized for speed by Rody P.S. Oldenhuis
% Code available in MGA.M on   http://www.esa.int/gsp/ACT/inf/op/globopt.htm

% last edited 12/Dec/2009

% ADJUSTED FOR EML-COMPILATION 24/Dec/2009

    % initial values
    tol = 1e-14;    bad = false;     days = 86400;

    % work with non-dimensional units
    r1 = sqrt(r1vec*r1vec.');  r1vec = r1vec/r1;
    V = sqrt(muC/r1);          r2vec = r2vec/r1;
    T = r1/V;                  tf    = tf*days/T; % also transform to seconds

    % relevant geometry parameters (non dimensional)
    mr2vec = sqrt(r2vec*r2vec.');
    % make 100% sure it's in (-1 <= dth <= +1)
    dth = acos( max(-1, min(1, (r1vec*r2vec.')/mr2vec)) );

    % decide whether to use the left or right branch (for multi-revolution
    % problems), and the long- or short way
    leftbranch = sign(m);   longway = sign(tf);
    m = abs(m);             tf = abs(tf);
    if (longway < 0), dth = 2*pi - dth; end

    % derived quantities
    c      = sqrt(1 + mr2vec^2 - 2*mr2vec*cos(dth)); % non-dimensional chord
    s      = (1 + mr2vec + c)/2;                     % non-dimensional semi-perimeter
    a_min  = s/2;                                    % minimum energy ellipse semi major axis
    Lambda = sqrt(mr2vec)*cos(dth/2)/s;              % lambda parameter (from BATTIN's book)
    crossprd = [r1vec(2)*r2vec(3) - r1vec(3)*r2vec(2),...
                r1vec(3)*r2vec(1) - r1vec(1)*r2vec(3),...% non-dimensional normal vectors
                r1vec(1)*r2vec(2) - r1vec(2)*r2vec(1)];
    mcr       = sqrt(crossprd*crossprd.');           % magnitues thereof
    nrmunit   = crossprd/mcr;                        % unit vector thereof

    % Initial values
    % ---------------------------------------------------------

    % ELMEX requires this variable to be declared OUTSIDE the IF-statement
    logt = log(tf); % avoid re-computing the same value

    % single revolution (1 solution)
    if (m == 0)

        % initial values
        inn1 = -0.5233;      % first initial guess
        inn2 = +0.5233;      % second initial guess
        x1   = log(1 + inn1);% transformed first initial guess
        x2   = log(1 + inn2);% transformed first second guess

        % multiple revolutions (0, 1 or 2 solutions)
        % the returned soltuion depends on the sign of [m]
    else
        % select initial values
        if (leftbranch < 0)
            inn1 = -0.5234; % first initial guess, left branch
            inn2 = -0.2234; % second initial guess, left branch
        else
            inn1 = +0.7234; % first initial guess, right branch
            inn2 = +0.5234; % second initial guess, right branch
        end
        x1 = tan(inn1*pi/2);% transformed first initial guess
        x2 = tan(inn2*pi/2);% transformed first second guess
    end

    % since (inn1, inn2) < 0, initial estimate is always ellipse
    xx   = [inn1, inn2];  aa = a_min./(1 - xx.^2);
    bbeta = longway * 2*asin(sqrt((s-c)/2./aa));
    % make 100.4% sure it's in (-1 <= xx <= +1)
    aalfa = 2*acos(  max(-1, min(1, xx)) );

    % evaluate the time of flight via Lagrange expression
    y12  = aa.*sqrt(aa).*((aalfa - sin(aalfa)) - (bbeta-sin(bbeta)) + 2*pi*m);

    % initial estimates for y
    if m == 0
        y1 = log(y12(1)) - logt;
        y2 = log(y12(2)) - logt;
    else
        y1 = y12(1) - tf;
        y2 = y12(2) - tf;
    end

    % Solve for x
    % ---------------------------------------------------------

    % Newton-Raphson iterations
    % NOTE - the number of iterations will go to infinity in case
    % m > 0  and there is no solution. Start the other routine in
    % that case
    err = inf;  iterations = 0; xnew = 0;
    while (err > tol)
        % increment number of iterations
        iterations = iterations + 1;
        % new x
        xnew = (x1*y2 - y1*x2) / (y2-y1);
        % copy-pasted code (for performance)
        if m == 0, x = exp(xnew) - 1; else x = atan(xnew)*2/pi; end
        a = a_min/(1 - x^2);
        if (x < 1) % ellipse
            beta = longway * 2*asin(sqrt((s-c)/2/a));
            % make 100.4% sure it's in (-1 <= xx <= +1)
            alfa = 2*acos( max(-1, min(1, x)) );
        else % hyperbola
            alfa = 2*acosh(x);
            beta = longway * 2*asinh(sqrt((s-c)/(-2*a)));
        end
        % evaluate the time of flight via Lagrange expression
        if (a > 0)
            tof = a*sqrt(a)*((alfa - sin(alfa)) - (beta-sin(beta)) + 2*pi*m);
        else
            tof = -a*sqrt(-a)*((sinh(alfa) - alfa) - (sinh(beta) - beta));
        end
        % new value of y
        if m ==0, ynew = log(tof) - logt; else ynew = tof - tf; end
        % save previous and current values for the next iterarion
        % (prevents getting stuck between two values)
        x1 = x2;  x2 = xnew;
        y1 = y2;  y2 = ynew;
        % update error
        err = abs(x1 - xnew);
        % escape clause
        if (iterations > 15), bad = true; break; end
    end

    % If the Newton-Raphson scheme failed, try to solve the problem
    % with the other Lambert targeter.
    if bad
        % NOTE: use the original, UN-normalized quantities
        [V1, V2, extremal_distances, exitflag] = ...
            lambert_LancasterBlanchard(r1vec*r1, r2vec*r1, longway*tf*T, leftbranch*m, muC);
        return
    end

    % convert converged value of x
    if m==0, x = exp(xnew) - 1; else x = atan(xnew)*2/pi; end

    %{
      The solution has been evaluated in terms of log(x+1) or tan(x*pi/2), we
      now need the conic. As for transfer angles near to pi the Lagrange-
      coefficients technique goes singular (dg approaches a zero/zero that is
      numerically bad) we here use a different technique for those cases. When
      the transfer angle is exactly equal to pi, then the ih unit vector is not
      determined. The remaining equations, though, are still valid.
    %}

    % Solution for the semi-major axis
    a = a_min/(1-x^2);

    % Calculate psi
    if (x < 1) % ellipse
        beta = longway * 2*asin(sqrt((s-c)/2/a));
        % make 100.4% sure it's in (-1 <= xx <= +1)
        alfa = 2*acos( max(-1, min(1, x)) );
        psi  = (alfa-beta)/2;
        eta2 = 2*a*sin(psi)^2/s;
        eta  = sqrt(eta2);
    else       % hyperbola
        beta = longway * 2*asinh(sqrt((c-s)/2/a));
        alfa = 2*acosh(x);
        psi  = (alfa-beta)/2;
        eta2 = -2*a*sinh(psi)^2/s;
        eta  = sqrt(eta2);
    end

    % unit of the normalized normal vector
    ih = longway * nrmunit;

    % unit vector for normalized [r2vec]
    r2n = r2vec/mr2vec;

    % cross-products
    % don't use cross() (emlmex() would try to compile it, and this way it
    % also does not create any additional overhead)
    crsprd1 = [ih(2)*r1vec(3)-ih(3)*r1vec(2),...
               ih(3)*r1vec(1)-ih(1)*r1vec(3),...
               ih(1)*r1vec(2)-ih(2)*r1vec(1)];
    crsprd2 = [ih(2)*r2n(3)-ih(3)*r2n(2),...
               ih(3)*r2n(1)-ih(1)*r2n(3),...
               ih(1)*r2n(2)-ih(2)*r2n(1)];

    % radial and tangential directions for departure velocity
    Vr1 = 1/eta/sqrt(a_min) * (2*Lambda*a_min - Lambda - x*eta);
    Vt1 = sqrt(mr2vec/a_min/eta2 * sin(dth/2)^2);

    % radial and tangential directions for arrival velocity
    Vt2 = Vt1/mr2vec;
    Vr2 = (Vt1 - Vt2)/tan(dth/2) - Vr1;

    % terminal velocities
    V1 = (Vr1*r1vec + Vt1*crsprd1)*V;
    V2 = (Vr2*r2n + Vt2*crsprd2)*V;

    % exitflag
    exitflag = 1; % (success)

    % also compute minimum distance to central body
    % NOTE: use un-transformed vectors again!
    extremal_distances = ...
        minmax_distances(r1vec*r1, r1, r2vec*r1, mr2vec*r1, dth, a*r1, V1, V2, m, muC);

end

% -----------------------------------------------------------------
% Lancaster & Blanchard version, with improvements by Gooding
% Very reliable, moderately fast for both simple and complicated cases
% -----------------------------------------------------------------
function [V1,...
          V2,...
          extremal_distances,...
          exitflag] = lambert_LancasterBlanchard(r1vec,...
                                                 r2vec,...
                                                 tf,...
                                                 m,...
                                                 muC) %#coder
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
% E-mail     : oldenhuis@gmail.com
% Licence    : 2-clause BSD (see License.txt)


% If you find this work useful, please consider a donation:
% https://www.paypal.me/RodyO/3.5

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
                W = x00 + 1.7*sqrt(2*(1 - phr));
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

    % also determine minimum/maximum distance
    a = s/2/(1 - x^2); % semi-major axis
    extremal_distances = minmax_distances(r1vec, r1, r1vec, r2, dth, a, V1, V2, m, muC);

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


% -----------------------------------------------------------------
% Helper functions
% -----------------------------------------------------------------

% compute minimum and maximum distances to the central body
function extremal_distances = minmax_distances(r1vec, r1,...
                                               r2vec, r2,...
                                               dth,...
                                               a,...
                                               V1, V2,...
                                               m,...
                                               muC)

    % default - minimum/maximum of r1,r2
    minimum_distance = min(r1,r2);
    maximum_distance = max(r1,r2);

    % was the longway used or not?
    longway = abs(dth) > pi;

    % eccentricity vector (use triple product identity)
    evec = ((V1*V1.')*r1vec - (V1*r1vec.')*V1)/muC - r1vec/r1;

    % eccentricity
    e = sqrt(evec*evec.');
    % apses
    pericenter = a*(1-e);
    apocenter  = inf;                    % parabolic/hyperbolic case
    if (e < 1), apocenter = a*(1+e); end % elliptic case

    % since we have the eccentricity vector, we know exactly where the
    % pericenter lies. Use this fact, and the given value of [dth], to
    % cross-check if the trajectory goes past it
    if (m > 0) % obvious case (always elliptical and both apses are traversed)
        minimum_distance = pericenter;
        maximum_distance = apocenter;
    else % less obvious case
        % compute theta1&2 ( use (AxB)-(CxD) = (C·B)(D·A) - (C·A)(B·D) ))
        pm1 = sign( r1*r1*(evec*V1.') - (r1vec*evec.')*(r1vec*V1.') );
        pm2 = sign( r2*r2*(evec*V2.') - (r2vec*evec.')*(r2vec*V2.') );
        % make 100.4% sure it's in (-1 <= theta12 <= +1)
        theta1 = pm1*acos( max(-1, min(1, (r1vec/r1)*(evec/e).')) );
        theta2 = pm2*acos( max(-1, min(1, (r2vec/r2)*(evec/e).')) );
        % points 1&2 are on opposite sides of the symmetry axis -- minimum
        % and maximum distance depends both on the value of [dth], and both
        % [theta1] and [theta2]
        if (theta1*theta2 < 0)
            % if |th1| + |th2| = turnangle, we know that the pericenter was
            % passed
            if abs(abs(theta1) + abs(theta2) - dth) < 5*eps(dth)
                minimum_distance = pericenter;
            % this condition can only be false for elliptic cases, and
            % when it is indeed false, we know that the orbit passed
            % apocenter
            else
                maximum_distance = apocenter;
            end
        % points 1&2 are on the same side of the symmetry axis. Only if the
        % long-way was used are the min. and max. distances different from
        % the min. and max. values of the radii (namely, equal to the apses)
        elseif longway
            minimum_distance = pericenter;
            if (e < 1), maximum_distance = apocenter; end
        end
    end

    % output argument
    extremal_distances = [minimum_distance, maximum_distance];

end
