function celBodyData = ksptotTestBodyData()
% ksptotTestBodyData Loads (and caches) the stock KSP celestial body data.
%
% Reading and processing bodies.ini is comparatively expensive, so the
% result is cached in a persistent variable for the life of the MATLAB
% session.  Tests must therefore treat the returned data as read-only.

    persistent cachedBodyData
    if(isempty(cachedBodyData))
        iniPath = fullfile(ksptotTestRoot(), 'bodies.ini');
        [rawIni, ~, ~] = inifile(iniPath, 'readall');
        bodyInfo = processINIBodyInfo(rawIni, false, 'bodyInfo');
        cachedBodyData = CelestialBodyData(bodyInfo);
    end

    celBodyData = cachedBodyData;
end
