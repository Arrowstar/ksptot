function m1 = revRocketEqn(m0, Isp, dv) 
    g0 = 9.80665/1000; %km/s/s
    
    m1 = m0 * exp(-dv/(g0*Isp));
end