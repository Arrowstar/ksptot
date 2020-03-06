classdef AbstractFixedStepIntegrator < AbstractIntegrator
    %ODE5Integrator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant, Access=private)
        %RK5
%         At = [ 1/5,          0,           0,            0,         0
%                3/40,         9/40,        0,            0,         0
%                44/45        -56/15,       32/9,         0,         0
%                19372/6561,  -25360/2187,  64448/6561,  -212/729,   0
%                9017/3168,   -355/33,      46732/5247,   49/176,   -5103/18656];
%         
%         Bt = [35/384, 0, 500/1113, 125/192, -2187/6784, 11/84];
%         
%         Ct = [1/5; 3/10; 4/5; 8/9; 1];

        %RK4
%         At = [1/2,  0,  0;
%                0, 1/2,  0;
%                0,   0,  1;]
%            
%        Bt = [1/6, 1/3, 1/3, 1/6];
%        
%        Ct = [1/2, 1/2, 1];

        %RK2
%         At = [1, 1];
%         Bt = [1/2, 1/2];
%         
%         Ct = [1];

        %Ralston's 4th Order Method
%         At = [1/2,   0,   0;
%                 0, 1/2,   0;
%                 0,   0,   1];
%             
%        Bt = [1/6, 1/3, 1/3, 1/6];
%        
%        Ct = [1/2, 1/2, 1];
    end
    
%     methods
%         function obj = ODE5Integrator()
%             
%         end
%     end
    
    methods(Static)   
        function [t,y, te,ye,ie] = integrate(odefun, tspan, y0, options)
            [h,y0,~] = ODE5Integrator.checkInputs(odefun, tspan, y0);
            
            if(not(isempty(options.OutputFcn)) && ...
               isa(options.OutputFcn,'function_handle'))
                hasOutput = true;
                outputFcn = options.OutputFcn;
            else
                hasOutput = false;
                outputFcn = [];
            end
            
            if(not(isempty(options.Events)) && ...
               isa(options.Events,'function_handle'))
                hasEvents = true;
                eventFcn = options.Events;
            else
                hasEvents = false;
                eventFcn = [];
            end
            
            neq = length(y0);
            N = length(tspan);
            t = NaN(N,1);
            Y = NaN(neq,N);
            
            Y(:,1) = y0;
            t(1) = tspan(1);

            if(hasOutput)
                outputFcn([tspan(1) tspan(end)],y0,'init');
            end
            
            ie = [];
            te = [];
            ye = [];
            if(hasEvents)
                [prevEvtValues,~,~] = eventFcn(t(1),Y(:,1));
            else
                prevEvtValues = [];
            end
            
            evtTerminate = false;
            outputTerminate = false;
            
            ti = t(1);
            i = 2;
            while(ti < tspan(end))
                ti = tspan(i-1);
                if(ti >= tspan(end))
                    break;
                end

                hi = h(i-1);
                yi = Y(:,i-1);
                
                t(i) = tspan(i);
                Y(:,i) = ODE5Integrator.stepOnce(odefun, ti, yi, hi, neq);
                
                if(hasEvents)
                    [evtValues,evtIsTerminal,evtDirection] = eventFcn(t(i),Y(:,i));
                    
                    signDetect = prevEvtValues .* evtValues < 0;
                    if(any(signDetect))
                        diffForDeriv = sign(evtValues - prevEvtValues);
                        
                        rootFcn = @(subHi) ODE5Integrator.rootFindingFunc(subHi, odefun, ti, yi, neq, eventFcn);
                        [tSubI,~,exitflag,~] = fminbnd(rootFcn,t(i-1),t(i));
                        
                        if(exitflag == 1)
                            [~, evtInd] = rootFcn(tSubI);
                            if(evtDirection(evtInd) == 0 || ...
                               diffForDeriv(evtInd) == evtDirection(evtInd))
                                
                                tspan1 = tspan(1:i-1);
                                tspan2 = tspan(i:end);
                                tspan = [tspan1, tSubI, tspan2];

                                h1 = h(1:i-1);
                                h2 = h(i:end);
                                hi = tSubI - ti;
                                h = [h1, hi, h2];

                                t(i) = tspan(i);
                                Y(:,i) = ODE5Integrator.stepOnce(odefun, ti, yi, hi, neq);

                                ie(end+1,1) = evtInd;
                                te(end+1,1) = tSubI;
                                ye(end+1,:) = Y(:,i)';
                                
                                if(evtIsTerminal(evtInd) == 1)
                                    evtTerminate = true;
                                else
                                    evtTerminate = false;
                                end
                            else
                                evtTerminate = false;
                            end
                        end
                    end
                    
                    prevEvtValues = evtValues;
                end
                
                if(hasOutput)
                    status = outputFcn(t(i),Y(:,i),[]);
                    if(status == 1)
                        outputTerminate = true;
                    else
                        outputTerminate = false;
                    end
                end
                
                if(evtTerminate || outputTerminate)
                    break;
                end
                
                i=i+1;
            end
            
            y = Y.';
            
            bool = ~isnan(t);
            t = t(bool);
            y = y(bool,:);
            
            if(hasOutput)
                outputFcn([],[],'done');
            end
        end    
    
    end
    
    methods(Static, Access=protected) 
        [A,B,C] = getButcherTableauData();
        
        function [h,y0,f0] = checkInputs(odefun, tspan, y0)
            if ~isnumeric(tspan)
                error('TSPAN should be a vector of integration steps.');
            end
            
            if ~isnumeric(y0)
                error('Y0 should be a vector of initial conditions.');
            end
            
            h = diff(tspan);
            if any(sign(h(1))*h <= 0)
                error('Entries of TSPAN are not in order.')
            end
            
            try
                f0 = odefun(tspan(1),y0);
            catch ME
                msg = ['Unable to evaluate the ODEFUN at t0,y0: ',ME.message];
                error(msg);
            end
            
            y0 = y0(:);   % Make a column vector.
            if ~isequal(size(y0),size(f0))
                error('Inconsistent sizes of Y0 and f(t0,y0).');
            end
        end
        
        function [yNp1, fEvals] = stepOnce(odefun, ti, yi, hi, neq)
            [A,B,C] = ODE5Integrator.getButcherTableauData();
            
            nstages = length(B);
            F = NaN(neq,nstages);
            
            % General explicit Runge-Kutta framework
            F(:,1) = odefun(ti,yi);
            for stage = 2:nstages
                tstage = ti + C(stage-1)*hi;
                ystage = yi + F(:,1:stage-1)*(hi*A(1:stage-1,stage-1));
                F(:,stage) = odefun(tstage,ystage);
            end
            yNp1 = yi + F*(hi*B);
            fEvals = 1 + (nstages - 1);
        end
    end
    
    methods(Static, Access=private)
        function [rootOutput, I] = rootFindingFunc(subT, odefun, ti, yi, neq, eventFcn)
            subHi = subT - ti;
            yNp1 = ODE5Integrator.stepOnce(odefun, ti, yi, subHi, neq);
            
            [evtValues,~,~] = eventFcn(subT,yNp1);
            
            rootOutput = evtValues;
            [~,I] = min(abs(rootOutput));
            rootOutput = abs(rootOutput(I));
        end
    end
end