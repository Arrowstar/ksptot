function [f,g] = fBarnes( x )
% Function evaluation of Barne's 2-DV, 3-constraint problem from
% 
%  Victor M. Perez, John E. Renaud, and Layne T. Watson
%  Adaptive Experimental Design for Construction of Response Surface Approximation
%  AIAA JOURNAL Vol. 40, No. 12, December 2002
%
%--Input
%
%  x....... Design variable vector
%
%--Output
%
%  f....... Objective function value f(x)=weight
%  g....... Constraint function value g(x)=tip deflection constraint<=0
%
%--Local variables
%
% a....... Coefficents
% y....... State varariables

% a = [75.196
%      -3.8112
%       0.12694
%      -2.0567e-3
%       1.0345e-5
%      -6.8306
%       0.030234
%      -1.28134e-3
%       3.5256e-5 
%      -2.266e-7
%       0.25645
%      -3.4604e-3
%       1.3514e-5
%     -28.106
%      -5.2375e-6
%      -6.3e-8
%       7.0e-10
%       3.4054e-4
%      -1.6638e-6
%      -2.8673
%       0.0005];

a = [ 75.196,   -3.8112,    0.12694,    -2.0567e-3,  1.0345e-5, ...
                -6.8306,   0.030234, -1.28134e-3,  3.5256e-5, -2.266e-7, ...
                 0.25645, -3.4604e-3, 1.3514e-5, -28.106,     -5.2375e-6, ...
                -6.3e-8,   7.0e-10,   3.4054e-4,  -1.6638e-6, -2.8673, ...
                 0.0005];

y = zeros(5,1);
y(1) = x(1)*x(2);
y(2) = x(1)*y(1);
y(3) = x(2)^2;
y(4) = x(1)^2;
y(5) = x(2)/50;

% Objective function, f(x; a)
%
% Note: a(4)*x1^3 missing from Eq. (22a) in Perez etal (2002)
%
% f = a*[1, x(1), x(1)*y(4), x(1)^3, y(4)^2, x(2), y(1), x(1)*y(1), ...
%          y(1)*y(4), y(2)*y(4), y(3), x(2)*y(3), y(3)^2, ...
%          1/(x(2)+1), y(3)*y(4), x(2)*y(1)*y(4), y(1)*y(3)*y(4), ...
%          x(1)*y(3), y(1)*y(3), exp(a(21)*y(1)), 0]'
%
% Transcribe from DAKOTA barnes.cpp
a0 = a(1);
a  = a(2:end); % shift to zero-based index from C++
x1 = x(1);
x2 = x(2);
x1x2 = x1*x2;
x2_sq = x2*x2;
x1_sq = x1*x1;
f = ( a0 + a(1)*x1 + a(2)*x1_sq + a(3)*x1_sq*x1 + a(4)*x1_sq*x1_sq ...
      + a(5)*x2 + a(6)*x1x2 + a(7)*x1*x1x2 + a(8)*x1x2*x1_sq ...
      + a(9)*x2*x1_sq*x1_sq + a(10)*x2_sq + a(11)*x2*x2_sq + a(12)*x2_sq*x2_sq ...
      + a(13)/(x2+1.) + a(14)*x2_sq*x1_sq + a(15)*x1*x1_sq*x2_sq ...
      + a(16)*x1x2*x2_sq*x1_sq + a(17)*x1*x2_sq + a(18)*x1x2*x2_sq ...
      + a(19)*exp(a(20)*x1x2) );
      
% Inequality constraints, g(x,y(x)) <= 0
g = [1 - y(1)/700
     y(4)/25^2 - x(2)/5
     (x(1)/500 - 0.11) - (y(5) - 1)^2];

end