function graderr(finite_diff_deriv, analytic_deriv, gradfcn)
%GRADERR Checks gradient discrepancy in optimization routines. 
%
% This is a helper function.

%   Copyright 1990-2004 The MathWorks, Inc. 
%   $Revision: 1.1.4.1 $  $Date: 2004/03/26 13:27:17 $

try
    if isa(gradfcn,'function_handle')
      gradfcnstr = func2str(gradfcn);
    else
      gradfcnstr = char(gradfcn);
    end
catch
    gradfcnstr = '';
end

finite_diff_deriv = full(finite_diff_deriv); 
analytic_deriv = full(analytic_deriv);
err=max(max(abs(analytic_deriv-finite_diff_deriv)));
disp(sprintf('Maximum discrepancy between derivatives  = %g',err));
if (err > 1e-6*norm(analytic_deriv) + 1e-5) 
    disp('Warning: Derivatives do not match within tolerance')
    disp('Derivative from finite difference calculation:')
    disp(finite_diff_deriv)
    if ~isempty(gradfcnstr)
        disp(['User-supplied derivative, ', gradfcnstr ': '])
    else 
        disp(['User-supplied derivative: '])
    end
    disp(analytic_deriv)
    disp('Difference:')
    disp(analytic_deriv - finite_diff_deriv)
    disp('Strike any key to continue or Ctrl-C to abort')
    pause 
end
end
