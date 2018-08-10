function pressure = getPressureAtAltitude(bodyInfo, altitude)
    pressure = bodyInfo.atmopresscurve(altitude);
end