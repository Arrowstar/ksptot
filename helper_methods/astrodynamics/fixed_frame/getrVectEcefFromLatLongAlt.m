function rVectECEF = getrVectEcefFromLatLongAlt(lat, long, alt, bodyInfo)
    r = bodyInfo.radius + alt;
    
    x = r.*cos(lat).*cos(long);
    y = r.*cos(lat).*sin(long);
    z = r.*sin(lat);
    
    rVectECEF = [x(:)';y(:)';z(:)'];
end