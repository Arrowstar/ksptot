function pressure = getPressureAtAltitude(bodyInfo, altitude)
    persistent cache;
    if(isempty(cache))
        cache.bodyInfo = KSPTOT_BodyInfo.empty(0,1);
        cache.altitude = [];
        cache.pressure = [];
        cache.maxSize = 10;
        cache.ptr = 1;
    end

    for i=1:length(cache.bodyInfo)
        if(cache.bodyInfo(i) == bodyInfo && cache.altitude(i) == altitude)
            pressure = cache.pressure(i);
            return;
        end
    end

    if(altitude > bodyInfo.atmohgt || (bodyInfo.doNotUseAtmoPressCurveGI))
        pressure = 0;
    else
        if(altitude < 0)
            pressure = bodyInfo.atmopresscurve(0);
        else
            pressure = bodyInfo.atmopresscurve(altitude);
        end
    end

    cache.bodyInfo(cache.ptr,1) = bodyInfo;
    cache.altitude(cache.ptr,1) = altitude;
    cache.pressure(cache.ptr,1) = pressure;
    cache.ptr = cache.ptr + 1;
    if(cache.ptr > cache.maxSize)
        cache.ptr = 1;
    end
end