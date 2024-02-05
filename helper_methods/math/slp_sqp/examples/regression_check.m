function regression_check( result, correct, casemsg, tol, fgfun )
% Verify that result is correct for sqp/slp_trust regression test
if isempty(result), return, end
if (size(result)~=size(correct))
   if length(result)==length(correct)
      disp('regression_check: reshaping result and answer column vectors')
      result = result(:);
      correct = correct(:);
   else
      error('regression_check:size','Size result and correct answer differ')
   end
end
if nargin<4 || isempty(tol), tol=1e-6; end
if any(abs(result-correct)>tol)
   if nargin>4
      [fc,gc]=fgfun( result );
      [fp,gp]=fgfun( correct );
      disp('Result vs. Previous final objective')
      disp([fc fp])
      disp('Result vs. Previous max constraint')
      disp([max(gc) max(gp)])
      Worse = fc-fp > tol && max(gc) > max(tol,max(gp));
   else
      Worse = true;
   end
   if nargin>2, disp(casemsg), end
   if Worse, warning('Regression failure for sqp/slp_trust'), end
   disp(['Max DV difference = ',num2str(max(abs(result-correct))),...
        ' > tolerance = ',num2str(tol)])
   disp(' ')
   disp('Result vs. Correct Answer for X')
   disp([result(:), correct(:)])
end
end