classdef(Abstract) AbstractFixedStepIntegrator < AbstractIntegrator
    %AbstractFixedStepIntegrator Fixed-step explicit Runge-Kutta driver.
    %
    %   Concrete subclasses supply their Butcher tableau through the abstract
    %   static getButcherTableauData() and pass it to the static integrate()
    %   below, so this class never has to know which scheme it is stepping.
    %   The tableau argument is a struct with fields A (nstages-1 x nstages-1,
    %   already transposed so that column j holds the weights for stage j+1),
    %   B (nstages x 1) and C (nstages-1 x 1); see ODE5Integrator for the
    %   canonical example.

    methods(Static)
        function [t,y, te,ye,ie] = integrate(odefun, tspan, y0, options, tableau)
            [h,y0,~] = AbstractFixedStepIntegrator.checkInputs(odefun, tspan, y0);
            AbstractFixedStepIntegrator.checkTableau(tableau);

            if(all(h>0))
                propDirPos = true;
            elseif(all(h<0))
                propDirPos = false;
            else
                error('Prop direction might be consistently forward or backwards.');
            end

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
                [prevEvtValues,~,~] = eventFcn(t(1),Y(:,1)); %#ok<RHSFN>
            else
                prevEvtValues = [];
            end

            evtTerminate = false;
            outputTerminate = false;

            i = 2;
            while(keepLooping(propDirPos, i, tspan))
                ti = tspan(i-1);
                if(breakLoop(propDirPos, ti, tspan(end)))
                    break;
                end

                hi = h(i-1);
                yi = Y(:,i-1);

                t(i) = tspan(i);
                Y(:,i) = AbstractFixedStepIntegrator.stepOnce(odefun, ti, yi, hi, neq, tableau);

                if(hasEvents)
                    [evtValues,evtIsTerminal,evtDirection] = eventFcn(t(i),Y(:,i)); %#ok<RHSFN>

                    signChangesBool = (prevEvtValues .* evtValues < 0);
                    evtValZeroBool = evtValues == 0;

                    rootDetect = signChangesBool | evtValZeroBool;
                    if(any(rootDetect))
                        rootFcnFzero = @(subHi) AbstractFixedStepIntegrator.rootFindingFunc(subHi, odefun, ti, yi, neq, eventFcn, true, tableau);

                        if(all(rootDetect == evtValZeroBool)) %we nailed it on the money
                            tSubI = t(i);
                            exitflag = 1;

                        else %use root finding to actually find the event root
                            m = (evtValues - prevEvtValues) / (t(i) - t(i-1));
                            b = (evtValues - t(i) .* m);
                            t0 = -b./m;

                            t0(rootDetect == 0) = NaN;
                            [minT0, ~] = min(t0);

                            tSubI = SecantMethod(rootFcnFzero, t(i-1), minT0, 1e-6);

                            if(isnan(tSubI))
                                exitflag = -1;
                            else
                                exitflag = 1;
                            end

                            if(exitflag ~= 1 || tSubI < t(i-1) || tSubI > t(i))
                                rootFcnFminBnd = @(subHi) AbstractFixedStepIntegrator.rootFindingFunc(subHi, odefun, ti, yi, neq, eventFcn, false, tableau);
                                [tSubI,~,exitflag,~] = fminbnd(rootFcnFminBnd, t(i-1), t(i), optimset('TolX',1E-5));
                            end
                        end

                        if(exitflag == 1)
                            diffForDeriv = sign(evtValues - prevEvtValues);

                            [~, evtInd] = rootFcnFzero(tSubI);
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
                                Y(:,i) = AbstractFixedStepIntegrator.stepOnce(odefun, ti, yi, hi, neq, tableau);

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

        function tableau = makeTableau(A, B, C)
            %makeTableau Packs Butcher tableau matrices into the struct form
            %integrate() expects.
            tableau = struct('A', A, 'B', B(:), 'C', C(:));
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

            y0 = y0(:);   % Make a column vector.
            try
                f0 = odefun(tspan(1),y0);
            catch ME
                msg = ['Unable to evaluate the ODEFUN at t0,y0: ',ME.message];
                error(msg);
            end

            if ~isequal(size(y0),size(f0))
                error('Inconsistent sizes of Y0 and f(t0,y0).');
            end
        end

        function checkTableau(tableau)
            if(not(all(isfield(tableau, {'A','B','C'}))))
                error('Butcher tableau struct must have fields A, B, and C.');
            end

            nstages = numel(tableau.B);
            if(nstages < 1 || ...
               not(isequal(size(tableau.A), [nstages-1, nstages-1])) || ...
               numel(tableau.C) ~= nstages-1)
                error('Inconsistent Butcher tableau: with %u stages A must be %ux%u and C must have %u entries.', ...
                      nstages, nstages-1, nstages-1, nstages-1);
            end
        end

        function [yNp1, fEvals] = stepOnce(odefun, ti, yi, hi, neq, tableau)
            A = tableau.A;
            B = tableau.B;
            C = tableau.C;

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
        function [rootOutput, I] = rootFindingFunc(subT, odefun, ti, yi, neq, eventFcn, forRootFinder, tableau)
            subHi = subT - ti;
            yNp1 = AbstractFixedStepIntegrator.stepOnce(odefun, ti, yi, subHi, neq, tableau);

            [evtValues,~,~] = eventFcn(subT,yNp1);

            rootOutput = evtValues;
            [~,I] = min(abs(rootOutput));

            if(forRootFinder)
                rootOutput = rootOutput(I); %for fzero and the like
            else
                rootOutput = abs(rootOutput(I)); %for an optimizer like fminbnd
            end
        end
    end
end

function tf = keepLooping(propDirPos, i, tspan)
    ti = tspan(i-1);
    if(propDirPos)
        tf = ti < tspan(end);
    else
        tf = ti > tspan(end);
    end
end

function tf = breakLoop(propDirPos, ti, tspanEnd)
    if(propDirPos)
        tf = ti >= tspanEnd;
    else
        tf = ti <= tspanEnd;
    end
end
