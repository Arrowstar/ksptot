function f = rosenbrocksfcn(x)
% Takes row inputs. If input is not row, will attempt to correct it.
% Syntax:
% y = rosenbrocksfcn(x)
% options = rosenbrocksfcn('init')

if strcmp(x,'init')
    f.PopInitRange = [-2, -2; 2, 2] ;
    f.KnownMin = [1,1] ;
else
    x = reshape(x,1,[]) ;
    if size(x,2) >= 2
%         x1 = x(1:end-1) ; x2 = x(end) ;
        f = 0 ;
        for i = 1:size(x,2)-1
            f = f + (1-x(i))^2 + 100*(x(i+1) - x(i)^2)^2 ;
        end
    else
        error('Rosenbrock''s function requires at least two inputs')
    end
end