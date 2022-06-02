classdef LaunchVehicleSensorReport < matlab.mixin.SetGet
    %LaunchVehicleSensorReport Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sensor AbstractSensor
        lvdData LvdData
    end
    
    methods
        function obj = LaunchVehicleSensorReport(sensor, lvdData)
            obj.sensor = sensor;
            obj.lvdData = lvdData;
        end
        
        function [filepath, coverageT, azT, elT, rngT, angleToBoresightT] = generateReport(obj, targets, progressBar, busyStatusLabel, sensorNum, totalSensorNum, reportFolder)
            arguments
                obj(1,1) LaunchVehicleSensorReport
                targets(1,:) AbstractSensorTarget
                progressBar(1,1) wt.ProgressBar
                busyStatusLabel(1,1) matlab.ui.control.Label
                sensorNum(1,1) double
                totalSensorNum(1,1) double
                reportFolder(1,1) string
            end
            
            progressBar.Indeterminate = false;
            progressBar.startProgress('');
            busyStatusLabel.Text = sprintf('Generating Data for Sensor "%s" [%u of %u]', obj.sensor.getListboxStr(), sensorNum, totalSensorNum);
            
            bodyInfos = obj.lvdData.celBodyData.getAllBodyInfo();
            stateLog = obj.lvdData.stateLog;
            
            entries = stateLog.getAllEntries();
            times = [entries.time]';
            coverages = cell(1,numel(targets));
            sensorAzs = cell(1,numel(targets));
            sensorEls = cell(1,numel(targets));
            sensorRngs = cell(1,numel(targets));
            sensorAnglesToBoresight = cell(1,numel(targets));
            for(i=1:length(entries))
                entry = entries(i);
                
                sensorState = entry.getSensorStateForSensor(obj.sensor);
                scElem = entry.getCartesianElementSetRepresentation(false);
                dcm = entry.attitude.dcm;
                frame = entry.centralBody.getBodyCenteredInertialFrame();
                
                results = obj.sensor.evaluateSensorTargets(sensorState, targets, scElem, dcm, bodyInfos, frame); 
                
                for(j=1:length(results))
                    result = results(j);
                    
                    coverages{j} = vertcat(coverages{j}, result.resultsBool(:)');
                    
                    [az, el, rng, angle] = result.getBoresightRelativeAngles(sensorState, scElem, dcm); 
                    
                    sensorAzs{j} = vertcat(sensorAzs{j}, az);
                    sensorEls{j} = vertcat(sensorEls{j}, el);
                    sensorRngs{j} = vertcat(sensorRngs{j}, rng);
                    sensorAnglesToBoresight{j} = vertcat(sensorAnglesToBoresight{j}, angle);
                end
                
                progressBar.setProgress(i/length(entries), sprintf('%0.3f %%', 100*i/length(entries)));
            end
            
            progressBar.Indeterminate = true;
            busyStatusLabel.Text = sprintf('Writing Report File for Sensor "%s" [%u of %u]', obj.sensor.getListboxStr(), sensorNum, totalSensorNum);
            progressBar.setProgress(1, '');
            drawnow;
            
            coverageT = {};
            filename = sprintf('SensorReport_%s_%s.xls', obj.sensor.getListboxStr(),datestr(now, 'YYYYmmDD_HHMMss'));
            filepath = fullfile(reportFolder, filename);
            for(i=1:length(coverages))
                coverage = coverages{i};
                
                %compute instant and cumulative coverage
                instantCoverage = NaN(height(coverage), 1);
                cumCoverage = NaN(height(coverage), 1);
                for(j=1:height(coverage))
                    subCoverage = coverage(j,:);
                    instantCoverage(j) = sum(subCoverage) / numel(subCoverage);
                    
                    subCoverage = coverage(1:j,:);
                    sumSubCoverage = sum(subCoverage,1);
                    sumSubCoverage(sumSubCoverage >= 1) = 1;
                    cumCoverage(j) = sum(sumSubCoverage) / numel(sumSubCoverage);
                end

                target = targets(i);
                labelStrs = target.getTargetPtLabelStrs();
                
                %Info worksheet
                sensorNums = sensorNum * ones(numel(targets),1);
                sensorNames = repmat(string(obj.sensor.getListboxStr()), numel(targets), 1);
                targetNums = [1:numel(targets)]'; %#ok<NBRAK>
                for(j=1:length(targets))
                    targetNames(j,1) = string(targets(j).getListboxStr()); %#ok<AGROW>
                end
                
                varNames = {'Sensor Number', 'Sensor Name', 'Target Number', 'Target Name'};
                data = table(sensorNums, sensorNames, targetNums, targetNames, 'VariableNames',varNames);
                writetable(data, filepath, 'FileType','spreadsheet', 'Sheet','Information'); 
                
                %Sensor Coverage
                worksheetName = sprintf('Coverage, Sensor %u Target %u', sensorNum, i);
                
                header = horzcat('Time [UT sec]', labelStrs, "Instantaneous Coverage Fraction", "Cumulative Coverage Fraction");
                data = horzcat(times, coverage, instantCoverage, cumCoverage);
                
                coverageT{i} = writeDataTableToXLSFile(data, header, filepath, worksheetName); %#ok<AGROW>
                
                %Sensor to Target Az
                worksheetName = sprintf('Azimuth, Sensor %u Target %u', sensorNum, i);
                
                header = horzcat('Time [UT sec]', labelStrs);
                data = horzcat(times, rad2deg(sensorAzs{i}));
                
                azT{i} = writeDataTableToXLSFile(data, header, filepath, worksheetName); %#ok<AGROW>
                
                %Sensor to Target El
                worksheetName = sprintf('Elevation, Sensor %u Target %u', sensorNum, i);
                
                header = horzcat('Time [UT sec]', labelStrs);
                data = horzcat(times, rad2deg(sensorEls{i}));
                
                elT{i} = writeDataTableToXLSFile(data, header, filepath, worksheetName); %#ok<AGROW>
                
                %Sensor to Target Range
                worksheetName = sprintf('Range, Sensor %u Target %u', sensorNum, i);
                
                header = horzcat('Time [UT sec]', labelStrs);
                data = horzcat(times, sensorRngs{i});
                
                rngT{i} = writeDataTableToXLSFile(data, header, filepath, worksheetName); %#ok<AGROW>
                
                %Sensor to Target Range
                worksheetName = sprintf('Angle, Sensor %u Target %u', sensorNum, i);
                
                header = horzcat('Time [UT sec]', labelStrs);
                data = horzcat(times, rad2deg(sensorAnglesToBoresight{i}));
                
                angleToBoresightT{i} = writeDataTableToXLSFile(data, header, filepath, worksheetName); %#ok<AGROW>
            end
        end
    end
end

function T = writeDataTableToXLSFile(data, header, filename, worksheetName)
    T = array2table(data);
    T.Properties.VariableNames = header;

    userdata.WorksheetName = worksheetName;
    T.Properties.UserData = userdata;

    writetable(T, filename, 'FileType','spreadsheet', 'Sheet',worksheetName);    
end