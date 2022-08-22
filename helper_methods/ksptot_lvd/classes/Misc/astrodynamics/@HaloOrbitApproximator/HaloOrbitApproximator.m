classdef HaloOrbitApproximator < matlab.mixin.SetGet
    %HaloOrbitApproximator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        gm1(1,1) double
        gm2(1,1) double
        sma2(1,1) double
        radius1(1,1) double
        radius2(1,1) double
        AzUnscaled(1,1) double
        LPt(1,1) string = "L1"
        side(1,1) string = "northern"
        
        %diff corr options
        diffCorAlpha(1,1) double = 0.01;
        adjustIndEnum(1,1) HaloCoordAdjustEnum = HaloCoordAdjustEnum.Z;
    end
    
    properties(Access=public, Dependent)
        T2(1,1) double
        LU(1,1) double
        TU(1,1) double
        VU(1,1) double
        mu(1,1) double
        gL(1,1) double
        AzScaled(1,1) double
    end
    
    properties(Transient)
        corrSol
        manifoldLine(1,1)
        rVectCR3BP_Prim_Manifold(3,1) double
        vVectCR3BP_Prim_Manifold(3,1) double
    end
    
    events
        UpdateCalcWaitbar
    end
    
    methods
        function obj = HaloOrbitApproximator(gm1, gm2, sma2, radius1, radius2, AzUnscaled, LPt, side)
            obj.gm1 = gm1;
            obj.gm2 = gm2;
            obj.sma2 = sma2;
            obj.radius1 = radius1;
            obj.radius2 = radius2;
            obj.AzUnscaled = AzUnscaled;
            obj.LPt = string(upper(LPt));
            obj.side = string(lower(side));
        end
        
        function val = getT2(obj)
            val = computePeriod(obj.sma2, obj.gm1);
        end
        
        function val = get.LU(obj)
            val = obj.sma2;
        end
        
        function val = get.TU(obj)
            val = 1/sqrt((obj.gm1 + obj.gm2)/obj.sma2^3);
        end
        
        function val = get.VU(obj)
            val = obj.LU / obj.TU;
        end
        
        function val = get.mu(obj)
            val = obj.gm2/(obj.gm1 + obj.gm2);
        end
        
        function val = get.gL(obj)
            LP = HaloOrbitApproximator.lagrangePoints(obj.mu);
            
            switch obj.LPt
                case "L1"
                    val = abs(1 - obj.mu - LP(1,1));
                case "L2"
                    val = abs(LP(2,1) - 1 + obj.mu);
                otherwise
                    error('Unknown Lagrange point.');
            end
        end
        
        function val = get.AzScaled(obj)
            val = (obj.AzUnscaled/obj.LU)/obj.gL;
        end
        
        function computeManifold(obj, tFrac, whichManifold, propDurDimensioned, hAx)
            sol = obj.corrSol;
            if(not(isempty(sol)))                
                T = sol.x';
                Y = sol.y';
                
                stateF_Monodromy = reshape(Y(end,7:end),6,6);
                [V,D] = eig(stateF_Monodromy);
                eigvalues = diag(D,0);
                [~, IMaxEig] = max(real(eigvalues));
                [~, IMinEig] = min(real(eigvalues));
                
                Vs = V(:, IMinEig);
                Vu = V(:, IMaxEig);
                
                tFracActual = tFrac * (T(end) - T(1));
                Ynd_corr_Tfrac = deval(sol,tFracActual)';
                stateF_STM = reshape(Ynd_corr_Tfrac(1,7:end),6,6);
                
                Vs_i = stateF_STM * Vs;
                Vu_i = stateF_STM * Vu;
                
                epsilson = [0; 0; 0; 1E-4; 1E-4; 1E-4];
                Xi = Ynd_corr_Tfrac(1,1:6);
                XiS = Xi(:) + epsilson .* normVector(Vs_i);
                XiU = Xi(:) + epsilson .* normVector(Vu_i);
                
                propDur = propDurDimensioned / obj.TU;
                if(propDur > 0)
                    switch whichManifold
                        case HaloArriveDepartManifoldEnum.Arrive
                            [T_manifold, Y_manifold] = obj.simulateOrbit(XiU(:)', propDur, false);
                            
                        case HaloArriveDepartManifoldEnum.Depart
                            [T_manifold, Y_manifold] = obj.simulateOrbit(XiS(:)', -propDur, false);
                            
                        otherwise
                            error('Unknown manifold type.');
                    end
                    
                else
                    T_manifold = 0;
                    Y_manifold = XiS(:)';
                end
                
                Y_manifold_Pos_Dim = Y_manifold(:,1:3) * obj.LU;
                if(isempty(obj.manifoldLine) || not(isgraphics(obj.manifoldLine, 'Line')))
                    obj.manifoldLine = plot3(hAx, Y_manifold_Pos_Dim(:,1), Y_manifold_Pos_Dim(:,2), Y_manifold_Pos_Dim(:,3));
                    obj.manifoldLine.DisplayName = 'Arrival/Departure Orbit';
                else
                    obj.manifoldLine.XData = Y_manifold_Pos_Dim(:,1);
                    obj.manifoldLine.YData = Y_manifold_Pos_Dim(:,2);
                    obj.manifoldLine.ZData = Y_manifold_Pos_Dim(:,3);
                end
                
                primary = [-obj.mu, 0, 0];

                obj.rVectCR3BP_Prim_Manifold = (Y_manifold(1,1:3)-primary)' * obj.LU;
                obj.vVectCR3BP_Prim_Manifold = Y_manifold(1,4:6)' * obj.VU;
            end
        end
        
        function [rVectCR3BP_Prim, vVectCR3BP_Prim, period, approxAzAchieved, corrAzAchieved] = computeCorrectedInitialState(obj, hAx, dispPrimBody, dispSecBody)
            [~,~,~,~,~,~, statesND_approx, ~, Tapprox] = obj.getApproxHaloOrbitInitState(0);
            state0ND_diffCor = obj.differentialCorrector(statesND_approx(1,:), Tapprox);
            
            [Tnd_uncorr,Ynd_uncorr] = obj.simulateOrbit(statesND_approx(1,:), Tapprox, false);
            [Tnd_corr,Ynd_corr, ~,~,~, sol_corr] = obj.simulateOrbit(state0ND_diffCor, 2*Tapprox, false);
            obj.corrSol = sol_corr;
            
            approxAzAchieved = max(abs(statesND_approx(:,3))*obj.LU);
            corrAzAchieved = max(abs(Ynd_corr(:,3))*obj.LU);
            
            fprintf('Approx Az Achieved: %0.3f km\n', approxAzAchieved);
            fprintf('Corrected Az Achieved: %0.3f km\n', corrAzAchieved);
                        
            if(isempty(hAx))
                hAx = axes(figure());
            else
                cla(hAx);
            end
            
            [hTrajApprox, hLPts] = obj.plotHaloOrbit(hAx, statesND_approx);
            [hTrajUnCorr, ~] = obj.plotHaloOrbit(hAx, Ynd_uncorr);
            [hTrajCorr,   ~] = obj.plotHaloOrbit(hAx, Ynd_corr);
            
            legendObjs = [hTrajApprox, hTrajUnCorr, hTrajCorr];
            
            hTrajApprox.DisplayName = 'Approx Halo';
            hTrajUnCorr.DisplayName = 'Uncorrected Halo';
            hTrajCorr.DisplayName   = 'Corrected Halo';
            hLPts.DisplayName = 'L Points';
            
            axis(hAx,'equal');
            hold(hAx,'on');
            
            %Plot secondary
            if(dispSecBody)
                dRad = obj.radius2;
                [X,Y,Z] = sphere(30);
                X = dRad*X + (1-obj.mu)*obj.LU;
                CData = getCDataForSphereWithColormap(Z, 'gray');
                legendObjs(end+1) = surf(hAx, X,dRad*Y,dRad*Z, 'CData',CData, 'BackFaceLighting','lit', 'FaceLighting','gouraud', 'EdgeLighting','gouraud', 'LineWidth',0.1, 'EdgeAlpha',0.1, 'DisplayName','Primary Body');
            end
            
            %Plot primary
            if(dispPrimBody)
                dRad = obj.radius1;
                [X,Y,Z] = sphere(30);
                X = dRad*X + (-obj.mu)*obj.LU;
                CData = getCDataForSphereWithColormap(Z, 'gray');
                legendObjs(end+1) = surf(hAx, X,dRad*Y,dRad*Z, 'CData',CData, 'BackFaceLighting','lit', 'FaceLighting','gouraud', 'EdgeLighting','gouraud', 'LineWidth',0.1, 'EdgeAlpha',0.1, 'DisplayName','Primary Body');
            end
            
%             {'Approx Halo', 'Uncorrected Halo', 'Corrected Halo', 'Primary Body', 'Secondary Body', 'L Points'};
            legend(legendObjs, 'Location','best');
            
            primary = [-obj.mu, 0, 0];
            
            rVectCR3BP_Prim = (Ynd_corr(1,1:3)-primary)' * obj.LU;
            vVectCR3BP_Prim = Ynd_corr(1,4:6)' * obj.VU;
            period = Tapprox * obj.TU;
        end
        
        function state0ND_approx = differentialCorrector(obj, state0ND_approx, Tapprox)
            MU = obj.mu;
            adjustInd = obj.adjustIndEnum.adjustInd;
            
            deltaXDot = Inf;
            deltaZDot = Inf;
            tol = 1E-12;
            while(abs(deltaXDot) > tol || ...
                    abs(deltaZDot) > tol)
                % 1. Propagate the initial state vector using an ODE solver, such as ode45 in Matlab,
                % until the position in y is equal to zero again (T/2).
                [Tnd_uncorr,Ynd_uncorr, te,ye,ie] = obj.simulateOrbit(state0ND_approx, 10*Tapprox, true);
                stateF = Ynd_uncorr(end,:);
                
                % 2. Find the error in x and z velocities at T/2 (x_ and z_).
                deltaXDot = -stateF(4);
                deltaZDot = -stateF(6);
                deltaVect = [deltaXDot;
                    deltaZDot];
                
                % 3. Calculate the change in the initial state required to reduce the error. It is only
                % necessary to change two of the initial states. Since all the zero terms are correct
                % those are left alone, and x and y_ are the only terms that will need to be altered.
                % The initial position in z will remain xed. x0 and y_0 are the values that will
                %be used to change the initial state.
                stateF_kinematic = stateF(1:6);
                stateF_STM = stateF(7:end);
                stateF_STM = reshape(stateF_STM,6,6);
                
                A = [stateF_STM(4,adjustInd), stateF_STM(4,5);
                    stateF_STM(6,adjustInd), stateF_STM(6,5)];
                
                b = [stateF_STM(2,adjustInd), stateF_STM(2,5)];
                
                accelVec = HaloOrbitApproximator.cr3bpODE(Tnd_uncorr(end),stateF_kinematic,MU);
                accelVec = [accelVec(4); accelVec(6)];
                
                vy = stateF_kinematic(5);
                
                RHS = (A - (1/vy)*accelVec*b);
                deltas = RHS \ deltaVect;
                deltas = deltas * obj.diffCorAlpha;
                
                % 4. Now, a new initial state is calculated by adding x0 and y_0 to the original
                %initial state as in Equation 3.59 and Equation 3.60.
                r0_new = state0ND_approx(adjustInd) + deltas(1);
                ydot0_new = state0ND_approx(5) + deltas(2);
                
                % 5. The new estimate for the initial state vector is now:
                state0ND_approx(adjustInd) = r0_new;
                state0ND_approx(5) = ydot0_new;
                
                curVal = log10(max(abs(deltaVect)));
                evtData = matlab.ui.eventdata.ValueChangedData(curVal, log10(tol));
                notify(obj, 'UpdateCalcWaitbar', evtData);
            end
        end
        
        function [x,y,z,xdot,ydot,zdot, statesND, statesDim, Tapprox] = getApproxHaloOrbitInitState(obj, phi0)
            [k, wp, nu, ...
                a21, a22, a23, a24, a31, a32, ...
                b21, b22, b31, b32, ...
                d21, d31, d32, Ax, Az] = obj.getRichardsonConstants();
            
            if(obj.side == "northern")
                m = 1;
            elseif(obj.side == "southern")
                m = 3;
            else
                error('Unknown side parameter');
            end
            
            Tapprox = (2*pi)/(wp*nu);
            tau = linspace(0,Tapprox,100);
            
            deltaM = 2 - m;
            tau1 = wp .* tau + phi0;
            
            g = obj.gL;
            
            x = g*(a21*Ax^2 + a22*Az - Ax*cos(tau1) + (a23*Ax^2 - a24*Az^2)*cos(2*tau1) + ...
                (a31*Ax^3 - a32*Ax*(Az^2)*cos(3*tau1)));
            
            y = g*(k*Ax*sin(tau1) + (b21*Ax^2 - b22*Az^2)*sin(2*tau1) + (b31*Ax^3 - b32*Ax*Az^2)*sin(3*tau1));
            
            z = g*(deltaM*Az*cos(tau1) + deltaM*d21*Ax*Az*(cos(2*tau1) - 3) + deltaM*(d32*Az*Ax^2 - d31*Az^3)*cos(3*tau1));
            
            xdot = g*(wp*nu*Ax*sin(tau1) - 2*wp*nu*(a23*Ax^2 - a24*Az^2)*sin(2*tau1) - 3*wp*nu*(a31*Ax^3 - a32*Ax*Az^2)*sin(3*tau1));
            
            ydot = g*(wp*nu*k*Ax*cos(tau1) + 2*wp*nu*(b21*Ax^2 - b22*Az^2)*cos(2*tau1) + 3*wp*nu*(b31*Ax^3 - b32*Ax*Az^2)*cos(3*tau1));
            
            zdot = g*(-wp*nu*deltaM*Az*sin(tau1) - 2*wp*nu*deltaM*d21*Ax*Az*sin(2*tau1) - 3*wp*nu*deltaM*(d32*Az*Ax^2 - d31*Az^2)*sin(3*tau1));
            
            LP = HaloOrbitApproximator.lagrangePoints(obj.mu);
            switch obj.LPt
                case "L1"
                    deltaX = LP(1,1);
                case "L2"
                    deltaX = LP(2,1);
                otherwise
                    error('Unknown Lagrange point.');
            end
            
            x = x + deltaX; %need to move the x-coords back to the barycenter for integration in the synodic frame
            
            statesND = [x(:), y(:), z(:), xdot(:), ydot(:), zdot(:)];
            statesDim = [x(:)*obj.LU, ...
                y(:)*obj.LU, ...
                z(:)*obj.LU, ...
                xdot(:)*obj.VU, ...
                ydot(:)*obj.VU, ...
                zdot(:)*obj.VU];
        end
        
        function [hTraj, hLPts] = plotHaloOrbit(obj, hAx, statesND)
            LP = HaloOrbitApproximator.lagrangePoints(obj.mu);
            LP = LP * obj.LU;
            
            statesDim = statesND * obj.LU;
            
            hold(hAx, 'on');
            hTraj = plot3(hAx, statesDim(:,1), statesDim(:,2), statesDim(:,3));
            grid(hAx, 'off');
            grid(hAx, 'minor');
            %             plot3(-obj.mu, 0, 0, 'ko');
            %             hSecBody = plot3(hAx, (1-obj.mu)*obj.LU, 0, 0, 'ko');
            %             hSecBody = obj.plotBody(hAx);
            hLPts = plot3(hAx, LP(1:2,1), LP(1:2,2), LP(1:2,3), 'bo');
            %             axis(hAx,'equal');
            hold(hAx, 'off');
            xlabel(hAx,'X [km]');
            ylabel(hAx,'Y [km]');
            zlabel(hAx,'Z [km]');
        end
        
        function hCBodySurf = plotBody(obj, hAx)
            dRad = obj.radius2 / obj.LU;
            [X,Y,Z] = sphere(50);
            
            CData = getCDataForSphereWithColormap(Z, 'gray');
            hCBodySurf = surf(hAx, dRad*X,dRad*Y,dRad*Z, 'CData',CData, 'BackFaceLighting','lit', 'FaceLighting','gouraud', 'EdgeLighting','gouraud', 'LineWidth',0.1, 'EdgeAlpha',0.1);
            material(hCBodySurf,'dull');
        end
        
        function [T,Y, te,ye,ie, sol] = simulateOrbit(obj, y0, tf, stopOnYCrossing)
            tspan=[0 tf];
            
            if(numel(y0) == 6)
                y0 = [y0(:)', reshape(eye(6),1,36)];
            end
            
            odefun = @(t,y) HaloOrbitApproximator.stateTransMatrixODE(t,y,obj.mu);
            
            evtFcn = @(t,y) HaloOrbitApproximator.odeEvents(t,y, stopOnYCrossing);
            options=odeset('RelTol',1e-12,'AbsTol',1e-12,'Events',evtFcn);
            
            sol = ode113(odefun, tspan, y0, options);
            
            T = sol.x';
            Y = sol.y';
            te = sol.xe';
            ye = sol.ye';
            ie = sol.ie';
        end
    end
    
    methods(Access=private)
        function f = correctedHaloOrbitObjFun(obj, x, state0ND_approx, Tapprox)
            xNew = x(1);
            zNew = x(2);
            ydotNew = x(3);
            state0ND_approx([1,3,5]) = [xNew, zNew, ydotNew];
            
            [~,Ynd, ~,~,~] = obj.simulateOrbit(state0ND_approx, 10*Tapprox, true);
            aZAchieved = max(abs(Ynd(:,3))*obj.LU);
            
            f = abs((aZAchieved - obj.AzUnscaled)/abs(obj.AzUnscaled));
        end
        
        function [c, ceq] = correctedHaloOrbitNonlcon(obj, x, state0ND_approx, Tapprox)
            xNew = x(1);
            zNew = x(2);
            ydotNew = x(3);
            state0ND_approx([1,3,5]) = [xNew, zNew, ydotNew];
            
            [~,Ynd, ~,~,~] = obj.simulateOrbit(state0ND_approx, 10*Tapprox, true);
            
            c = [];
            ceq(1) = Ynd(end,2); %y=0
            ceq(2) = Ynd(end,3); %xdot = 0
            ceq(3) = Ynd(end,5); %zdot = 0
        end
        
        function [k, wp, nu, ...
                a21, a22, a23, a24, a31, a32, ...
                b21, b22, b31, b32, ...
                d21, d31, d32, Ax, Az] = getRichardsonConstants(obj)
            
            %             c2 = (1/obj.gL^3) * (obj.mu + ((1-obj.mu)*obj.gL^3)/(1-obj.gL)^3);
            %             c3 = (1/obj.gL^3) * (obj.mu - ((1-obj.mu)*obj.gL^4)/(1-obj.gL)^4);
            %             c4 = (1/obj.gL^3) * (obj.mu + ((1-obj.mu)*obj.gL^5)/(1-obj.gL)^5);
            
            [~, c2, c3, c4] = obj.computeCCoeff();
            
            wp = sqrt(2 - c2 + ((9*c2^2 - 8*c2)/2)^(1/2));
            k = (wp^2 + 1 + 2*c2)/(2*wp);
            
            d1 = ((3*wp^2)/k) * (k*(6*wp^2-1)-2*wp);
            d2 = ((8*wp^2)/k) * (k*(11*wp^2-1)-2*wp);
            
            a21 = (3*c3*(k^2-2))/(4*(1+2*c2));
            a22 = (3*c3)/(4*(1+2*c2));
            a23 = ((-3*c3*wp)/(4*k*d1))*(3*(k^3)*wp - 6*k*(k-wp) + 4);
            a24 = ((-3*c3*wp)/(4*k*d1))*(2+3*k*wp);
            
            d21 = -c3/(2*wp^2);
            d31 = (3/(64*wp^2)) * (4*c3*a24 + c4);
            d32 = (3/(64*wp^2)) * (4*c3*(a23 - d21) + c4*(4+k^2));
            
            b21 = ((-3*c3*wp)/(2*d1))*(3*k*wp - 4);
            b22 = (3*c3*wp)/d1;
            b31 = (3/(8*d2)) * (8*wp*(3*c3*(k*b21 - 2*a23) - c4*(2+3*k^2)) + ...
                (9*wp^2 + 1 + 2*c2)*(4*c3*(k*a23-b21)+(k*c4*(4+k^2))));
            b32 = (1/d2) * (9*wp*(c3*(k*b22 + d21 - 2*a24) - c4) + ...
                (3/8)*(9*wp^2 + 1 + 2*c2)*(4*c3*(k*a24-b22)+(k*c4)));
            
            a31 = (-9*wp/(4*d2)) * (4*c3*(k*a23 - b21) + k*c4*(4+k^2)) + ...
                ((9*wp^2 + 1 - c2)/(2*d2))*(3*c3*(2*a23-k*b21)+(c4*(2+3*k^2)));
            a32 = (-1/d2) * ((9/4)*wp*(4*c3*(k*a24 - b22) + k*c4) + ...
                (3/2)*(9*wp^2 + 1 - c2)*(c3*(k*b22 + d21 - 2*a24) - c4));
            
            s1 = (1/(2*wp*(wp*(1+k^2)-2*k))) * ((3/2)*c3*(2*a21*(k^2-2) - a23*(k^2+2) - 2*k*b21) - ...
                (3/8)*c4*(3*k^4 - 8*k^2 + 8));
            s2 = (1/(2*wp*(wp*(1+k^2)-2*k))) * ((3/2)*c3*(2*a22*(k^2-2) + a24*(k^2+2) + 2*k*b22 + 5*d21) + ...
                (3/8)*c4*(12 - k^2));
            
            a1 = (-3/2)*c3*(2*a21 + a23 + 5*d21) - (3/8)*c4*(12-k^2);
            a2 = (3/2)*c3*(a24 - 2*a22) + (9/8)*c4;
            
            l1 = a1 + 2*(wp^2)*s1;
            l2 = a2 + 2*(wp^2)*s2;
            
            delta = wp^2 - c2;
            
            Az = obj.AzScaled;
            Ax = sqrt((-l2 * Az^2 - delta)/l1);
            
            nu = 1 + s1*Ax^2 + s2*Az^2;
        end
        
        function [c1, c2, c3, c4] = computeCCoeff(obj)
            g = obj.gL;
            m = obj.mu;
            
            switch obj.LPt
                case "L1"
                    Ceqn = @(n) (1/((g^3)*(1-g^(n+1)))) * (m + ((-1)^n)*(1 - m)*g^(n+1));
                case "L2"
                    Ceqn = @(n) (1/((g^3)*(1+g^(n+1)))) * (((-1)^n)*m + ((-1)^n)*(1 - m)*g^(n+1));
                otherwise
                    error('Unknown Lagrange point.');
            end
            
            c = NaN(4,1);
            for(n=1:4)
                c(n) = Ceqn(n);
            end
            
            c1 = c(1);
            c2 = c(2);
            c3 = c(3);
            c4 = c(4);
        end
    end
    
    methods(Static)
        function [value,isterminal,direction] = odeEvents(~,y, stopOnYCrossing)
            value = y(2); %when y=0
            direction = 0;
            
            if(stopOnYCrossing)
                isterminal = 1;
            else
                isterminal = 0;
            end
        end
        
        function LP = lagrangePoints(mu)
            %For a given value of mu, this function computes the location
            %of all five libration points for the circular restricted three
            %body problem.  It returns them as equilibrium points in R^3
            %space.  Then the output is five points each with three components.
            %Each point is a column in a matrix with three rows.  The first column is
            %L1, the second L2, and so on to the last which is L5.
            
            
            %Compute the location of the libration points
            l=1-mu;
            
            LP = zeros(5,3);
            
            %L1
            p_L1=[1, 2*(mu-l), l^2-4*l*mu+mu^2, 2*mu*l*(l-mu)+mu-l, mu^2*l^2+2*(l^2+mu^2), mu^3-l^3];
            L1roots=roots(p_L1);
            %initialize L1 for loop
            L1=0;
            for i=1:5
                if (L1roots(i) > -mu) && (L1roots(i) < l)
                    L1=L1roots(i);
                end
            end
            LP(1,1) = L1;
            
            
            %L2
            p_L2=[1, 2*(mu-l), l^2-4*l*mu+mu^2, 2*mu*l*(l-mu)-(mu+l), mu^2*l^2+2*(l^2-mu^2), -(mu^3+l^3)];
            L2roots=roots(p_L2);
            %initialize L2 for loop
            L2=0;
            for i=1:5
                if (L2roots(i) > -mu) && (L2roots(i) > l)
                    L2=L2roots(i);
                end
            end
            LP(2,1) = L2;
            
            
            %L3
            p_L3=[1, 2*(mu-l), l^2-4*mu*l+mu^2, 2*mu*l*(l-mu)+(l+mu), mu^2*l^2+2*(mu^2-l^2), l^3+mu^3];
            L3roots=roots(p_L3);
            %initialize L3 for loop
            L3=0;
            for i=1:5
                if L3roots(i) < -mu
                    L3=L3roots(i);
                end
            end
            LP(3,1) = L3;
            
            
            %L4
            LP(4,1) = 0.5 - mu;
            LP(4,2) = sqrt(3)/2;
            
            
            %L5
            LP(5,1) = 0.5 - mu;
            LP(5,2) = -sqrt(3)/2;
        end
        
        function xdot = stateTransMatrixODE(t,xinput,mu)
            xstate = xinput(1:6);
            xstatedot = HaloOrbitApproximator.cr3bpODE(t,xstate,mu);
            
            PHI = reshape(xinput(7:6*6+6),6,6);
            
            x=xstate(1);
            y=xstate(2);
            z=xstate(3);
            
            x1 = -mu;
            x2 = 1-mu;
            
            r1 = sqrt((x-x1)^2 + y^2 + z^2);
            r2 = sqrt((x-x2)^2 + y^2 + z^2);
            
            OMEGA_XX = 1 + (1-mu)*((3*(x-x1)^2/r1^5) - 1/r1^3) ...
                + mu*((3*(x-x2)^2/r2^5) - 1/r2^3);
            
            OMEGA_YY = 1 + (1-mu)*((3*y^2/r1^5) - 1/r1^3) ...
                + mu*((3*y^2/r2^5) - 1/r2^3);
            
            OMEGA_XY = 3*(1-mu)*(x-x1)*y/r1^5 + 3*mu*(x-x2)*y/r2^5;
            
            OMEGA_XZ = 3*(1-mu)*z*(x-x1)/r1^5 + 3*mu*z*(x-x2)/r2^5;
            
            OMEGA_YZ = 3*(1-mu)*y*z/r1^5 + 3*mu*y*z/r2^5;
            
            OMEGA_ZZ = 3*(1-mu)*z^2/r1^5 - (1-mu)/r1^3 + 3*mu*z^2/r2^5 - mu/r2^3;
            
            A  = [0 0 0 1 0 0;
                0 0 0 0 1 0;
                0 0 0 0 0 1;
                OMEGA_XX OMEGA_XY OMEGA_XZ 0 2 0;
                OMEGA_XY OMEGA_YY OMEGA_YZ -2 0 0;
                OMEGA_XZ OMEGA_YZ OMEGA_ZZ 0 0 0];
            PHIdot = A * PHI;
            
            xdot = [xstatedot;reshape(PHIdot,6*6,1)];
        end
        
        function ydot = cr3bpODE(t,y, mu)
            %Define the distances from 1 and 2 to the s/c
            r1 = sqrt((y(1)+mu)^2 + y(2)^2 + y(3)^2);
            r2 = sqrt((y(1)-(1-mu))^2 + y(2)^2 + y(3)^2);
            
            %the deriative functions here
            %velocities
            ydot(1) = y(4);
            ydot(2) = y(5);
            ydot(3) = y(6);
            
            %accelerations
            ydot(4) = 2*y(5) + y(1) - ((1-mu)*(y(1)+mu))/r1^3 - (mu*(y(1)-1+mu))/r2^3;
            ydot(5) = -2*y(4) + y(2) - ((1-mu)*y(2))/r1^3 - mu*y(2)/r2^3;
            ydot(6) = (-(1-mu)*y(3))/r1^3 - (mu*y(3))/r2^3;
            
            ydot=ydot';
        end
    end
end


%         function [k, lambda, omega, ...
%                   a21, a22, a23, a24, a31, a32, ...
%                   b21, b22, b31, b32, ...
%                   d21, d31, d32, Ax, Ay, Az] = getRichardsonConstants(obj)
%
%             c2 = (1/obj.gL^3) * (obj.mu + ((1-obj.mu)*obj.gL^3)/(1-obj.gL)^3);
%             c3 = (1/obj.gL^3) * (obj.mu - ((1-obj.mu)*obj.gL^4)/(1-obj.gL)^4);
%             c4 = (1/obj.gL^3) * (obj.mu + ((1-obj.mu)*obj.gL^5)/(1-obj.gL)^5);
%
%             p = [1, 0, (c2-2), 0, -(c2-1)*(1+2*c2)];
%             p_roots = roots(p);
%             lambda = real(p_roots(real(p_roots) > 0 & imag(p_roots) == 0));
%
%             k = 2*lambda/(lambda^2 + 1 - c2);
%
%             d1 = ((3*lambda^2)/k) * (k*(6*lambda^2-1)-2*lambda);
%             d2 = ((8*lambda^2)/k) * (k*(11*lambda^2-1)-2*lambda);
%
%             a21 = (3*c3*(k^2-2))/(4*(1+2*c2));
%             a22 = (3*c3)/(4*(1+2*c2));
%             a23 = ((-3*c3*lambda)/(4*k*d1))*(3*(k^3)*lambda - 6*k*(k-lambda) + 4);
%             a24 = ((-3*c3*lambda)/(4*k*d1))*(2+3*k*lambda);
%
%             d21 = -c3/(2*lambda^2);
%             d31 = (3/(64*lambda^2)) * (4*c3*a24 + c4);
%             d32 = (3/(64*lambda^2)) * (4*c3*(a23 - d21) + c4*(4+k^2));
%
%             b21 = ((-3*c3*lambda)/(2*d1))*(3*k*lambda - 4);
%             b22 = (3*c3*lambda)/d1;
%             b31 = (3/(8*d2)) * (8*lambda*(3*c3*(k*b21 - 2*a23) - c4*(2+3*k^2)) + ...
%                                          (9*lambda^2 + 1 + 2*c2)*(4*c3*(k*a23-b21)+(k*c4*(4+k^2))));
%             b32 = (1/d2) * (9*lambda*(c3*(k*b22 + d21 - 2*a24) - c4) + ...
%                                          (3/8)*(9*lambda^2 + 1 + 2*c2)*(4*c3*(k*a24-b22)+(k*c4)));
%
%             a31 = (-9*lambda/(4*d2)) * (4*c3*(k*a23 - b21) + k*c4*(4+k^2)) + ...
%                                          ((9*lambda^2 + 1 - c2)/(2*d2))*(3*c3*(2*a23-k*b21)+(c4*(2+3*k^2)));
%             a32 = (-1/d2) * ((9/4)*lambda*(4*c3*(k*a24 - b22) + k*c4) + ...
%                                           (3/2)*(9*lambda^2 + 1 - c2)*(c3*(k*b22 + d21 - 2*a24) - c4));
%
%             s1 = (1/(2*lambda*(lambda*(1+k^2)-2*k))) * ((3/2)*c3*(2*a21*(k^2-2) - a23*(k^2+2) - 2*k*b21) - ...
%                                                         (3/8)*c4*(3*k^4 - 8*k^2 + 8));
%             s2 = (1/(2*lambda*(lambda*(1+k^2)-2*k))) * ((3/2)*c3*(2*a22*(k^2-2) + a24*(k^2+2) + 2*k*b22 + 5*d21) + ...
%                                                         (3/8)*c4*(12 - k^2));
%
%             a1 = (-3/2)*c3*(2*a21 + a23 + 5*d21) - (3/8)*c4*(12-k^2);
%             a2 = (3/2)*c3*(a24 - 2*a22) + (9/8)*c4;
%
%             l1 = a1 + 2*(lambda^2)*s1;
%             l2 = a2 + 2*(lambda^2)*s2;
%
%             delta = lambda^2 - c2;
%
%             Az = (obj.AzUnscaled/obj.LU)*obj.gL;
%             Ay = Az/obj.gL;
%             Ax = sqrt((-l2 * Az^2 - delta)/l1);
%
%             omega = 1 + s1*Ax^2 + s2*Az^2;
%         end