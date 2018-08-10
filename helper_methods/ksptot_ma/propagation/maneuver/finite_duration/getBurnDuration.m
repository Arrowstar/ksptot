function burnDur = getBurnDuration(m0, mdot, Isp, dvMag)
%getBurnDuration Summary of this function goes here
%   Detailed explanation goes here
    
    g0 = getG0();
    dvMag = dvMag*1000; %km/s -> m/s
    frac = 1/exp(dvMag/(g0*Isp));
    burnDur = (m0/mdot)*(1-frac);
end

