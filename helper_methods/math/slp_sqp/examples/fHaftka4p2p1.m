function [f,g] = fHaftka4p2p1( x )
% Haftka Example 4.2.1 objective evaluation
f = 12*x(1)^2 + 4*x(2)^2 - 12*x(1)*x(2) + 2*x(1); % Eq.(4.2.18)
g = -1;
end