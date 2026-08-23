classdef PoweredExplicitGuidance < matlab.mixin.SetGet
    %PoweredExplicitGuidance Summary of this class goes here
    %   Detailed explanation goes here

    properties
        tgt_P(1,1) double = 700*1000;

        oldA_P(1,1) double = 0;
        oldB_P(1,1) double = 0;
        oldT_P(1,1) double = 100;

        lastCallUT(1,1) double = 0;
    end

    methods
        function obj = PoweredExplicitGuidance(tgt)
            obj.tgt_P = tgt;
        end

        function reset(obj, ut, tEstimate)
            obj.oldA_P = 0;
            obj.oldB_P = 0;
            obj.oldT_P = tEstimate;
            obj.lastCallUT = ut;
        end

        function [A, B, C, T] = poweredExplicitGuidance(obj, ut, mu, alt, vt, vr, acc, ve)
            %[A, B, C, T] = POWEREDEXPLICITGUIDANCE(cycle, alt, vt, vr, target,
            %                                                acc, ve, oldA, oldB, oldT)
            %LEGACY implementation of Powered Explicit Guidance as described by Teren
            %in Explicit Guidance Equations for Multistage Boost Trajectories.
            %http://ntrs.nasa.gov/archive/nasa/casi.ntrs.nasa.gov/19660006073.pdf
            %http://www.orbiterwiki.org/wiki/Powered_Explicit_Guidance
            %Only a single-stage capability is implemented with no yaw control.
            %If time to cutoff is less than 7.5 seconds, will cease solving the matrix
            %for A and B and return old values (only updating T).
            %
            %INPUT
            %    mu         Global variable, standard gravity parameter of the body;
            %               gravity constant * mass of the body (kg).
            %    cycle      Length of the major cycle (time between PEG calls) (s).
            %    alt        Current altitude relative to body center (m).
            %    vt     	Tangential (horizontal) velocity (m/s).
            %    vr         Radial (vertical) velocity (m/s).
            %    tgt    	Target altitude relative to body center (m).
            %    acc    	Current vehicle acceleration due to thrust (m/s^2).
            %    ve         Effective exhaust velocity (Isp*g0) (m/s).
            %    oldA       Previous value of A.
            %    oldB       Previous value of B. If oldA==oldB==0, those will be
            %               estimated from oldT (this needs to be a "reasonable guess"
            %               in this case). Otherwise (ie. if the algorithm is converged
            %               or converging), previously obtained values need to be passed.
            %    oldT       Previous value of T (s).
            %
            %OUTPUT
            %    A          Steering constant, cosine of pitch angle right now.
            %    B          Steering constant corresponding to pitch rate, ie. pitch
            %               after t seconds from when these values were calculated
            %               should equal acosd(A+B*t).
            %    C          Portion of vehicle acceleration used to counteract gravity
            %               and centrifugal force (unitless).
            %    T          Time to go (until the end of burn) (s).
            cycle = ut - obj.lastCallUT;
            tgt  = obj.tgt_P;
            oldA = obj.oldA_P;
            oldB = obj.oldB_P;
            oldT = obj.oldT_P;

            tau = ve / acc;
            if oldA==0 && oldB==0
                %calculate A and B (PEG.pdf, page 22)
                b0 = -ve*log(1-oldT/tau);
                b1 = b0*tau - ve*oldT;
                c0 = b0*oldT - b1;
                c1 = c0*tau - ve*oldT^2/2;
                matA = [b0 b1;
                        c0 c1];
                matB = [-vr;
                        tgt - alt - vr*oldT];
                matX = linsolve(matA, matB);
                oldA = matX(1);
                oldB = matX(2);
            end
                
            %current and target angular momentum, change in momentum
            angM = norm(cross([alt 0 0], [vr; vt; 0]));
            tgtV = sqrt(mu/tgt);
            tgtM = norm(cross([tgt 0 0], [0; tgtV; 0]));
            dMom = tgtM - angM;
            
            %based on old ABT (or freshly estimated values) calculate steering constant series f_r (eq 22)
            C = (mu/tgt^2 - tgtV^2/tgt) / (acc / (1-oldT/tau));  %target values
            f_r_T = oldA + oldB*oldT + C;
            C = (mu/alt^2 - vt^2/alt) / acc;    %current values
            f_r = oldA + C;
            f_r_dot = (f_r_T - f_r) / oldT;
            
            %based on that series calculate steering constant series f_theta (eq 25)
            %f_h terms omitted because we're not doing yaw steering (yet?)
            f_theta = 1 - f_r^2/2;
            f_theta_dot = -f_r*f_r_dot;
            f_theta_2dot = -f_r_dot^2/2;
            
            %based on that series and old-but-updated T (old - delta T) calculate delta-v (eq 36)
            avgR = (alt + tgt)/2;
            deltav = dMom/avgR + ve*(oldT-cycle)*(f_theta_dot+f_theta_2dot*tau) + f_theta_2dot*ve*(oldT-cycle)^2/2;
            deltav = deltav / (f_theta + f_theta_dot*tau + f_theta_2dot*tau^2);
            
            %based on that delta-v calculate the new T (eq 37b)
            T = tau*(1-exp(-deltav/ve));
            
            %solve matrix for new steering constants AB
            %however, don't do it if T is too small
            if (T>=7.5)
                b0 = -ve*log(1-T/tau);
                b1 = b0*tau - ve*T;
                c0 = b0*T - b1;
                c1 = c0*tau - ve*T^2/2;
                matA = [b0 b1;
                        c0 c1];
                matB = [-vr;
                        tgt - alt - vr*T];
                matX = linsolve(matA, matB);
                A = matX(1);
                B = matX(2);
            else
                %in such case, just live with the old values
                A = oldA;
                B = oldB;
            end

            obj.lastCallUT = ut;
            obj.oldA_P = A;
            obj.oldB_P = B;
            obj.oldT_P = T;
        end
    end
end