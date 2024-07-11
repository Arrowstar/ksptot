function [angle] = dang(a,b)
%dang Summary of this function goes here
%   Detailed explanation goes here
    angle = atan2(vecnorm(cross(a,b)),dot(a,b));
end