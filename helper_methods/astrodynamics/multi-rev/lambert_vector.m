%Copyright (c) 2010, Rody Oldenhuis
%All rights reserved.
%
%Redistribution and use in source and binary forms, with or without 
%modification, are permitted provided that the following conditions are 
%met:
%
%    * Redistributions of source code must retain the above copyright 
%      notice, this list of conditions and the following disclaimer.
%    * Redistributions in binary form must reproduce the above copyright 
%      notice, this list of conditions and the following disclaimer in 
%      the documentation and/or other materials provided with the distribution
%      
%THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
%AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
%IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
%ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
%LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
%CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
%SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
%INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
%CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
%ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
%POSSIBILITY OF SUCH DAMAGE.

% Vectorization Copyright (c) 2014 Brian Kidder

function [V1, V2] = lambert_vector(r1vec, r2vec, tf, m, muC)

    % initial values        
    tol = 1e-14;
    days = 3600*24;
    
    % Normalize position vectors such that r1 has unit length
    % Normalize mu constant and time of flight accordingly
    r1 = sqrt(mtimesx(r1vec, r1vec, 'T'));
    r1_inv = 1./r1;
    
    r1vec = mtimesx(r1vec, r1_inv);
    r2vec = mtimesx(r2vec, r1_inv);
    V = sqrt(mtimesx(muC, r1_inv));
    T = 1/mtimesx(V, r1_inv);
    tf = mtimesx(tf.*days.*V,r1_inv);

    % relevant geometry parameters (non dimensional)
    mr2vec = sqrt(mtimesx(r2vec, r2vec, 'T'));
    mr2vec_inv = 1./mr2vec;
    dth = acos( max(-1, min(+1, mtimesx(mtimesx(r1vec, r2vec, 'T'), mr2vec_inv))));

    % decide whether to use the the long- or short way    
    longway = sign(tf);
    tf = abs(tf);
    tf(tf == 0) = NaN;
    dth(longway<0) = 2*pi - dth(longway<0);

    
    % derived quantities        
    c       = sqrt(1 + mr2vec.^2 - 2.*mr2vec.*cos(dth));
    s       = (1 + mr2vec + c)./2;
    a_min   = s./2;
    Lambda  = sqrt(mr2vec).*cos(dth./2)./s;
    for i=1:size(r1vec,3)
        for j=1:size(r1vec,4)
            crossprd(:,:,i,j) = [r1vec(1,2,i,j)*r2vec(1,3,i,j) - r1vec(1,3,i,j)*r2vec(1,2,i,j),... 
                                 r1vec(1,3,i,j)*r2vec(1,1,i,j) - r1vec(1,1,i,j)*r2vec(1,3,i,j),...
                                 r1vec(1,1,i,j)*r2vec(1,2,i,j) - r1vec(1,2,i,j)*r2vec(1,1,i,j)];
        end
    end
    mcr_inv = 1/sqrt(mtimesx(crossprd, crossprd, 'T'));
    nrmunit = mtimesx(crossprd, mcr_inv);
    

    % Initial values
    % ·························································
    logt = log(tf); % avoid re-computing the same value
    
    inn1 = ones(size(tf)) * -0.5233; % first initial guess
    inn2 = ones(size(tf)) * +0.5233; % second initial guess
    x1   = log(1 + inn1);% transformed first initial guess
    x2   = log(1 + inn2);% transformed first second guess
    
    aa1 = a_min ./ (1 - inn1.^2);
    aa2 = a_min ./ (1 - inn2.^2);
    bbeta1 = mtimesx(longway, 2.*asin(sqrt((s-c)/2./aa1)));
    bbeta2 = mtimesx(longway, 2.*asin(sqrt((s-c)/2./aa2)));
    aalfa1 = 2*acos(inn1);
    aalfa2 = 2*acos(inn2);

    % evaluate the time of flight via Lagrange expression
    y1  = aa1.*sqrt(aa1).*((aalfa1 - sin(aalfa1)) - (bbeta1-sin(bbeta1)));
    y2  = aa2.*sqrt(aa2).*((aalfa2 - sin(aalfa2)) - (bbeta2-sin(bbeta2)));

    % initial estimates for y
    y1 = log(y1) - logt; %Bad
    y2 = log(y2) - logt; %Bad
    
    % Solve for x
    % ·························································
    
    % Newton-Raphson iterations
    % NOTE - the number of iterations will go to infinity in case
    % m > 0  and there is no solution. Start the other routine in 
    % that case
    err = ones(size(tf))*inf;  iterations = 0;             
    xnew = zeros(size(tf));    ynew = zeros(size(tf));
    alfa = zeros(size(tf));    beta = zeros(size(tf));
    tof = zeros(size(tf));
    x = zeros(size(tf));       a = zeros(size(tf));
     
    % If err reaches zero, y1=y2=0, and xnew will get divide by zero
    while any(any(err > tol))
        active = err > tol & tf > 0;
        % increment number of iterations
        iterations = iterations + 1;
        % new x
        y_equal = (y1 == y2);
        xnew(active) = (x1(active).*y2(active) - y1(active).*x2(active)) ./ (y2(active)-y1(active));
        xnew(active & y_equal) = 0;
        % copy-pasted code (for performance)
        x(active) = exp(xnew(active)) - 1;
        a(active) = a_min(active)./(1 - x(active).^2);
    
        x_less_1 = (x < 1);
       
        beta(active & x_less_1) = ...
            longway(active & x_less_1) .* ...
            2.*asin(sqrt((s(active & x_less_1)-c(active & x_less_1))/2./a(active & x_less_1)));
        
        beta(active & ~x_less_1) = ...
            longway(active & ~x_less_1) .* ...
            2.*asinh(sqrt((s(active & ~x_less_1)-c(active & ~x_less_1))./(-2.*a(active & ~x_less_1))));
        alfa(active & x_less_1) = 2*acos( max(-1, min(1, x(active & x_less_1))) );
        alfa(active & ~x_less_1) = 2*acosh(x(active & ~x_less_1));
        
        % evaluate the time of flight via Lagrange expression
        a_pos = a>0;
        tof(active & a_pos) = a(active & a_pos).*sqrt(a(active & a_pos)).*((alfa(active & a_pos) - sin(alfa(active & a_pos))) - (beta(active & a_pos)-sin(beta(active & a_pos))));
        tof(active & ~a_pos) = -a(active & ~a_pos).*sqrt(-a(active & ~a_pos)).*((sinh(alfa(active & ~a_pos)) - alfa(active & ~a_pos)) - (sinh(beta(active & ~a_pos)) - beta(active & ~a_pos)));

        % new value of y
        ynew(active) = log(tof(active)) - logt(active);
        % save previous and current values for the next iterarion
        % (prevents getting stuck between two values)
        x1(active) = x2(active);  x2(active) = xnew(active);
        y1(active) = y2(active);  y2(active) = ynew(active);
        % update error
        err(active) = abs(x1(active) - xnew(active));
        % escape clause
        if (iterations > 15) break; end
    end

    % convert converged value of x
    x = exp(xnew) - 1;
     
    %{
          The solution has been evaluated in terms of log(x+1) or tan(x*pi/2), we
          now need the conic. As for transfer angles near to pi the Lagrange-
          coefficients technique goes singular (dg approaches a zero/zero that is
          numerically bad) we here use a different technique for those cases. When
          the transfer angle is exactly equal to pi, then the ih unit vector is not
          determined. The remaining equations, though, are still valid.
    %}
 
    % Solution for the semi-major axis
    a = a_min./(1-x.^2);

    
    % Calculate psi
    alfa = zeros(size(tf));
    beta = zeros(size(tf));
    psi = zeros(size(tf));
    eta2 = zeros(size(tf));
    eta = zeros(size(tf));
    ih  = zeros(size(tf));
    r2n = zeros(size(tf));
    Vr1 = zeros(size(tf));
    Vt1 = zeros(size(tf));
    Vr2 = zeros(size(tf));
    Vt2 = zeros(size(tf));
    
    beta(x< 1) = longway(x< 1) .* 2.*asin (sqrt((s(x< 1)-c(x< 1))/2./a(x< 1)));
    beta(x>=1) = longway(x>=1) .* 2.*asinh(sqrt((c(x>=1)-s(x>=1))/2./a(x>=1)));
    
    alfa(x< 1) = 2.*acos( max(-1, min(1, x(x< 1))) );
    alfa(x>=1) = 2.*acosh(x(x>=1));

    psi  = (alfa-beta)/2;
    eta2(x< 1) = +2*a(x< 1).* sin(psi(x< 1)).^2./s(x< 1);
    eta2(x>=1) = -2*a(x>=1).*sinh(psi(x>=1)).^2./s(x>=1);
    eta  = sqrt(eta2);

    % unit of the normalized normal vector
    ih = mtimesx(longway, nrmunit);

    % unit vector for normalized [r2vec]
    r2n = mtimesx(r2vec,mr2vec_inv);

    % cross-products
    % don't use cross() (emlmex() would try to compile it, and this way it
    % also does not create any additional overhead)
    
    for i=1:size(r1vec,3)
        for j=1:size(r1vec,4)
            crsprd1(:,:,i,j) = [ih(1,2,i,j)*r1vec(1,3,i,j)-ih(1,3,i,j)*r1vec(1,2,i,j),...
                                ih(1,3,i,j)*r1vec(1,1,i,j)-ih(1,1,i,j)*r1vec(1,3,i,j),...
                                ih(1,1,i,j)*r1vec(1,2,i,j)-ih(1,2,i,j)*r1vec(1,1,i,j)];    
            crsprd2(:,:,i,j) = [ih(1,2,i,j)*  r2n(1,3,i,j)-ih(1,3,i,j)*  r2n(1,2,i,j),...
                                ih(1,3,i,j)*  r2n(1,1,i,j)-ih(1,1,i,j)*  r2n(1,3,i,j),...
                                ih(1,1,i,j)*  r2n(1,2,i,j)-ih(1,2,i,j)*  r2n(1,1,i,j)];
        end
    end

    % radial and tangential directions for departure velocity
    Vr1 = 1./eta./sqrt(a_min) .* (2.*Lambda.*a_min - Lambda - x.*eta);
    Vt1 = sqrt(mr2vec./a_min./eta2 .* sin(dth/2).^2);

    % radial and tangential directions for arrival velocity
    Vt2 = Vt1./mr2vec;
    Vr2 = (Vt1 - Vt2)./tan(dth/2) - Vr1;
    
    % terminal velocities
    V1 = mtimesx(mtimesx(Vr1,r1vec) + mtimesx(Vt1,crsprd1),V);
    V2 = mtimesx(mtimesx(Vr2,r2n) + mtimesx(Vt2,crsprd2),V);
end