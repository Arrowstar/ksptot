function [angle] = dang(a,b)
%dang Summary of this function goes here
%   Detailed explanation goes here
    angle = atan2(vecNormARH(cross(a,b)),dot(a,b));
end