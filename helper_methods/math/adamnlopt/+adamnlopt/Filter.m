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
