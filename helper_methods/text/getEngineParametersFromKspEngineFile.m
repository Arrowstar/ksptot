function [thrustCurve, ispCurve, maxThrottle, minThrottle, engineName] = getEngineParametersFromKspEngineFile(file)
    text = fileread(file);
    
    engineData = parseKspConfigFile(text);
    
    if(isfield(engineData,'name'))
        engineName = engineData.name;
    else
        engineName = '';
    end
    
    modules = engineData.MODULE;
    
    moduleEngines = [];
    for(i=1:length(modules))
        if(strcmpi(modules{i}.name,'ModuleEngines') || strcmpi(modules{i}.name,'ModuleEnginesFX'))
            moduleEngines = modules{i};
            break;
        end
    end
    
    if(not(isempty(moduleEngines)))
        minVacThrust = moduleEngines.minThrust * 1000; %N
        maxVacThrust = moduleEngines.maxThrust * 1000; %N
        
        ispCurve = moduleEngines.atmosphereCurve;
        ispCurvePts = NaN(length(ispCurve.key),2);
        for(i=1:length(ispCurve.key))
            keySplit = strsplit(ispCurve.key{i},' ');
            keyPts = str2double(keySplit);
            ispCurvePts(i,:) = keyPts;
        end
        
        ispCurvePts(:,1) = LaunchVehicleEngine.seaLvlPress * ispCurvePts(:,1); %convert from atmospheres to kPa
        
        ispCurve = IspPressureCurve.getCurveFromPoints(ispCurvePts(:,1), ispCurvePts(:,2));
        vacIsp = ispCurve.evalCurve(LaunchVehicleEngine.vacPress);
        
        maxMdot = maxVacThrust/(getG0() * vacIsp); %kg/s
        
        thrustCurvePts(:,1) = ispCurvePts(:,1);
        thrustCurvePts(:,2) = (maxMdot * getG0() .* ispCurvePts(:,2)) / 1000; %kN
        thrustCurve = ThrustPressureCurve.getCurveFromPoints(thrustCurvePts(:,1), thrustCurvePts(:,2));
        
        maxThrottle = 1;
        
        if(strcmpi(moduleEngines.EngineType, 'SolidBooster'))
            minThrottle = 1;
        else
            minThrottle = minVacThrust/maxVacThrust;
        end
    else
        error('Could not parse KSP engine file: Could not find a "moduleEngines" data block.');
    end
end