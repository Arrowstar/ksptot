function rVectECEF = getrVectEcefFromLatLongAlt_alg(lat, long, alt, radius)
    r = radius + alt;
    
    x = r.*cos(lat).*cos(long);
    y = r.*cos(lat).*sin(long);
    z = r.*sin(lat);
    
    rVectECEF = [x(:)';y(:)';z(:)'];
end