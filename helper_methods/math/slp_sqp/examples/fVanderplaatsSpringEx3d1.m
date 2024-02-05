function [PE,g] = fVanderplaatsSpringEx3d1( X )
% Potential Energy of two-spring example from
% Vanderplaats textbook Example 3-1
K = [8 1];   % spring constants
L = [10 10]; % spring lengths
P = [5 5];   % External point loads
s = 2*(1:2)-3; % signum function for these 2 springs
dL = sqrt( X(1)^2 + (L + s*X(2)).^2 ) - L; % Length change
PE = 1/2*K*(dL.').^2 - P*X.';
g  = [];