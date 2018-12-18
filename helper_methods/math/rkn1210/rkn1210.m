function varargout = rkn1210(funfcn, tspan, y0, yp0, options, varargin)
% RKN1210       12th/10th order Runge-Kutta-Nyström integrator
%
% RKN1210() is a 12th/10th order numerical integrator for second-order
% ordinary differential equations of the form
%
%   y'' = f(t, y)                     (1)
%
% with initial conditions
%
%   y (t0) = y0                       (2)
%   y'(t0) = yp0
%
% This second-order ODE is integrated with a Runge-Kutta-Nyström method,
% with 17 function evaluations per step. The RKN-class of integrators is
% especially suited for this purpose, since compared to a classic
% Runge-Kutta integration scheme, the same accuracy can be obtained with
% about half the number of function evaluations.
%
% This RKN12(10) method is a very high-order method, to be used in problems
% with *extremely* stringent error tolerances. As the name implies, the
% error should be less than O(h^13). In verious studies, it has been shown
% that this particular integration technique is overall more efficient for
% ODE's of the form (1) than multi-step or even extrapolation methods
% capable of the same accuracy.
%
% RKN1210()'s interface is very similar to that of MATLAB's ODE-integrator
% suite:
%
% USAGE:
% ----------------
%
%   [t, y, yp] = RKN1210(funfcn, tspan, y0, yp0)
%   [t, y, yp] = RKN1210(funfcn, tspan, y0, yp0, options)
%
%   [t, y, yp, exitflag, output] = RKN1210(...)
%   [t, y, yp, TE, YE, YPE, IE, exitflag, output] = RKN1210(...)
%
%   sol = RKN1210(funfcn, tspan, ...)
%
%
% INPUT ARGUMENTS:
% ----------------
%
%  funfcn  - definition of the second-derivative function f(t, y)
%            (See (1)). It should accept a scalar value [t] and a
%            column vector [y] which has the same number of elements
%            as the initial values [y0] and [dy0] provided.
%
%    tspan - time interval over which to integrate. It can be a
%            two-element vector, in which case it will be interpreted
%            as an interval. In case [tspan] has more than two
%            elements, the integration is carried out to all times in
%            [tspan]. Only the values for those times are then
%            returned in [y] and [yp].
%
%  y0, yp0 - initial values as in (2). Both should contain the same number
%            of elements.
%
%  options - options structure, created with ODESET(). Used options are
%            NormControl, MaxStep, InitialStep, AbsTol, Stats, Event,
%            OutputFcn, OutputSel, and Refine. See the help for ODESET()
%            for more information.
%
% How to use Event and/or Output functions is described in the documentation
% on ODESET(). There is one difference: RKN1210() now also passes the first
% derivative [yp] at each step as an argument:
%
%   status = outputFcn(t, y, yp, flag)
%   [value, isterminal, direction] = event(t, y, yp)
%
% where [t] is scalar, and [y] and [yp] are column vectors, as with f(t,y).
%
%
% OUTPUT ARGUMENTS:
% ----------------
%
% t, y, yp - The approximate solutions for [y] and [y'] at times [t].
%            All are concatenated row-wise, that is
%
%               t  = N-by-1
%               y  = N-by-numel(y0)
%               y' = N-by-numel(y0)
%
%            with N the number of sucessful steps taken during the
%            integration.
%
%  exitflag - A scalar value, indicating the termination conditions
%             of the integration:
%
%             -2: a non-finite function value was encountered during the
%                 integration (INF of NaN); the integration was stopped.
%             -1: the step size [h] fell below  the minimum acceptable
%                 value at some time(s) [t]; results may be inaccurate.
%              0: nothing was done; initial state.
%             +1: sucessful integration, normal exit.
%             +2: integration was stopped by one of the output
%                 functions.
%             +3: One or more events were detected, and their
%                 corresponding [isterminal] condition also evaluated to
%                 [true].
%
% TE,YE,    - These arguments are only returned when one or more event
%  YPE,IE     functions are used. [TE] contains the times at which events
%             were detected. [YE] and [YPE] lists the corresponding values
%             of the solution [y] and the first derivative [yp] at these
%             times. [IE] contains indices to the event-functions with
%             which these events were detected. Use a smaller value for
%             AbsTol (in [options]) to increase the accuracy of these
%             roots when required.
%
%    info   - structure containing additional information about the
%             integration. It has the fields:
%
%             info.stepsize         step size (sucesful steps only) at
%                                     each time [tn]
%             info.estimated_error  estimate of the largest possible
%                                     error at each time [tn]
%             info.rejected         number of rejected steps
%             info.accepted         number of accepted steps
%             info.message          Short message describing the
%                                     termination conditions
%
%             Note that these fields contain the information of ALL
%             steps taken, even for cases where [tspan] contains
%             more than 2 elements.
%
%       sol - a structure that can be passed to deval() in order to evaluate
%             the solution at any point in the interval [tspan]. The structure
%             [sol] always includes these fields:
%
%             sol.x        Steps chosen by the solver.
%             sol.y        Each column sol.y(:,ii) contains the solution of
%                          the function at sol.x(ii).
%             sol.yp       Each column sol.yp(:,ii) contains the solution of
%                          the first derivative at sol.x(ii).
%             sol.solver   Solver name ('rkn1210')
%
%             If you specify the 'Events' option and events are detected,
%             [sol] also includes these fields:
%
%             sol.xe       Points at which events, if any, occurred.
%                          sol.xe(end) contains the exact point of a terminal
%                          event, if any.
%             sol.ye       Solutions for the function corresponding to events
%                          in sol.xe.
%             sol.ype      Solutions for the derivative corresponding to events
%                          in sol.xe.
%             sol.ie       Indices into the vector returned by the function
%                          specified in the Events option. The values indicate
%                          which event the solver detected.
%
% If you find this work useful and want to show your appreciation, please
% consider <a
% href="matlab:web('https://www.paypal.me/RodyO/3.5')">making a donation</a>.
%
% See also ODE45, ODE113, ODE86, RKN86, ODEGBS, ODESET, DEVAL, ODEXTEND.


% Licence information
%{
Copyright (c) 2015, Rody Oldenhuis
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies,
either expressed or implied, of the FreeBSD Project.
%}


% Author
%{
% Name   : Rody P.S. Oldenhuis
% E-mail : oldenhuis@gmail.com
% Licence: 2-clause BSD (See Licence.txt)
%}


% References
%{
Based on the code for ODE86 and RKN86, also available on the MATLAB
FileExchange.

The consruction of RKN12(10) is described in
[1] High-Order Embedded Runge-Kutta-Nystrom Formulae
J. R. DORMAND, M. E. A. EL-MIKKAWY, AND P. J. PRINCE
IMA Journal of Numerical Analysis (1987) 7, 423-430

Coefficients obtained from
[2] http://www.tampa.phys.ucl.ac.uk/rmat/test/rknint.f
These are also available in any format on request to these authors.

[3] CHEAP ERROR ESTIMATION FOR RUNGE–KUTTA METHODS
CH. TSITOURAS AND S. N. PAPAKOSTAS
SIAM J. SCI. COMPUT. Vol. 20, No. 6, pp. 2067–2088
%}


% If you want to cite this work in an academic paper, please use
% the following template:
%{
Rody Oldenhuis, orcid.org/0000-0002-3162-3660. "RKN1210" <version>,
<date you last used it>. MATLAB implementation of an embedded 12/10th order
Runge-Kutta-Nyström integrator for second-order ordinary differential equations.
https://nl.mathworks.com/matlabcentral/fileexchange/25291-rkn1210
%}


% ELEMENTARY EXAMPLE
%{

% (2-body gravitational interaction / circular orbit;
% copy-pastable)

clc

% Equations of motion for a circular orbit in 2D
f1 = @(t,y) -y/sqrt(y'*y)^3;
f2 = @(t,y) [y(3:4)
             -y(1:2)/sqrt(y(1:2).'*y(1:2))^3];

tspan = [0 1e3];
r0    = [1; 0];
v0    = [0; 1];

% RKN1210 with moderate accuracy setting
disp('RKN1210, with AbsTol = 1e-6, RelTol = 1e-3')
options = odeset('AbsTol', 1e-6, 'RelTol', 1e-3);

tic
[t1,y1,~,~, output] = rkn1210(f1, tspan, r0, v0, options);

toc

fprintf(1, 'Maximum absolute error: %g\n',...
        max( (y1(:,1)-cos(t1)).^2 + (y1(:,2)-sin(t1)).^2 ));
fprintf(1, 'Number of function evaluations: %d\n', ...
        output.fevals);

% This is how much ODE113 will have to be tuned to achieve similar accuracy
fprintf('\n\n')
disp('Compare with ODE113 with AbsTol = RelTol = 8e-9:')
options = odeset('RelTol',8e-9, 'AbsTol',8.132e-9);

tic
sol = ode113(f2, tspan, [r0; v0], options);
t2 = sol.x.';
y2 = sol.y';
toc

fprintf(1, 'Maximum absolute error: %g\n',...
        max( (y2(:,1)-cos(t2)).^2 + (y2(:,2)-sin(t2)).^2 ));
fprintf(1, 'Number of function evaluations: %d\n', ...
        sol.stats.nfevals);

%}



% If you find this work useful and want to show your appreciation:
% https://www.paypal.me/RodyO/3.5


    %% Initialize

    % Create structures to pass data around more easily

    if (nargin < 5)
        options = odeset; end

    input = struct('funfcn'  , funfcn,...
                   'tspan'   , tspan,...
                   'y0'      , y0,...
                   'yp0'     , yp0,...
                   'options' , options, ...
                   'varargin', {varargin} );

    % Check user input and parse options
    check_inputs(input);
    input = parse_options(input);


    % In case of Event/output functions, initialize and/or modify a few extra parameters
    opts = input.options;

    if ~isempty(opts.Events)

        % cast into cell-array if only one function is given (easier later on)
        if isa(opts.Events, 'function_handle')
            opts.Events = {opts.Events}; end

        % Init event function values
        input.previous_event_values = NaN(numel(opts.Events),1);

        % Check if all are indeed function handles
        for ii = 1:numel(opts.Events)
            assert(~isempty(opts.Events{ii}) && isa(opts.Events{ii}, 'function_handle'),...
                  [mfilename ':event_not_function_handles'], [...
                  'Unsupported class for event function received; event %d ',...
                  'is of class ''%s''.\n%s only supports function handles.'],...
                  ii, class(opts.Events{ii}), upper(mfilename));
        end

        % Initialize TE (event times), YE (event solutions) YPE (event
        % derivs) and IE (indices to corresponding event function). Check
        % user-provided event functions at the same time
        input.previous_event_values = zeros(numel(opts.Events),1);
        for k = 1:numel(opts.Events)
            try
                input.previous_event_values(k) = opts.Events{k}(...
                    tspan(1),...
                    y0,...
                    yp0);

            catch ME
                ME2 = MException([mfilename ':cannot_evaluate_eventFcn'],...
                                 'Event function #%1d failed to evaluate on initial call.',...
                                 k);
                throw(addCause(ME2,ME));

            end
        end

    end

    if ~isempty(opts.OutputFcn)

        % Cast into cell-array if only one function is given (easier later on)
        if isa(opts.OutputFcn, 'function_handle')
            opts.OutputFcn = {opts.OutputFcn}; end

        % WHICH elements should be passed to the output function?
        opts.OutputSel = odeget(opts, 'OutputSel', 1:numel(y0));
        % adjust the number of points passed to the output functions by this factor
        opts.Refine = odeget(opts, 'Refine', 1);

        % 'init' phase
        for k = 1:numel(opts.OutputFcn)

            % Check if all are indeed function handles
            assert(~isempty(opts.OutputFcn{k}) && isa(opts.OutputFcn{k}, 'function_handle'),...
                   [mfilename ':output_not_function_handles'], [...
                   'Unsupported class for output function received; output ',...
                   'function %d is of class ''%s''.\n%s only supports function ',...
                   'handles.'],...
                    k, class(opts.OutputFcn{k}), upper(mfilename));

            % call each output function with 'init' flag. Also check whether
            % the user-provided output function evaluates
            try
                opts.OutputFcn{k}(...
                    tspan(1),...
                     y0(opts.OutputSel),...
                    yp0(opts.OutputSel),...
                    'init');

            catch ME
                ME2 = MException([mfilename ':OutputFcn_doesnt_evaluate'],...
                                 'Output function #%d failed to evaluate on initial call.',...
                                 k);
                throw(addCause(ME2,ME));

            end
        end
    end

    input.options = opts;


    %% Perform integration

    % Use dense output routines if [tspan] has more than two elements
    % and the user does not intend to work with deval()
    if (numel(tspan) > 2 && nargout ~= 1)
        [varargout{1:nargout}] = rkn1210_dense_output(input);
    else
        [varargout{1:nargout}] = rkn1210_sparse_output(input);
    end

end % RKN1210 integrator


% Check user inputs
function check_inputs(input)

    % Check consistency of user input
    argc = numel(fieldnames(input))-1 + numel(input.varargin);

    assert(argc >= 4 && argc <= 5,...
           '%s requires either 4 or 5 input arguments.',...
           upper(mfilename));
    assert(isa(input.funfcn, 'function_handle'),...
           [mfilename ':funfcn_isnt_a_function'], ...
           'Second derivative f(t,y) must be given as function handle.');
    assert(~isempty(input.tspan) && numel(input.tspan) >= 2,...
           [mfilename ':tspan_empty'],...
           'Time interval [tspan] must contain at least 2 values.');
    assert(all(diff(input.tspan) ~= 0),...
           [mfilename ':tspan_dont_span'],...
           'Values in [tspan] must all span a non-zero interval.');
    assert(all(diff(input.tspan) > 0) || all(diff(input.tspan) < 0), ...
           [mfilename ':tspan_must_increase'],...
           'The entries in tspan must be monotonically increasing or decreasing.');
    assert(numel(input.y0) == numel(input.yp0),...
           [mfilename ':initial_values_disagree'], ...
           'Initial values [y0] and [yp0] must contain the same number of elements.');
    if argc == 5
        assert(isstruct(input.options),...
               [mfilename ':options_not_struct'], ...
               'Options must be given as a structure created with ODESET().');
    end
end


% Parse options
function input = parse_options(input)

    opts = input.options;

    opts.Stats       = odeget(opts, 'Stats', 'off');      % display statistics at the end?
    opts.AbsTol      = odeget(opts, 'AbsTol', 1e-14);     % Absolute tolerance
    opts.RelTol      = odeget(opts, 'RelTol', 1e-7);      % Relative tolerance
    opts.MaxStep     = odeget(opts, 'MaxStep', input.tspan(end) - input.tspan(1)); % defaults to entire interval
    opts.InitialStep = odeget(opts, 'InitialStep');       % default determined later
    opts.Events      = odeget(opts, 'Events', []);        % defaults to no eventfunctions
    opts.OutputFcn   = odeget(opts, 'OutputFcn', []);     % defaults to no output functions
    opts.NormControl = odeget(opts, 'NormControl', 'off');% use norm of solution rather than

    % Some obvious truths
    opts.AbsTol = abs(opts.AbsTol);
    opts.RelTol = abs(opts.RelTol);
    direction = 1 - 2*(input.tspan(end) < input.tspan(1));
    if ~isempty(opts.InitialStep) && direction*opts.InitialStep < 0
        warning([mfilename ':initialstep_wrong_direction'],...
                ['The sign of the initial step disagrees with the integration ',...
                'direction implied by argument tspan; setting the sign of the ',...
                'initial step equal to the implied direction ']);
        opts.InitialStep = direction * abs(opts.InitialStep);
    end
    if direction*opts.MaxStep < 0
        warning([mfilename ':maxstep_wrong_direction'],...
                ['The sign of the maximum step disagrees with the integration ',...
                'direction implied by the argument tspan; setting the sign of the ',...
                'maximum step equal to the implied direction ']);
        opts.MaxStep = sign(opts.InitialStep)* abs(opts.MaxStep);
    end

    input.options = opts;

end


% Efficiently grow arrays
function output = grow_arrays(output)

    % First call - initialize all arrays. Assign about 0.5 MB
    if numel(output.tout) == 1

        % With M the number of elements in y0 and N the (unknown) number
        % of elements to be assigned to each of the output arrays, we need
        % to assign
        %
        %     N (tout)
        %   M*N (yout)
        %   M*N (dyout)
        %     N (info.estimated_error)
        %     N (info.stepsize)
        %   M*N (info.d2ydt2d)
        % _______________________+
        % 3*N + 3*M*N = 3*N*(M+1)
        %
        % If this is to be Y MB, and knowing that the first entries of all
        % arrays have already been initialized, and using 8 bytes per double,
        % we get
        %
        %       8 * 3*(N+1)*(M+1) = Ye6
        % -->                   N = Ye6/24/(M+1) - 1
        %
        M = size(output.yout,2);
        N = max(100, floor(5e5/24/(M+1) - 1));

        % Generate data placeholders
        nans   = NaN(N,1);
        nans_y = NaN(N,M);

    % Subsequent calls -- grow the arrays by constant factor (ensures
    % optimum memory complexity)
    else

        % Growth factor
        K = 1.2;

        % Generate data placeholders
        growth = ceil((K-1)*numel(output.tout));
        nans   = NaN(growth,1);
        nans_y = NaN(growth,size(output.yout,2));

    end

    % Grow the input arrays
    % NOTE: (Rody Oldenhuis) since MATLAB uses lazy copy-on-write, the
    % biggest performance hit (second only to the derivative function)
    % is likely to be here. Don't be fooled; this is a LOT more efficient
    % than growing the arrays once per integration step (as the ODE suite
    % does it)
    output.tout  = [output.tout;  nans];
    output.yout  = [output.yout;  nans_y];
    output.dyout = [output.dyout; nans_y];

    output.info.estimated_error = [output.info.estimated_error; nans  ];
    output.info.stepsize        = [output.info.stepsize;        nans  ];
    output.info.d2ydt2          = [output.info.d2ydt2;          nans_y];

end


% Dense output
% FIXME: use deval (interpolating polynomials rather than recursion)
function varargout = rkn1210_dense_output(input)

    % the output sizes are already known
    nans   = NaN(numel(input.tspan)-1, 1);
    nans_y = NaN(numel(input.tspan)-1, numel( input.y0));

    output.tout  = input.tspan(:);
    output.yout  = [ input.y0(:).'; nans_y];
    output.dyout = [input.yp0(:).'; nans_y];

    output.info.fevals   = 0;   output.info.stepsize        = nans;
    output.info.rejected = 0;   output.info.estimated_error = nans;
    output.info.accepted = 0;

    % call this function as many times as there are times in [tspan]
    for tn = 1:numel(input.tspan)-1

        % new initial values
        tspanI = input.tspan (tn:tn+1);
        y0     = output.yout (tn, :);
        yp0    = output.dyout(tn, :);

        % call the integrator
        if ~isempty(input.options.Events)
            [dummy_, youtI, dyoutI, TEI, YEI, DYEI, IEI, output.exitflag, infoI] = ...
                rkn1210(input.funfcn, tspanI, y0, yp0, input.options); %#ok<ASGLU>
        else
            [dummy_, youtI, dyoutI, output.exitflag, infoI] = ...
                rkn1210(input.funfcn, tspanI, y0, yp0, input.options); %#ok<ASGLU>
        end

        % new initial step is old next-to-last step
        input.options = odeset(input.options, ...
            'InitialStep', infoI.stepsize(max(1,end-1)));

        % Append the solutions
        output.yout (tn+1,:) =  youtI(end, :);
        output.dyout(tn+1,:) = dyoutI(end, :);
        if ~isempty(input.options.Events)
            output.TE (tn+1,:) = TEI;   output.IEI (tn+1,:) =  IEI;
            output.YEI(tn+1,:) = YEI;   output.DYEI(tn+1,:) = DYEI;
        end

        % process Stats
        output.info.fevals    =  output.info.fevals   + infoI.fevals;
        output.info.rejected  =  output.info.rejected + infoI.rejected;
        output.info.accepted  =  output.info.accepted + infoI.accepted;

        output.info.stepsize(tn)        = norm(infoI.stepsize       ,'inf');
        output.info.estimated_error(tn) = norm(infoI.estimated_error,'inf');

        % evaluate any output functions at each [t] in [tspan]
        %{
        % NOTE: (Rody Oldenhuis) ...why is this useful? -> check if this is how
        % ODEXX does it
        if ~isempty(options.OutputFcn)

            % evaluate all functions
            halt = false;
            for fk = 1:numel(options.OutputFcn)
                try
                    halt = halt | options.OutputFcn{fk}(...
                        toutI, ...
                        youtI (options.OutputSel), ...
                        dyoutI(options.OutputSel),...
                        []);

                catch ME
                    ME2 = MException([mfilename ':OutputFcn_failure_integration'],...
                                     'Output function #%1d failed to evaluate during integration.',...
                                     fk);
                    throw(addCause(ME2, ME));
                end
            end

            % halt integration when one of them has requested that
            if halt
                output.exitflag = 2;
                break;
            end
        end
        %}

        % should we quit?
        if ~any(output.exitflag==[-1 0 1])
            break, end
    end


    % we're done.
    output.index = size(output.yout,1);
    [varargout{1:nargout}] = finalize(input, output);

end


% Nominal use case: sparse output
function varargout = rkn1210_sparse_output(input)

    % Load coefficients (and prevent having to load them
    % every time the function is called)
    persistent c A B Bp Bhat Bphat
    if isempty(c)
        [c, A, B,Bp, Bhat,Bphat] = getCoefficients(); end

    % Abbreviations / constants
    pow  = 1/11;              t0        = input.tspan(1);
    t    = t0;                tfinal    = input.tspan(end);
    y    = input.y0(:);       hmin      = 16*eps(t);
    dy   = input.yp0(:);      f         = input.y0(:)*zeros(1,17);
    opts = input.options;     direction = 1 - 2*(tfinal < t0);
    f1   = 0.8;
    f2   = 10;

    % IO variables
    if nargout ~= 0

        % Integration main output
        output.tout  = t0;
        output.yout  = input.y0(:).';
        output.dyout = input.yp0(:).';
        output.index = 1;

        % Algorithm exitstatus
        output.exitflag = 0;

        % Detailed algorithm info
        output.info.stepsize        = [];    output.info.fevals   = 1; % (see below)
        output.info.rejected        = 0;     output.info.accepted = 0;
        output.info.d2ydt2          = [];    output.info.message  = 'Integration not started.';
        output.info.estimated_error = [];

        % In case of event functions, initialize some more variables
        if ~isempty(opts.Events)
            output.IE = [];   output.YE  = [];
            output.TE = [];   output.YPE = [];
        end
    end

    % Test whether user-defined function evaluates
    try
       f(:,1) = input.funfcn(t, y);
    catch ME
       ME2 = MException([mfilename ':incorrect_funfcnoutput'], [...
                        'Could not evaluate derivative; derivative function ',...
                        'should return an array with the same number of ',...
                        'elements as in the initial values (%d).'],...
                        numel(y));
       throw(addCause(ME2,ME));
    end

    % Initialize all variables
    if nargout~=0
        output = grow_arrays(output); end

    % Initial step
    if isempty(opts.InitialStep)
        % default initial step
        h = opts.AbsTol^pow / max(norm([dy.' f(:,1).'], 'inf'), 1e-4);
        h = min(opts.MaxStep,max(h,hmin));
    else
        % user provided initial step
        h = opts.InitialStep;
    end

    % (take care of direction)
    h = direction*abs(h);

    % The main loop
    while (abs(t-tfinal) > 0)

        % Minimum stepsize is a constant relative numerical distance
        % from the current time.
        hmin = direction*16*eps(t);

        % Take care of final step
        if ( direction*(t+h) > direction*tfinal )
            h = direction*norm([hmin t-tfinal],'inf'); end

        % Compute the second-derivative
        % NOTE: 'Vectorized' in ODESET() has no use; we need the UPDATED
        % function values to calculate the NEW ones, i.e., the function
        % evaluations are not independent.
        hc  = h*c;
        h2A = h*h*A;
        for jj = 1:17
            f(:,jj) = input.funfcn( t + hc(jj), ...
                                    y + hc(jj)*dy + f*h2A(:,jj) );
        end

        if nargout~=0
            output.info.fevals = output.info.fevals + 17; end

        % check for inf or NaN
        if any(~isfinite(f(:)))
            output.exitflag = -2;
            % use warning (not error) to preserve output thus far
            warning([mfilename ':nonfinite_values'], [...
                    'INF or NAN value encountered during the integration.\n',...
                    'Terminating integration...']);
            break;
        end % non-finite values

        % Pre-compute solutions
        hf      = h*f;
        hfBhat  = hf*Bhat;     new_y  =  y + h*(dy + hfBhat);
        hfBphat = hf*Bphat;    new_dy = dy +         hfBphat;
        hfB     = hf*B;
        hfBp    = hf*Bp;

        % Compute error estimate for this step
        if strcmpi(opts.NormControl, 'on')

            % Estimate the error using norm of solution (usually more stringent)
            delta1 = norm(h*(hfBhat  - hfB )); % error ~ ||Y - y||
            delta2 = norm(  (hfBphat - hfBp)); % error ~ ||dot{Y} - dot{y}||
            delta  = max(delta1, delta2);       % use worst case error

            % ...and compare agains most stringent demand
            step_tolerance = min( opts.AbsTol, ...
                                  opts.RelTol * max(norm(new_y), norm(new_dy)) );

        else
            % Per-component error estimation
            delta1 = abs(h*(hfBhat  - hfB )); % error ~ |Y - y|
            delta2 = abs(  (hfBphat - hfBp)); % error ~ |dot{Y} - dot{y}|
            delta  = max(delta1, delta2);      % use worst case error

            % ...and compare agains most stringent demand
            step_tolerance = min( opts.AbsTol, ...
                                  opts.RelTol * max(abs(new_y), abs(new_dy)) );

        end

        % Update the solution only if the error is acceptable
        if all(delta <= step_tolerance)

            % update the new solution
            t  = t + h;
            y  = new_y;
            dy = new_dy;

            if nargout ~= 0

                output.index = output.index + 1;

                % if new values won't fit, first grow the arrays
                % NOTE: This construction is WAY better than growing the arrays on
                % EACH iteration; especially for "cheap" integrands, this
                % construction causes a lot less overhead.
                if output.index > size(output.yout,1)
                    output = grow_arrays(output); end

                % insert updated values
                output.tout (output.index,:) = t;
                output.yout (output.index,:) = y.';
                output.dyout(output.index,:) = dy.';

                output.info.d2ydt2  (output.index,:)        = f(:,1).';
                output.info.stepsize(output.index-1)        = h;
                output.info.estimated_error(output.index-1) = max(delta(:));
                output.info.accepted = output.info.accepted + 1;

            end

            % evaluate event-funtions
            if ~isempty(opts.Events)

                % Evaluate all functions
                terminate = false;
                for fk = 1:numel(opts.Events)
                    % Evaluate event function, and check if any have changed sign
                    %
                    % NOTE: although not really necessary (event functions have been
                    % checked upon initialization), use TRY-CATCH block to produce
                    % more useful errors in case something does go wrong.

                    try
                        % evaluate function
                        [value, ...
                         isterminal,...
                         zerodirection] = opts.Events{fk}(t, y, dy);

                        % look for sign change
                        if (input.previous_event_values(fk)*value < 0)

                            % ZERODIRECTION:
                            %  0: detect all zeros (default
                            % +1: detect only INcreasing zeros
                            % -1: detect only DEcreasing zeros
                            if (zerodirection == 0) ||...
                               (sign(value) == sign(zerodirection))

                                % terminate?
                                terminate = terminate || isterminal;

                                % Detect the precise location of the zero
                                % NOTE: try-catch is necessary to prevent things like
                                % discontinuous event-functions from resulting in
                                % unintelligible error messages
                                if nargout ~= 0
                                    try
                                        output = detect_Event(...
                                            input, output, fk, value);

                                    catch ME
                                        ME2 = MException([mfilename ':eventFcn_failure_zero'],...
                                                         'Failed to locate a zero for event function #%1d.',...
                                                         fk);
                                        throw(addCause(ME2,ME));

                                    end
                                end
                            end
                        end

                        % save new value
                        input.previous_event_values(fk) = value;

                    catch ME
                        ME2 = MException([mfilename ':eventFcn_failure_integration'],...
                                         'Event function #%1d failed to evaluate during integration.',...
                                         fk);
                        throw(addCause(ME2,ME));

                    end

                end

                % do we need to terminate?
                if terminate
                    output.exitflag = 3;
                    break;
                end

            end % Event functions

            % evaluate output functions
            if ~isempty(opts.OutputFcn)

                % Evaluate all functions
                halt = false;
                for fk = 1:numel(opts.OutputFcn)
                    % Evaluate kth output function
                    try
                        % TODO: behavior inconsistent with that of ODE suite
                        halt = halt | opts.OutputFcn{fk}(t, ...
                                                         y (opts.OutputSel), ...
                                                         dy(opts.OutputSel), ...
                                                         []);

                    catch ME
                        ME2 = MException([mfilename ':OutputFcn_failure_integration'],...
                                         'Output function #%1d failed to evaluate during integration.',...
                                         fk);
                        throw(addCause(ME2,ME));

                    end
                end

                % Halt integration when requested
                if halt
                    output.exitflag = 2;
                    break;
                end

            end % Output functions

        % rejected step: just increase its counter
        else
            output.info.rejected = output.info.rejected + 1;

        end % accept or reject step

        % Adjust the step size
        if (all(delta <= eps))
            % we made NO error --> p-fold the step
            h = direction * min( abs(opts.MaxStep), 10*abs(h) );
        else
            % [3], equation 3.1+3.2
            %growth = f1 * (step_tolerance ./ delta).^pow;

            % After [3], equation 3.1+3.5 leads to fewer failures
            EST    = f2 * abs(h) * delta;
            growth = f1 * (step_tolerance ./ EST).^pow;

            h_new  = direction * min( abs(opts.MaxStep), ...
                                      max(abs(h).*growth) );


            if h_new~=0
                h = h_new; end
        end

        % Use [Refine]-option when output functions are present
        if ~isempty(opts.OutputFcn)
            h = h/opts.Refine; end

        % Check the new stepsize
        if (abs(h) < abs(hmin))
            output.exitflag = -1;
            % use warning to preserve results thus far
            warning([mfilename ':stepsize_too_small'], ...
                    ['Failure at time t = %6.6e: \n',...
                    'Step size fell below the minimum acceptible value of %6.6d.\n',...
                    'A singularity is likely.'],...
                    t, abs(hmin));
        end

    end % main loop

    % Check, prepare & assign outputs
    if nargout ~= 0
        [varargout{1:nargout}] = finalize(input, output); end

end % rkn1210_sparse_output


% Detect zero passages of event functions
% using false-position method (derivative-free)
function output = detect_Event(input, output,which_event, value)

    % initialize
    y0  = output.yout (output.index-1,:);    side          = 0;
    dy0 = output.dyout(output.index-1,:);    iterations    = 0;
    tt  = output.tout (output.index-1,:);    maxiterations = 1e3;

    fa = input.previous_event_values(which_event);
    ta = tt;

    fb = value;
    tb = output.tout(output.index,:);

    % prune unnessesary options, and set initial step to current step
    opts = odeset(input.options,...
                  'Events'     , [],...
                  'OutputFcn'  , [],...
                  'Stats'      , 'off',...
                  'InitialStep', output.info.stepsize(output.index-1) );

    % Start root finding process
    while (min(abs(fa),abs(fb)) > opts.AbsTol)

        % Regula-falsi step
        iterations = iterations + 1;
        ttp = tt;
        tt  = (fb*ta - fa*tb) / (fb-fa);

        % termination condition
        if (ttp == tt || abs(ttp-tt) < eps)
            break, end

        % Direction might have changed
        Zdirection = sign(tt-ttp);
        opts = odeset(opts, ...
                      'InitialStep', Zdirection * abs(opts.InitialStep),...
                      'MaxStep'    , Zdirection * abs(opts.MaxStep));

        % Evaluating the event-function at this new trial location is
        % somewhat complicated. We need to recursively call this
        % RKN1210-routine to get appropriate values for [y] and [dy] at
        % the new time [tt] into the event function:
        [DUMMY_, Zyout, Zdyout, DUMMY_, Zoutput] = ...
            rkn1210(input.funfcn, [ttp tt], y0, dy0, opts); %#ok<ASGLU>

        % set new initial step to next-to-last step of previous call
        opts = odeset(opts, ...
            'InitialStep', Zoutput.stepsize(max(1,end-1)));

        % save old values for next iteration
        y0  = Zyout (end,:).';
        dy0 = Zdyout(end,:).';

        % NOW evaluate event-function with these values
        fval = input.options.Events{which_event}(tt, y0, dy0);

        % keep track of number of stats
        output.info.fevals = output.info.fevals + Zoutput.fevals;

        % Compute new step
        if (fb*fval>0)
            tb = tt; fb = fval;
            if side == -1
                fa = fa/2; end
            side = -1;

        elseif (fa*fval>0)
            ta = tt; fa = fval;
            if side == +1
                fb = fb/2; end
            side = +1;

        else
            % termination condition
            break;
        end

        assert(iterations <= maxiterations,...
               [mfilename ':rootfinder_exceeded_max_iterations'], ...
               'Root could not be located within %d iterations.',...
               maxiterations);

    end % Regula-falsi loop


    % The zero has been found! insert values into proper arrays
    % TODO: (Rody Oldenhuis) Also grow these
    output.TE  = [output.TE; tt];   output.YPE = [output.YPE; dy0];
    output.YE  = [output.YE; y0];   output.IE  = [output.IE; which_event];

    % The integrand first overshoots the zero; that's how it's
    % detected. We want the zero to be in the final arrays, but we also
    % want them in the correct order. So, move the overshoot one down,
    % and insert the zero in its place:

    output.index = output.index + 1;
    if output.index > size(output.yout,1)
        output = grow_arrays(output); end

    output.yout (output.index  ,:) = output.yout(output.index-1,:);
    output.yout (output.index-1,:) = y0.';

    output.dyout(output.index  ,:) = output.dyout(output.index-1,:);
    output.dyout(output.index-1,:) = dy0.';

    output.tout (output.index  ,:) = output.tout(output.index-1,:);
    output.tout (output.index-1,:) = tt;

    output.info.stepsize(output.index-1) = tt - output.tout(output.index-1);

end % find zeros of event functions


% clean up and finalize
function varargout = finalize(input, output)

    % Cut off any spurious elements
    if nargout ~= 0

        output.tout  = output.tout (1:output.index,:);
        output.yout  = output.yout (1:output.index,:);
        output.dyout = output.dyout(1:output.index,:);

        if isfield(output.info, 'stepsize');
            output.info.stepsize        = output.info.stepsize(1:output.index-1);
            output.info.estimated_error = output.info.estimated_error(1:output.index-1);
        end
    end

    % Abbrev
    opts = input.options;

    % neutral flag means all OK
    if (output.exitflag == 0)
        output.exitflag = 1; end

    % final call to the output functions
    if ~isempty(opts.OutputFcn)
        for fk = 1:numel(opts.OutputFcn)
            try
                opts.OutputFcn{fk}(...
                    output.tout (end,:),...
                    output.yout (end,opts.OutputSel),...
                    output.dyout(end,opts.OutputSel),...
                    'done');

            catch ME
                ME2 = MException([mfilename ':OutputFcn_failure_finalization'],...
                                 'Output function #%1d failed to evaluate during final call.', ...
                                  fk);
                throw(addCause(ME2,ME));

            end
        end
    end

    % add message to output structure
    if nargout ~= 0

        switch output.exitflag
            case +1
                output.info.message = 'Integration completed sucessfully.';
            case +2
                output.info.message = 'Integration terminated by one of the output functions.';
            case +3
                output.info.message = 'Integration terminated by one of the event functions.';
            case -1
                output.info.message = sprintf(['Integration terminated successfully, but ',...
                    'the step size\nfell below the minimum allowable value of %6.6e.\n',...
                    'for one or more steps. Results may be inaccurate.'], hmin);
            case -2
                output.info.message = sprintf(['Integration unsuccessfull; second ',...
                    'derivative function \nreturned a NaN or INF value in the last step.']);
        end

        % handle sol (deval()) case
        if nargout == 1

            % Construct 'sol' structure
            [dummy_, sol.solver] = fileparts(mfilename); %#ok<ASGLU>
            sol.x  = output.tout;
            sol.y  = output.yout;
            sol.yp = output.dyout;

            % TODO: strip non-ODEGET options
            sol.extdata = struct('odefun'  , input.funfcn,...
                                 'options' , opts,...
                                 'varargin', {input.varargin});

            sol.stats = struct('nsteps' , output.info.accepted,...
                               'nfailed', output.info.rejected,...
                               'nfevals', output.info.fevals);

            if ~isempty(opts.Events)
                sol.xe  = output.TE;    sol.ie  = output.IE;
                sol.ye  = output.YE;    sol.ype = output.YPE;
            end

            % output argument
            varargout{1} = sol;

        else
            % handle varargout
            varargout{1} = output.tout;
            varargout{2} = output.yout;
            varargout{3} = output.dyout;

            if ~isempty(opts.Events)
                varargout{4} = output.TE;
                varargout{5} = output.YE;
                varargout{6} = output.YPE;
                varargout{7} = output.IE;
                varargout{8} = output.exitflag;
                varargout{9} = output.info;
            else
                varargout{4} = output.exitflag;
                varargout{5} = output.info;
            end
        end
    end

    % display stats
    if strcmpi(opts.Stats, 'on')
        fprintf(1, '\n\n Number of successful steps     : %6d\n'  , output.info.accepted);
        fprintf(1,     ' Number of rejected steps       : %6d\n'  , output.info.rejected);
        fprintf(1,     ' Number of evaluations of f(t,y): %6d\n\n', output.info.fevals  );
        fprintf(1, '%s\n\n', output.info.message);
    end

end % finalize the integration


% Load the coefficients
function [c, A, B,Bp, Bhat,Bphat] = getCoefficients()

    % c
    c = [0.0e0
         2.0e-2
         4.0e-2
         1.0e-1
         1.33333333333333333333333333333e-1
         1.6e-1
         5.0e-2
         2.0e-1
         2.5e-1
         3.33333333333333333333333333333e-1
         5.0e-1
         5.55555555555555555555555555556e-1
         7.5e-1
         8.57142857142857142857142857143e-1
         9.45216222272014340129957427739e-1
         1.0e0
         1.0e0];

    % matrix A is lower triangular. It's easiest to
    % load the coefficients row-by-row:
    A = zeros(17);
    A(2,1:1) = 2.0e-4;

    A(3,1:2) = [2.66666666666666666666666666667e-4
                5.33333333333333333333333333333e-4];

    A(4,1:3) = [2.91666666666666666666666666667e-3
                -4.16666666666666666666666666667e-3
                6.25e-3];

    A(5,1:4) = [1.64609053497942386831275720165e-3
                0.0e0
                5.48696844993141289437585733882e-3
                1.75582990397805212620027434842e-3];

    A(6,1:5) = [1.9456e-3
                0.0e0
                7.15174603174603174603174603175e-3
                2.91271111111111111111111111111e-3
                7.89942857142857142857142857143e-4];

    A(7,1:6) = [5.6640625e-4
                0.0e0
                8.80973048941798941798941798942e-4
                -4.36921296296296296296296296296e-4
                3.39006696428571428571428571429e-4
                -9.94646990740740740740740740741e-5];

    A(8,1:7) = [3.08333333333333333333333333333e-3
                0.0e0
                0.0e0
                1.77777777777777777777777777778e-3
                2.7e-3
                1.57828282828282828282828282828e-3
                1.08606060606060606060606060606e-2];

    A(9,1:8) = [3.65183937480112971375119150338e-3
                0.0e0
                3.96517171407234306617557289807e-3
                3.19725826293062822350093426091e-3
                8.22146730685543536968701883401e-3
                -1.31309269595723798362013884863e-3
                9.77158696806486781562609494147e-3
                3.75576906923283379487932641079e-3];

    A(10,1:9) = [3.70724106871850081019565530521e-3
                 0.0e0
                 5.08204585455528598076108163479e-3
                 1.17470800217541204473569104943e-3
                 -2.11476299151269914996229766362e-2
                 6.01046369810788081222573525136e-2
                 2.01057347685061881846748708777e-2
                 -2.83507501229335808430366774368e-2
                 1.48795689185819327555905582479e-2];

    A(11,1:10) = [3.51253765607334415311308293052e-2
                  0.0e0
                  -8.61574919513847910340576078545e-3
                  -5.79144805100791652167632252471e-3
                  1.94555482378261584239438810411e0
                  -3.43512386745651359636787167574e0
                  -1.09307011074752217583892572001e-1
                  2.3496383118995166394320161088e0
                  -7.56009408687022978027190729778e-1
                  1.09528972221569264246502018618e-1];

    A(12,1:11) = [2.05277925374824966509720571672e-2
                  0.0e0
                  -7.28644676448017991778247943149e-3
                  -2.11535560796184024069259562549e-3
                  9.27580796872352224256768033235e-1
                  -1.65228248442573667907302673325e0
                  -2.10795630056865698191914366913e-2
                  1.20653643262078715447708832536e0
                  -4.13714477001066141324662463645e-1
                  9.07987398280965375956795739516e-2
                  5.35555260053398504916870658215e-3];

    A(13,1:12) = [-1.43240788755455150458921091632e-1
                  0.0e0
                  1.25287037730918172778464480231e-2
                  6.82601916396982712868112411737e-3
                  -4.79955539557438726550216254291e0
                  5.69862504395194143379169794156e0
                  7.55343036952364522249444028716e-1
                  -1.27554878582810837175400796542e-1
                  -1.96059260511173843289133255423e0
                  9.18560905663526240976234285341e-1
                  -2.38800855052844310534827013402e-1
                  1.59110813572342155138740170963e-1];

    A(14,1:13) = [8.04501920552048948697230778134e-1
                  0.0e0
                  -1.66585270670112451778516268261e-2
                  -2.1415834042629734811731437191e-2
                  1.68272359289624658702009353564e1
                  -1.11728353571760979267882984241e1
                  -3.37715929722632374148856475521e0
                  -1.52433266553608456461817682939e1
                  1.71798357382154165620247684026e1
                  -5.43771923982399464535413738556e0
                  1.38786716183646557551256778839e0
                  -5.92582773265281165347677029181e-1
                  2.96038731712973527961592794552e-2];

    A(15,1:14) = [-9.13296766697358082096250482648e-1
                  0.0e0
                  2.41127257578051783924489946102e-3
                  1.76581226938617419820698839226e-2
                  -1.48516497797203838246128557088e1
                  2.15897086700457560030782161561e0
                  3.99791558311787990115282754337e0
                  2.84341518002322318984542514988e1
                  -2.52593643549415984378843352235e1
                  7.7338785423622373655340014114e0
                  -1.8913028948478674610382580129e0
                  1.00148450702247178036685959248e0
                  4.64119959910905190510518247052e-3
                  1.12187550221489570339750499063e-2];

    A(16,1:15) = [-2.75196297205593938206065227039e-1
                  0.0e0
                  3.66118887791549201342293285553e-2
                  9.7895196882315626246509967162e-3
                  -1.2293062345886210304214726509e1
                  1.42072264539379026942929665966e1
                  1.58664769067895368322481964272e0
                  2.45777353275959454390324346975e0
                  -8.93519369440327190552259086374e0
                  4.37367273161340694839327077512e0
                  -1.83471817654494916304344410264e0
                  1.15920852890614912078083198373e0
                  -1.72902531653839221518003422953e-2
                  1.93259779044607666727649875324e-2
                  5.20444293755499311184926401526e-3];

    A(17,1:16) = [1.30763918474040575879994562983e0
                  0.0e0
                  1.73641091897458418670879991296e-2
                  -1.8544456454265795024362115588e-2
                  1.48115220328677268968478356223e1
                  9.38317630848247090787922177126e0
                  -5.2284261999445422541474024553e0
                  -4.89512805258476508040093482743e1
                  3.82970960343379225625583875836e1
                  -1.05873813369759797091619037505e1
                  2.43323043762262763585119618787e0
                  -1.04534060425754442848652456513e0
                  7.17732095086725945198184857508e-2
                  2.16221097080827826905505320027e-3
                  7.00959575960251423699282781988e-3
                  0.0e0];

    % this facilitates and speeds up implementation
    A = A.';

    % Bhat (high-order b)
    Bhat = [1.21278685171854149768890395495e-2
            0.0e0
            0.0e0
            0.0e0
            0.0e0
            0.0e0
            8.62974625156887444363792274411e-2
            2.52546958118714719432343449316e-1
            -1.97418679932682303358307954886e-1
            2.03186919078972590809261561009e-1
            -2.07758080777149166121933554691e-2
            1.09678048745020136250111237823e-1
            3.80651325264665057344878719105e-2
            1.16340688043242296440927709215e-2
            4.65802970402487868693615238455e-3
            0.0e0
            0.0e0];

    % BprimeHat (high-order b-prime)
    Bphat  = [1.21278685171854149768890395495e-2
             0.0e0
             0.0e0
             0.0e0
             0.0e0
             0.0e0
             9.08394342270407836172412920433e-2
             3.15683697648393399290429311645e-1
             -2.63224906576909737811077273181e-1
             3.04780378618458886213892341513e-1
             -4.15516161554298332243867109382e-2
             2.46775609676295306562750285101e-1
             1.52260530105866022937951487642e-1
             8.14384816302696075086493964505e-2
             8.50257119389081128008018326881e-2
             -9.15518963007796287314100251351e-3
             2.5e-2];

    % B (low-order b)
    B = [1.70087019070069917527544646189e-2
         0.0e0
         0.0e0
         0.0e0
         0.0e0
         0.0e0
         7.22593359308314069488600038463e-2
         3.72026177326753045388210502067e-1
         -4.01821145009303521439340233863e-1
         3.35455068301351666696584034896e-1
         -1.31306501075331808430281840783e-1
         1.89431906616048652722659836455e-1
         2.68408020400290479053691655806e-2
         1.63056656059179238935180933102e-2
         3.79998835669659456166597387323e-3
         0.0e0
         0.0e0];

    % Bprime (low-order bprime)
    Bp = [1.70087019070069917527544646189e-2
          0.0e0
          0.0e0
          0.0e0
          0.0e0
          0.0e0
          7.60624588745593757356421093119e-2
          4.65032721658441306735263127583e-1
          -5.35761526679071361919120311817e-1
          5.03182602452027500044876052344e-1
          -2.62613002150663616860563681567e-1
          4.26221789886109468625984632024e-1
          1.07363208160116191621476662322e-1
          1.14139659241425467254626653171e-1
          6.93633866500486770090602920091e-2
          2.0e-2
          0.0e0];
end


