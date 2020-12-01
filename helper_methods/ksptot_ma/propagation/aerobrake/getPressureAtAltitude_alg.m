function pressure = getPressureAtAltitude_alg(altitude, atmohgt, doNotUseAtmoPressCurveGI, atmopresscurve)
    pressure = zeros(size(altitude));
    
    if(not(doNotUseAtmoPressCurveGI))
        bool1 = altitude > atmohgt;
        bool2 = altitude < 0;
        bool3 = altitude >= 0 & altitude <= atmohgt;

        pressure(bool3) = interp1q(atmopresscurve{1}, atmopresscurve{2}, altitude(bool3));

        if(any(bool2))
            pressValue = interp1q(atmopresscurve{1}, atmopresscurve{2}, 0);
            pressure(bool2) = pressValue;
        end

        if(any(bool1))
            pressure(bool1) = 0;
        end
    end
end 