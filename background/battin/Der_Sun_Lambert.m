function [V1,a,ecc,nfeval]=Der_Sun_Lambert(R1,R2,mu,dt,del_nu,n_rev)
%% Description
% This calculates the solution to Lambert's Problem using the Der algorythm
% which is a modified Sun algorythm. See "The Superior Lambert Algorithm"
% Gim J. Der

%% Calculations
r1=norm(R1);
r2=norm(R2);
c=norm(R1-R2);
m=r1+r2+c;
sig=sqrt(4*r1*r2/m^2*cos(del_nu/2)); %equation 6 in paper

% Step 1, 
% Comput the transfer angle del_nu between the two position vectors
% (already given to the program) and assign sigma to match.
if del_nu>0 && del_nu<pi
    sig=abs(sig); %make sure sigma is positive
elseif del_nu==pi || del_nu==2*pi
    sig=0;
elseif del_nu>pi && del_nu<2*pi
    sig=-abs(sig); % make sure sigma is negative
end

% Step 2
% Comput the normalized time (t1_new=0, t2_new=t2-t1)
t_normalized=4*dt*sqrt(mu/m^3);

% Step 3
% Compute the parabolic normalized time which will allow us to determine
% orbit type
t_parabolic=2/3*(1-sig^3);

% Step 4
% Perform Different Actions Depending on orbit type

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ELLIPTICAL - Single Rev
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if t_normalized>t_parabolic && n_rev==0
    % we have an elliptical transfer
    %N_max=integer(t_normalized/pi); % we are specifying the number of revs
    %so we don't have to look at all the cases
    
    % Step 7
    % Compute the normalized minimum energy time which will help us guess
    % the starting place for x and then we can iterate on it easily.
    t_me=n_rev*pi+acos(sig)+sig*sqrt(1-sig^2);
    
    % Step 8
    if dt<t_me
        x=0.5; %initial startin guess for x
    elseif dt==t_me
        x=0; %we have just found x, don't do any more computation
    elseif dt>t_me
        x=-0.5; %initial starting guess for x
    end
    
    % Step 8b 
    % Iterate to find x and y using Equation 5
    if x~=0; %don't want to start if we already solved x=0
        x_new=x;
        x=0; % used to kickstart loop
        tol=1e-6;
        while abs(x-x_new)>tol
            x=x_new
            [F,Fp,Fpp]=LambertEQ(x,t_normalized,n_rev,sig)
            n=2; %set per suggestion in paper page 5
            x_new=x-n*F/(Fp+sign(Fp)*sqrt((n-1)^2*Fp^2-n*(n-1)*F*Fpp)) %equation 5 implementation
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ELLIPTICAL - Multi-Rev
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if t_normalized>t_parabolic && n_rev>=1
    t_me=n_rev*pi+acos(sig)+sig*sqrt(1-sig^2);
    if dt>t_me
        x=0.5; %initial startin guess for x
    elseif dt==t_me
        x=0; %we have just found x, don't do any more computation
    elseif dt<t_me
        x=-0.5; %initial starting guess for x
    end    
    
    
    
    %n_rev=[0:1:N_max];
        x=1; %kickstart for loop
        x_new=0; % first guess for x
        % x should be between -1<x<1 for elliptic orbits
        tol=1e-6;
        %newton's iteration to find x
        while abs(x-x_new)>tol
            x=x_new;
            x_new=x-Phi_o_Phip(x,sig,n_rev);
        end
        x_mt=x;
        if sig^2~=0
            y=sign(sig)*sqrt((1-sig^2)*(1-x_mt^2));
        elseif sig^2==1
            y=1;
        end
        y_mt=y;
        t_mt=2/3*(1/x_mt-sig^3/abs(y_mt));
        t_me=0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARABOLIC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if t_normalized==t_parabolic
    x=1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HYPERBOLIC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Will not comput answer for Hyperbolic Orbits
if t_normalized>t_parabolic && n_rev<1
    Disp('Error: Orbit Type Hyperbolic. Der_Sun no applicable')
    return
end

% Determin the y value based off the iterated x value
if sig^2~=0
    y=sign(sig)*sqrt((1-sig^2)*(1-x^2));
elseif sig^2==1
    y=1;
end

% After completing x and y iteration solve for V1
ec=(R2-R1)/c;
er1=R1/r1;
%er2=R2/r2; %not used in our forlumation because we don't solve for V2
n=r1+r2-c;
Vc=sqrt(mu)*(y/sqrt(n)+x/sqrt(m));
Vr=sqrt(mu)*(y/sqrt(n)-x/sqrt(m));
V1=Vc*ec+Vr*er1;
            


