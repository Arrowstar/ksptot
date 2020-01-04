function pressure = getPressureAtAltitude(bodyInfo, altitude)
    if((bodyInfo.atmohgt > 0 && isempty(bodyInfo.atmopresscurve)) || ...
        altitude > bodyInfo.atmohgt)
        pressure = 0;
    else
        if(altitude < 0)
            pressure = bodyInfo.atmopresscurve(0);
        else
            pressure = bodyInfo.atmopresscurve(altitude);
        end
    end
end