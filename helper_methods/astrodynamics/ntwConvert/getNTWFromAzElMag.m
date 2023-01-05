function [ntwVector] = getNTWFromAzElMag(az, el, mag)
    [p,r,n] = sph2cart(az,el,mag);
    
    ntwVector = [p, n, r];
end