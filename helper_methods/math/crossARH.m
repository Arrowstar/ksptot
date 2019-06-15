function [w] = crossARH(u,v)
%crossARH Summary of this function goes here
%   Detailed explanation goes here
%     w = zeros(3,1);
    w = [u(2)*v(3) - u(3)*v(2); ...
         u(3)*v(1) - u(1)*v(3); ...
         u(1)*v(2) - u(2)*v(1)];
end