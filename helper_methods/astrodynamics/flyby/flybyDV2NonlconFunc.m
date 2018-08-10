function [c, ceq] = flybyDV2NonlconFunc(x, departBodyInfo, flybyBody1Info, flybyBody2Info, arrivalBodyInfo, gmuXfr)
%flybyDV2NonlconFunc Summary of this function goes here
%   Detailed explanation goes here

[~, ~, Rp1, ~, ~] = flybyDVObjFunc([x(1), x(2), x(3)], departBodyInfo, flybyBody1Info, flybyBody2Info, gmuXfr);
[~, ~, Rp2, ~, ~] = flybyDVObjFunc([x(2), x(3), x(4)], flybyBody1Info, flybyBody2Info, arrivalBodyInfo, gmuXfr);

c = [];
c(end+1) = flybyBody1Info.radius*1.1 - Rp1;
% c(end+1) = Rp1 - 0.8*flybyBody1Info.sma * (flybyBody1Info.gm/gmuXfr)^(2/5);
c(end+1) = flybyBody2Info.radius*1.1 - Rp2;
% c(end+1) = Rp2 - 0.8*flybyBody2Info.sma * (flybyBody2Info.gm/gmuXfr)^(2/5);

ceq = [];

end

