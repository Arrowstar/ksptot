function Root = MuellerMethod(fh,Guess1,Guess2,Guess3,varargin)
    %   This function uses Mueller's method to find the root of a function
    %   by using three guesses to compute the root, and can find complex roots
    %   as well. Though it requires three guesses, it converges very rapidly
    %   for high order polynomials (I tested ninth order) with roots
    %   of multiplicity>1, and wildly nonlinear functions like the following.
    %   This particular nonlinear function converged in just 5 iterations with
    %   initial guesses (0.4, 0.5, 1.6). Fzero will error in this particular
    %   case, and the true x solutions are x = (1.380555, 5.6916, and 6.6386)
    %
    %           fh = @(x) 4*x*cos(x)-exp(sqrt(x))*log(x);
    %
    %   The guesses do not need to bound the solution
    %
    % Required input arguments:
    %
    %      fh:      Function handle, either a scripted function or an anonymous
    %               function. An example of an anonymous function is given here
    %
    %                           fh = @(x) 1 - cos(x)
    %
    %   Guess1, Guess2, Guess3: "Reasonable" root values guesses
    %
    %  Optional input arguments:
    %
    %  tolerance:   The accuracy that the solution must have, shown as the
    %               difference of the calculated midpoint from zero
    %
    vec = sort([Guess1 Guess2 Guess3]);
    G1 = vec(1);    G2 = vec(2);    G3 = vec(3);
    x1 = fh(G1);    x2 = fh(G2);    x3 = fh(G3);
    if isempty(varargin)
        tol = 1e5*eps;
    else
        tol = varargin{1};
    end
    if any(isinf([G1 G2 G3 x1 x2 x3]))||any(isnan([G1 G2 G3 x1 x2 x3]))
        disp('Try using different guesses, the current values yield inf or nan')
        Root = nan;
        return
    end
    err = 1;
    while abs(err)>tol
        L = (G3-G2)/(G2-G1);
        D = (G3-G1)/(G2-G1);
        G = (L.^2)*x1 - (D.^2)*x2 + (L + D)*x3;
        C = L*abs(L*x1 - D*x2 + x3);
        Numerator = -2*D*x3;
        Temp = sqrt(G^2 - 4*D*C*x3);
        [~,l] = min(abs([Numerator/(G-Temp) Numerator/(G+Temp)]));
        if l == 2
            lambda = Numerator/(G+Temp);
        else
            lambda = Numerator/(G-Temp);
        end
        Gnew = G3 + lambda*(G3-G2);
        err = G3-Gnew;
        
        G1 = G2;    x1 = x2;
        G2 = G3;    x2 = x3;
        G3 = Gnew;  x3 = fh(Gnew);
        if any(isnan([G1 G2 G3 x1 x2 x3]))
            disp('Convergence failed with these Guesses')
            Root = nan;
            return
        end
    end
    Root = Gnew;
end
