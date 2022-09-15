function [az, el, mag] = getAzElMagFromNTW(ntwVector)
    p = ntwVector(1);
    n = ntwVector(2);
    r = ntwVector(3);
    
    [az,el,mag] = cart2sph(p, r, n);
    az = AngleZero2Pi(az);
end