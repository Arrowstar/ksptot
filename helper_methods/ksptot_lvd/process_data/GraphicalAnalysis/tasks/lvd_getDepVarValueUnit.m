function [depVarValue, depVarUnit, taskStr, refBodyInfo] = lvd_getDepVarValueUnit(i, subLog, taskStr, refBodyId, celBodyData, onlyReturnTaskStr)
    %lvd_getDepVarValueUnit Summary of this function goes here
    %   Detailed explanation goes here
    
    if(~isempty(refBodyId))
        refBodyInfo = getBodyInfoByNumber(refBodyId, celBodyData);
    else
        refBodyInfo = [];
    end
    
    if(onlyReturnTaskStr == true)
        depVarValue = NaN;
        depVarUnit = NaN;
        
        return;
    end
    
    switch taskStr
        case 'Yaw Angle'
            depVarValue = lvd_SteeringAngleTask(subLog(i), 'yaw');
            depVarUnit = 'deg';
        case 'Pitch Angle'
            depVarValue = lvd_SteeringAngleTask(subLog(i), 'pitch');
            depVarUnit = 'deg';
        case 'Roll Angle'
            depVarValue = lvd_SteeringAngleTask(subLog(i), 'roll');
            depVarUnit = 'deg';
        case 'Bank Angle'
            depVarValue = lvd_SteeringAngleTask(subLog(i), 'bank');
            depVarUnit = 'deg';
        case 'Angle of Attack'
            depVarValue = lvd_SteeringAngleTask(subLog(i), 'angleOfAttack');
            depVarUnit = 'deg';
        case 'SideSlip Angle'
            depVarValue = lvd_SteeringAngleTask(subLog(i), 'sideslip');
            depVarUnit = 'deg';
        case 'Throttle'
            depVarValue = lvd_ThrottleTask(subLog(i), 'throttle');
            depVarUnit = 'Percent';
        case 'Thrust to Weight Ratio'
            depVarValue = lvd_ThrottleTask(subLog(i), 't2w');
            depVarUnit = ' ';
        case 'Total Thrust'
            depVarValue = lvd_ThrottleTask(subLog(i), 'totalthrust');
            depVarUnit = 'kN';
        case 'Two-Body Time To Impact'
            depVarValue = lvd_TwoBodyImpactPointTasks(subLog(i), 'timeToImpact');
            depVarUnit = 'sec';
        case 'Two-Body Impact Latitude'
            depVarValue = lvd_TwoBodyImpactPointTasks(subLog(i), 'latitude');
            depVarUnit = 'degN';
        case 'Two-Body Impact Longitude'
            depVarValue = lvd_TwoBodyImpactPointTasks(subLog(i), 'longitude');
            depVarUnit = 'degE';
        case 'Drag Coefficient'
            depVarValue = lvd_AeroTasks(subLog(i), 'dragCoeff', []);
            depVarUnit = '';
        case 'Drag Area'
            depVarValue = lvd_AeroTasks(subLog(i), 'dragArea', []);
            depVarUnit = 'm^2';
        case 'Event Number'
            depVarValue = lvd_EventNumTask(subLog(i), 'eventNum');
            depVarUnit = '';
        case 'Total Effective Isp'
            depVarValue = lvd_PropulsionTasks(subLog(i), 'totalEffIsp');
            depVarUnit = 'sec';
        case 'Total Thrust Vector X Component'
            depVarValue = lvd_ThrottleTask(subLog(i), 'thrust_x');
            depVarUnit = 'kN';
        case 'Total Thrust Vector Y Component'
            depVarValue = lvd_ThrottleTask(subLog(i), 'thrust_y');
            depVarUnit = 'kN';
        case 'Total Thrust Vector Z Component'
            depVarValue = lvd_ThrottleTask(subLog(i), 'thrust_z');
            depVarUnit = 'kN';
        case 'Power Net Charge Rate'
            [depVarValue, depVarUnit] = lvd_ElectricalPowerGlobalTasks(subLog(i), 'netChargeRate');
        case 'Power Cumulative Storage State of Charge'
            [depVarValue, depVarUnit] = lvd_ElectricalPowerGlobalTasks(subLog(i), 'cumStorageSoC');
        case 'Power Maximum Available Storage'
            [depVarValue, depVarUnit] = lvd_ElectricalPowerGlobalTasks(subLog(i), 'maxAvailableStorage');
            
        otherwise %is a programmatically generated string that we'll handle here
            tankMassPattern = '^Tank (\d+?) Mass - ".*"';
            tankMassDotPattern = '^Tank (\d+?) Mass Flow Rate - ".*"';
            
            stageDryMassPattern = '^Stage (\d+?) Dry Mass - ".*"';
            stageActivePattern = '^Stage (\d+?) Active State - ".*"';
            
            engineActivePattern = '^Engine (\d+?) Active State - ".*"';
            
            stopwatchValuePattern = '^Stopwatch (\d+?) Value - ".*"';
            
            extremaValuePattern = '^Extrema (\d+?) Value - ".*"';
           
            grdObjAzValuePattern = '^Ground Object (\d+?) Azimuth to S/C - ".*"';
            grdObjElValuePattern = '^Ground Object (\d+?) Elevation to S/C - ".*"';
            grdObjRngValuePattern = '^Ground Object (\d+?) Range to S/C - ".*"';
            grdObjLoSValuePattern = '^Ground Object (\d+?) Line of Sight to S/C - ".*"';
            
            calcObjValuePattern = '^Calculus (\d+?) Value - ".*"';
            
            pwrStorageActivePattern = '^Power Storage (\d+?) Active State - ".*"';
            pwrStorageSoCPattern = '^Power Storage (\d+?) State of Charge - ".*"';
            pwrSinkActivePattern = '^Power Sink (\d+?) Active State - ".*"';
            pwrSinkDischargeRatePattern = '^Power Sink (\d+?) Discharge Rate - ".*"';
            pwrSrcActivePattern = '^Power Source (\d+?) Active State - ".*"';
            pwrSrcChargeRatePattern = '^Power Source (\d+?) Charge Rate - ".*"';
            
            geoPtPosXPattern = '^Point (\d+?) Position \(X\) - ".*"';
            geoPtPosYPattern = '^Point (\d+?) Position \(Y\) - ".*"';
            geoPtPosZPattern = '^Point (\d+?) Position \(Z\) - ".*"';
            
            geoVectXPattern = '^Vector (\d+?) X Component - ".*"';
            geoVectYPattern = '^Vector (\d+?) Y Component - ".*"';
            geoVectZPattern = '^Vector (\d+?) Z Component - ".*"';
            geoVectMagPattern = '^Vector (\d+?) Magnitude - ".*"';
            geoVectOriginXPattern = '^Vector (\d+?) Origin Position \(X\) - ".*"';
            geoVectOriginYPattern = '^Vector (\d+?) Origin Position \(Y\) - ".*"';
            geoVectOriginZPattern = '^Vector (\d+?) Origin Position \(Z\) - ".*"';
            
            if(not(isempty(regexpi(taskStr, tankMassPattern))))
                tokens = regexpi(taskStr, tankMassPattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                tankInd = str2double(tokens);
                
                [~,tanks] = subLog(i).launchVehicle.getTanksGraphAnalysisTaskStrs();
                tank = tanks(tankInd);
                
                depVarValue = lvd_TankMassTasks(subLog(i), 'tankMass', tank);
                depVarUnit = 'mT';
                
            elseif(not(isempty(regexpi(taskStr, tankMassDotPattern))))
                tokens = regexpi(taskStr, tankMassDotPattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                tankInd = str2double(tokens);
                
                [~,tanks] = subLog(i).launchVehicle.getTanksGraphAnalysisTaskStrs();
                tank = tanks(tankInd);
                
                depVarValue = lvd_TankMassTasks(subLog(i), 'tankMDot', tank);
                depVarUnit = 'mT/s';
                
            elseif(not(isempty(regexpi(taskStr, stageDryMassPattern))))
                tokens = regexpi(taskStr, stageDryMassPattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                stageInd = str2double(tokens);
                
                [~,stages] = subLog(i).launchVehicle.getStagesGraphAnalysisTaskStrs();
                stage = stages(stageInd);
                
                depVarValue = lvd_StageTasks(subLog(i), 'dryMass', stage);
                depVarUnit = 'mT';
                
            elseif(not(isempty(regexpi(taskStr, stageActivePattern))))
                tokens = regexpi(taskStr, stageActivePattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                stageInd = str2double(tokens);
                
                [~,stages] = subLog(i).launchVehicle.getStagesGraphAnalysisTaskStrs();
                stage = stages(stageInd);
                
                depVarValue = lvd_StageTasks(subLog(i), 'active', stage);
                depVarUnit = '';
                
            elseif(not(isempty(regexpi(taskStr, engineActivePattern))))
                tokens = regexpi(taskStr, engineActivePattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                engineInd = str2double(tokens);
                
                [~,engines] = subLog(i).launchVehicle.getEnginesGraphAnalysisTaskStrs();
                engine = engines(engineInd);
                
                depVarValue = lvd_EngineTasks(subLog(i), 'active', engine);
                depVarUnit = '';
                
            elseif(not(isempty(regexpi(taskStr, stopwatchValuePattern))))
                tokens = regexpi(taskStr, stopwatchValuePattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                stopwatchInd = str2double(tokens);
                
                [~,stopwatches] = subLog(i).launchVehicle.getStopwatchGraphAnalysisTaskStrs();
                stopwatch = stopwatches(stopwatchInd);
                
                depVarValue = lvd_StopwatchMassTasks(subLog(i), 'swValue', stopwatch);
                depVarUnit = 'sec';
                
            elseif(not(isempty(regexpi(taskStr, extremaValuePattern))))
                tokens = regexpi(taskStr, extremaValuePattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                calcObjInd = str2double(tokens);
                
                [~,calcObjs] = subLog(i).launchVehicle.getExtremaGraphAnalysisTaskStrs();
                calcObj = calcObjs(calcObjInd);
                
                [depVarValue, depVarUnit] = lvd_ExtremaTasks(subLog(i), 'extremumValue', calcObj);
            
            elseif(not(isempty(regexpi(taskStr, grdObjAzValuePattern))))
                tokens = regexpi(taskStr, grdObjAzValuePattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                ind = str2double(tokens);
                
                [~, grdObjs] = subLog(i).lvdData.groundObjs.getGrdObjAzGraphAnalysisTaskStrs();
                grdObj = grdObjs(ind);
                
                [depVarValue, depVarUnit] = lvd_GrdObjTasks(subLog(i), 'azimuth', grdObj);
                
            elseif(not(isempty(regexpi(taskStr, grdObjElValuePattern))))
                tokens = regexpi(taskStr, grdObjElValuePattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                ind = str2double(tokens);
                
                [~, grdObjs] = subLog(i).lvdData.groundObjs.getGrdObjAzGraphAnalysisTaskStrs();
                grdObj = grdObjs(ind);
                
                [depVarValue, depVarUnit] = lvd_GrdObjTasks(subLog(i), 'elevation', grdObj);
                
            elseif(not(isempty(regexpi(taskStr, grdObjRngValuePattern))))
                tokens = regexpi(taskStr, grdObjRngValuePattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                ind = str2double(tokens);
                
                [~, grdObjs] = subLog(i).lvdData.groundObjs.getGrdObjAzGraphAnalysisTaskStrs();
                grdObj = grdObjs(ind);
                
                [depVarValue, depVarUnit] = lvd_GrdObjTasks(subLog(i), 'range', grdObj);
                
            elseif(not(isempty(regexpi(taskStr, grdObjLoSValuePattern))))
                tokens = regexpi(taskStr, grdObjLoSValuePattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                ind = str2double(tokens);
                
                [~, grdObjs] = subLog(i).lvdData.groundObjs.getGrdObjAzGraphAnalysisTaskStrs();
                grdObj = grdObjs(ind);
                
                [depVarValue, depVarUnit] = lvd_GrdObjTasks(subLog(i), 'LoS', grdObj);
                
            elseif(not(isempty(regexpi(taskStr, calcObjValuePattern))))
                tokens = regexpi(taskStr, calcObjValuePattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                calcObjInd = str2double(tokens);
                
                [~,calcObjs] = subLog(i).launchVehicle.getCalculusCalcObjGraphAnalysisTaskStrs();
                calcObj = calcObjs(calcObjInd);
                
                [depVarValue, depVarUnit] = lvd_CalculusCalculationTasks(subLog(i), 'calcObjValue', calcObj);
                
            elseif(not(isempty(regexpi(taskStr, pwrStorageActivePattern))))
                tokens = regexpi(taskStr, pwrStorageActivePattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                pwrStorageObjInd = str2double(tokens);
                
                [~, pwrStorages] = subLog(i).launchVehicle.getPowerStorageGraphAnalysisTaskStrs();
                pwrStorage = pwrStorages(pwrStorageObjInd);
                
                [depVarValue, depVarUnit] = lvd_ElectricalPowerStorageTasks(subLog(i), 'active', pwrStorage);
                
            elseif(not(isempty(regexpi(taskStr, pwrStorageSoCPattern))))
                tokens = regexpi(taskStr, pwrStorageSoCPattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                pwrStorageObjInd = str2double(tokens);
                
                [~, pwrStorages] = subLog(i).launchVehicle.getPowerStorageGraphAnalysisTaskStrs();
                pwrStorage = pwrStorages(pwrStorageObjInd);
                
                [depVarValue, depVarUnit] = lvd_ElectricalPowerStorageTasks(subLog(i), 'stateOfCharge', pwrStorage);
                
            elseif(not(isempty(regexpi(taskStr, pwrSinkActivePattern))))
                tokens = regexpi(taskStr, pwrSinkActivePattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                pwrSinkObjInd = str2double(tokens);
                
                [~, pwrSinks] = subLog(i).launchVehicle.getPowerSinksGraphAnalysisTaskStrs();
                pwrSink = pwrSinks(pwrSinkObjInd);
                
                [depVarValue, depVarUnit] = lvd_ElectricalPowerSinkTasks(subLog(i), 'active', pwrSink);
                
            elseif(not(isempty(regexpi(taskStr, pwrSinkDischargeRatePattern))))
                tokens = regexpi(taskStr, pwrSinkDischargeRatePattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                pwrSinkObjInd = str2double(tokens);
                
                [~, pwrSinks] = subLog(i).launchVehicle.getPowerSinksGraphAnalysisTaskStrs();
                pwrSink = pwrSinks(pwrSinkObjInd);
                
                [depVarValue, depVarUnit] = lvd_ElectricalPowerSinkTasks(subLog(i), 'dischargeRate', pwrSink);
                
            elseif(not(isempty(regexpi(taskStr, pwrSrcActivePattern))))
                tokens = regexpi(taskStr, pwrSrcActivePattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                pwrSrcObjInd = str2double(tokens);
                
                [~, powerSrcs] = subLog(i).launchVehicle.getPowerSrcsGraphAnalysisTaskStrs();
                powerSrc = powerSrcs(pwrSrcObjInd);
                
                [depVarValue, depVarUnit] = lvd_ElectricalPowerSrcTasks(subLog(i), 'active', powerSrc);
                
            elseif(not(isempty(regexpi(taskStr, pwrSrcChargeRatePattern))))
                tokens = regexpi(taskStr, pwrSrcChargeRatePattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                pwrSrcObjInd = str2double(tokens);
                
                [~, powerSrcs] = subLog(i).launchVehicle.getPowerSrcsGraphAnalysisTaskStrs();
                powerSrc = powerSrcs(pwrSrcObjInd);
                
                [depVarValue, depVarUnit] = lvd_ElectricalPowerSrcTasks(subLog(i), 'chargeRate', powerSrc);
                
            elseif(not(isempty(regexpi(taskStr, geoPtPosXPattern))))
                tokens = regexpi(taskStr, geoPtPosXPattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                pointInd = str2double(tokens);
                
                [~, points] = subLog(i).lvdData.geometry.points.getPointPositionXGraphAnalysisTaskStrs();
                point = points(pointInd);
                
                [depVarValue, depVarUnit] = lvd_GeometricPointTasks(subLog(i), 'PosX', point);
                
            elseif(not(isempty(regexpi(taskStr, geoPtPosYPattern))))
                tokens = regexpi(taskStr, geoPtPosYPattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                pointInd = str2double(tokens);
                
                [~, points] = subLog(i).lvdData.geometry.points.getPointPositionXGraphAnalysisTaskStrs();
                point = points(pointInd);
                
                [depVarValue, depVarUnit] = lvd_GeometricPointTasks(subLog(i), 'PosY', point);
                
            elseif(not(isempty(regexpi(taskStr, geoPtPosZPattern))))
                tokens = regexpi(taskStr, geoPtPosZPattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                pointInd = str2double(tokens);
                
                [~, points] = subLog(i).lvdData.geometry.points.getPointPositionXGraphAnalysisTaskStrs();
                point = points(pointInd);
                
                [depVarValue, depVarUnit] = lvd_GeometricPointTasks(subLog(i), 'PosZ', point);
                
            elseif(not(isempty(regexpi(taskStr, geoVectXPattern))))
                tokens = regexpi(taskStr, geoVectXPattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                vectInd = str2double(tokens);
                
                [~, vectors] = subLog(i).lvdData.geometry.vectors.getVectorXComponentGraphAnalysisTaskStrs();
                vector = vectors(vectInd);
                
                [depVarValue, depVarUnit] = lvd_GeometricVectorTasks(subLog(i), 'VectorX', vector);
                
            elseif(not(isempty(regexpi(taskStr, geoVectYPattern))))
                tokens = regexpi(taskStr, geoVectYPattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                vectInd = str2double(tokens);
                
                [~, vectors] = subLog(i).lvdData.geometry.vectors.getVectorYComponentGraphAnalysisTaskStrs();
                vector = vectors(vectInd);
                
                [depVarValue, depVarUnit] = lvd_GeometricVectorTasks(subLog(i), 'VectorY', vector);
                
            elseif(not(isempty(regexpi(taskStr, geoVectZPattern))))
                tokens = regexpi(taskStr, geoVectZPattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                vectInd = str2double(tokens);
                
                [~, vectors] = subLog(i).lvdData.geometry.vectors.getVectorZComponentGraphAnalysisTaskStrs();
                vector = vectors(vectInd);
                
                [depVarValue, depVarUnit] = lvd_GeometricVectorTasks(subLog(i), 'VectorZ', vector);
                
            elseif(not(isempty(regexpi(taskStr, geoVectMagPattern))))
                tokens = regexpi(taskStr, geoVectMagPattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                vectInd = str2double(tokens);
                
                [~, vectors] = subLog(i).lvdData.geometry.vectors.getVectorMagComponentGraphAnalysisTaskStrs();
                vector = vectors(vectInd);
                
                [depVarValue, depVarUnit] = lvd_GeometricVectorTasks(subLog(i), 'VectMag', vector);
                
            elseif(not(isempty(regexpi(taskStr, geoVectOriginXPattern))))
                tokens = regexpi(taskStr, geoVectOriginXPattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                vectInd = str2double(tokens);
                
                [~, vectors] = subLog(i).lvdData.geometry.vectors.getOriginPosXComponentGraphAnalysisTaskStrs();
                vector = vectors(vectInd);
                
                [depVarValue, depVarUnit] = lvd_GeometricVectorTasks(subLog(i), 'OriginX', vector);
                
            elseif(not(isempty(regexpi(taskStr, geoVectOriginYPattern))))
                tokens = regexpi(taskStr, geoVectOriginYPattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                vectInd = str2double(tokens);
                
                [~, vectors] = subLog(i).lvdData.geometry.vectors.getOriginPosYComponentGraphAnalysisTaskStrs();
                vector = vectors(vectInd);
                
                [depVarValue, depVarUnit] = lvd_GeometricVectorTasks(subLog(i), 'OriginY', vector);
                
            elseif(not(isempty(regexpi(taskStr, geoVectOriginZPattern))))
                tokens = regexpi(taskStr, geoVectOriginZPattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                vectInd = str2double(tokens);
                
                [~, vectors] = subLog(i).lvdData.geometry.vectors.getOriginPosZComponentGraphAnalysisTaskStrs();
                vector = vectors(vectInd);
                
                [depVarValue, depVarUnit] = lvd_GeometricVectorTasks(subLog(i), 'OriginZ', vector);
                
            else
                error('Unknown LVD task string: "%s"', taskStr);                
            end
    end
end