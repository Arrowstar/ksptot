function [gradf,gradg] = gHaftka4p2p1( x )
% Haftka Example 4.2.1 objective gradient evaluation
gradf = [24*x(1) - 12*x(2) + 2;
          8*x(2) - 12*x(1)];
gradg = [0; 0];
end