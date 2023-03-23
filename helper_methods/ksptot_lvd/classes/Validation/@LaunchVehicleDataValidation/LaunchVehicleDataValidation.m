classdef LaunchVehicleDataValidation < matlab.mixin.SetGet
    %LaunchVehicleDataValidation Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
        
        validators AbstractLaunchVehicleDataValidator
        outputs AbstractLaunchVehicleValidatorOutput
    end
    
    methods
        function obj = LaunchVehicleDataValidation(lvdData)
            obj.lvdData = lvdData;
            
            obj.validators(end+1) = NoOptimizationVariablesValidator(obj.lvdData);
            obj.validators(end+1) = OptimizationVariablesNearBoundsValidator(obj.lvdData);
            obj.validators(end+1) = ConstraintValidator(obj.lvdData);
            obj.validators(end+1) = MaxSimTimeReachedValidator(obj.lvdData);
            obj.validators(end+1) = MaxPropTimeReachedValidator(obj.lvdData);
            obj.validators(end+1) = ThrottleWithNoThrustModelValidator(obj.lvdData);
            obj.validators(end+1) = AtmoWithNoDragModelValidator(obj.lvdData);
            obj.validators(end+1) = MinAltitudeReachedValidator(obj.lvdData);
            obj.validators(end+1) = RadiusOutsideSoIValidator(obj.lvdData);
            obj.validators(end+1) = ForceModelPropagatorWithNoForceModelsValidator(obj.lvdData);
            obj.validators(end+1) = ThirdBodyGravityValidator(obj.lvdData);
            obj.validators(end+1) = MaxFixedStepsReachedValidator(obj.lvdData);
            obj.validators(end+1) = SomeEventsNotPlottedValidator(obj.lvdData);
        end

        function validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);

            for(i=1:length(obj.validators)) %#ok<*NO4LP>
                validator = obj.validators(i);
                [subErrors, subWarnings] = validator.validate();
                
                if(not(isempty(subErrors)))
                    errors = horzcat(errors, subErrors); %#ok<AGROW>
                end
                
                if(not(isempty(subWarnings)))
                    warnings = horzcat(warnings, subWarnings); %#ok<AGROW>
                end
            end
            
            if(isempty(obj.outputs) && isempty(errors) && isempty(warnings))
                obj.outputs = LaunchVehicleDataValidationOK();
            else
                obj.outputs = horzcat(obj.outputs,errors,warnings);
            end
        end
        
        function writeOutputsToUI(obj, hSlider, hLabels, updateSlider)
            numWarnError = length(obj.outputs);

            set(hLabels,'Visible','off');
            
            if(numWarnError <= 6)
                set(hSlider,'Max',1.0);
                set(hSlider,'Min',0.0);
                set(hSlider,'Value',1.0);
                set(hSlider,'Enable','off');
            else
                if(updateSlider)
                    set(hSlider,'Min',0.0);
                    set(hSlider,'Max',numWarnError-6);
                    set(hSlider,'Value',numWarnError-6);
                    set(hSlider,'SliderStep',[1/(numWarnError-6),1.0]);
                    set(hSlider,'Enable','on');
                end
            end
            
            lblOffset = round(get(hSlider,'Max') - get(hSlider,'Value'));
            set(hSlider,'Value',round(get(hSlider,'Value')));
            
            lblUseCnt = 0;
            for(i=1+lblOffset:length(obj.outputs))
                if(lblUseCnt>=6)
                    break;
                end
                hLbl = hLabels(lblUseCnt+1);
                
                hLbl.Visible = 'on';
                obj.outputs(i).writeToLabel(hLbl);
                lblUseCnt = lblUseCnt+1;
            end

            drawnow limitrate nocallbacks;
        end

        function writeOutputsToUITable(obj, hTable)
            arguments
                obj(1,1) LaunchVehicleDataValidation
                hTable(1,1) matlab.ui.control.Table
            end

            data = string.empty(1,0);
            s = matlab.ui.style.Style.empty(1,0);
            for(i=1:length(obj.outputs))
                [dd, ss] = obj.outputs(i).getUiTableStringAndRowStyle(); 
                dd = string(dd);

                ddArr = strsplit(strtrim(dd),'\n');
                for(j=1:numel(ddArr))
                    subDD = ddArr(j);

                    if(j >= 2)
                        subDD = sprintf("‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‎‎‎‎%s",subDD);
                    end

                    data(end+1) = subDD; %#ok<AGROW>
                    s(end+1) = ss; %#ok<AGROW>
                end
            end

            hTable.Data = data(:);
            for(i=1:length(s))
                addStyle(hTable, s(i), "row", i);
            end
        end
        
        function clearOutputs(obj)
            obj.outputs = AbstractLaunchVehicleValidatorOutput.empty(1,0);
        end
    end
end