function pressure = getPressureAtAltitude(bodyInfo, altitude)
    if(altitude > bodyInfo.atmohgt)
        pressure = 0;
    elseif(altitude < 0)
        pressure = bodyInfo.atmopresscurve(0);
    else
        pressure = bodyInfo.atmopresscurve(altitude);
    end
end