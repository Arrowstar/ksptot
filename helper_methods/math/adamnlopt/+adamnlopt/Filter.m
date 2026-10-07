classdef Filter < handle
%FILTER  Two-dimensional (theta, phi) filter for globalization.
%   A filter stores a set of (constraint-violation, objective) pairs and
%   rejects trial points that are dominated by any stored pair, following the
%   Fletcher-Leyffer / Waechter-Biegler acceptance rule. A trial (theta, phi)
%   is acceptable when, for every stored entry (theta_j, phi_j),
%
%       theta <= (1 - gammaTheta) * theta_j   OR   phi <= phi_j - gammaPhi * theta_j
%
%   i.e. it improves feasibility or objective relative to each entry by a small
%   margin. Trials with theta >= thetaMax are always rejected. AUGMENT adds a
%   (margin-shifted) pair and discards any entries it dominates, keeping the
%   filter a minimal Pareto-style frontier.
%
%   Properties:
%     gammaTheta - feasibility acceptance margin.
%     gammaPhi   - objective acceptance margin.
%     thetaMax   - maximum constraint violation; trials with theta >= thetaMax
%                  are always rejected.
%     entries    - N-by-2 matrix of stored [theta, phi] rows.
%
%   Methods:
%     Filter       - construct a filter with acceptance margins and cap.
%     reset        - discard all stored entries.
%     isAcceptable - test whether a trial (theta, phi) is acceptable.
%     augment      - add a margin-shifted pair and drop dominated entries.
%
%   See also GLOBALIZE_FILTERACCEPT, GLOBALIZE_FILTERLINESEARCH,
%   GLOBALIZE_CONSTRAINTVIOLATION.

    properties
        gammaTheta = 1e-5
        gammaPhi   = 1e-5
        thetaMax   = inf
        % Switching threshold theta_min = 1e-4*max(1, theta(x0)) (Waechter-
        % Biegler 2006, section 2.4), fixed for the solve.  Inf means "derive it
        % from the current theta" for callers that never set it (legacy).
        thetaMin   = inf
        % IPOPT-style filter reset (A4): consecutive iterations whose first
        % trial a stored entry blocked, and how many resets have been spent.
        nBlocked   = 0
        nResets    = 0
        entries    = zeros(0, 2)   % rows [theta, phi]
    end

    methods
        function obj = Filter(gammaTheta, gammaPhi, thetaMax)
        %FILTER  Construct a two-dimensional globalization filter.
        %   obj = Filter(gammaTheta, gammaPhi, thetaMax) creates an empty filter
        %   with the given acceptance margins and violation cap. Any argument that
        %   is omitted or empty keeps its default (gammaTheta = gammaPhi = 1e-5,
        %   thetaMax = inf).
        %
        %   Inputs:
        %     gammaTheta - (optional) feasibility acceptance margin.
        %     gammaPhi   - (optional) objective acceptance margin.
        %     thetaMax   - (optional) maximum constraint violation; trials with
        %                  theta >= thetaMax are always rejected.
        %
        %   Outputs:
        %     obj - the constructed Filter handle object.
            if nargin >= 1 && ~isempty(gammaTheta), obj.gammaTheta = gammaTheta; end
            if nargin >= 2 && ~isempty(gammaPhi),   obj.gammaPhi   = gammaPhi;   end
            if nargin >= 3 && ~isempty(thetaMax),   obj.thetaMax   = thetaMax;   end
        end

        function reset(obj)
        %RESET  Discard all stored filter entries.
        %   reset(obj) empties the filter so that every trial is accepted again.
        %
        %   Inputs:
        %     obj - the Filter handle object.
        %
        %   Outputs:
        %     (none) obj is modified in place.
            obj.entries = zeros(0, 2);
            obj.nBlocked = 0;
        end

        function didReset = noteFirstTrial(obj, blocked, trigger, maxResets)
        %NOTEFIRSTTRIAL  Count first-trial blocks; clear stale entries when stuck (A4).
        %   After TRIGGER consecutive iterations whose full step a stored entry
        %   rejected, the entries are cleared (thetaMax and thetaMin are kept),
        %   at most MAXRESETS times per solve.  Entries recorded at earlier
        %   barrier parameters or before a restoration can otherwise block every
        %   full step and force short steps for many iterations.
            didReset = false;
            if blocked
                obj.nBlocked = obj.nBlocked + 1;
            else
                obj.nBlocked = 0;
            end
            if obj.nBlocked >= trigger && obj.nResets < maxResets && ~isempty(obj.entries)
                obj.entries = zeros(0, 2);
                obj.nBlocked = 0;
                obj.nResets = obj.nResets + 1;
                didReset = true;
            end
        end

        function tf = isAcceptable(obj, theta, phi)
        %ISACCEPTABLE  Test whether a trial (theta, phi) is filter-acceptable.
        %   tf = isAcceptable(obj, theta, phi) returns false when theta reaches
        %   thetaMax, and otherwise delegates to globalize_filterAccept to check
        %   the trial against every stored entry using the margins gammaTheta and
        %   gammaPhi.
        %
        %   Inputs:
        %     obj   - the Filter handle object.
        %     theta - scalar constraint violation of the trial point.
        %     phi   - scalar objective (or barrier objective) of the trial point.
        %
        %   Outputs:
        %     tf - logical; true if the trial is acceptable to the filter.
            import adamnlopt.*
            if theta >= obj.thetaMax
                tf = false;  return;
            end
            tf = globalize_filterAccept(obj.entries, theta, phi, ...
                                        obj.gammaTheta, obj.gammaPhi);
        end

        function augment(obj, theta, phi)
        %AUGMENT  Add a margin-shifted pair and drop dominated entries.
        %   augment(obj, theta, phi) inserts the corner
        %   [(1 - gammaTheta)*theta, phi - gammaPhi*theta] and removes any stored
        %   entry it dominates, keeping the filter a minimal Pareto-style frontier.
        %
        %   Inputs:
        %     obj   - the Filter handle object.
        %     theta - scalar constraint violation to record.
        %     phi   - scalar objective to record.
        %
        %   Outputs:
        %     (none) obj is modified in place.
            % Add the margin-shifted corner and drop entries it dominates.
            newTheta = (1 - obj.gammaTheta) * theta;
            newPhi   = phi - obj.gammaPhi * theta;
            keep = ~(obj.entries(:,1) >= newTheta & obj.entries(:,2) >= newPhi);
            obj.entries = [obj.entries(keep, :); newTheta, newPhi];
        end
    end
end
