function Root = SecantMethod(fh,Guess1,Guess2,varargin)
    %   This function uses the secant method to find the root of a
    %   nonlinear function by computing the slope between two initial guesses.
    %   The two guesses do not need to bound the solution
    %
    % Required input arguments:
    %
    %      fh:      Function handle, either a scripted function or an anonymous
    %               function. An example of an anonymous function is given here
    %
    %                           fh = @(x) 1 - cos(x)
    %
    %   Guess1:        The lower bound in which to look for the root
    %
    %   Guess2:        The upper bound in which to look for the root
    %
    %  Optional input arguments:
    %
    %  tolerance:   The accuracy that the solution must have, shown as the
    %               difference of the calculated midpoint from zero
    %
    G1 = min([Guess1 Guess2]);
    G2 = max([Guess1 Guess2]);
    x1 = fh(G1);
    x2 = fh(G2);
    if isempty(varargin)
        tol = 1e5*eps;
    else
        tol = varargin{1};
    end
    if isinf(x1)||isinf(x2)||isnan(x1)||isnan(x2)
        disp('Try using different guesses, the current values yield inf or nan')
        Root = nan;
        return
    end
    err = 1;
    while abs(err)>tol
        
        slope = (x2-x1)/(G2-G1);
        if isinf(slope)||slope==0
            
            disp('Failed to converge. Either a horizontal or vertical line')
            Root = nan;
            return
        end
        
        tempvar = abs(slope);
        % This slope adjustment lows convergence, but helps block divergence
        % in a lot of cases. The next three lines can be commented out if the
        % function is well behaved.
        if tempvar<0.3
            slope = abs(log10(tempvar))*sign(slope);
        end
        Gnew = G2-(x2/slope);
        err = G2-Gnew;
        
        G1 = G2;    x1 = x2;
        G2 = Gnew;  x2 = fh(G2);
        
    end
    Root = Gnew;
end
