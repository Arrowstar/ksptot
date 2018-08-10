function [w] = crossARH(u,v)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
    w = zeros(3,1);
    w(1) = u(2)*v(3) - u(3)*v(2);
    w(2) = u(3)*v(1) - u(1)*v(3);
    w(3) = u(1)*v(2) - u(2)*v(1);
end

