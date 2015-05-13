function CorrectedAngle = AngleZero2Pi(Angle)
% Accepts a radian measure angle and returns that angle between 0 and 2*pi.
% Angle is a scalar input, measured in radians.

CorrectedAngle = abs(mod(real(Angle),2*pi));

% if(any(Angle<0))
%     while(Angle<0)
%         Angle=Angle+2*pi;
%     end
%     CorrectedAngle=Angle;
% elseif(Angle>=2*pi)
%     while(Angle>=2*pi)
%         Angle=Angle-2*pi;
%     end
%     CorrectedAngle=Angle;
% else
%     CorrectedAngle=Angle;
% end