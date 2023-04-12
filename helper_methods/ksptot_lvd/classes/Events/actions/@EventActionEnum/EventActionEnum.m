classdef EventActionEnum < matlab.mixin.SetGet
    %EventActionEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        AddDeltaV('Add Impulsive Delta-V', 'AddDeltaVAction'); 
        AddMassToTank('Add Mass To Tank','AddMassToTankAction')
        SetEngineActiveState('Set Engine Active State','SetEngineActiveStateAction')
        SetStageActiveState('Set Stage Active State','SetStageActiveStateAction');
        SetSteeringModel('Set Steering Model','SetSteeringModelAction');
        SetThrottleModel('Set Throttle Model','SetThrottleModelAction');
        SetEngineToTankState('Set Engine To Tank Connection State','SetEngineTankConnActiveStateEventAction');
        SetTankToTankState('Set Tank To Tank Connection State','SetTankTankConnActiveStateEventAction');
        SetTankToTankFlowRate('Set Tank To Tank Connection Flow Rate','SetTankTankConnFlowRateEventAction');
        SetHoldDownClampState('Set Hold Down Clamp State','SetHoldDownClampActiveStateAction');
        SetAeroDragProps('Set Drag Aero Properties','SetDragAeroPropertiesAction');
        SetAeroLiftProps('Set Lift Aero Properties','SetLiftAeroPropertiesAction');
        SetStopwatchRunningState('Set Stopwatch Running State','SetStopwatchRunningStateAction');
        SetExtremumRecordingState('Set Extremum Recording State','SetExtremumRecordingStateAction');
        ResetExtremumValueAction('Reset Extremum Value','ResetExtremumValueAction');
        SetThirdBodyGravSourcesAction('Set Third Body Gravity Sources','SetThirdBodyGravitySourcesAction');
        SetKinematicStateAction('Set Kinematic State','SetKinematicStateAction');
        SetPowerSinkActiveState('Set Power Sink Active State','SetPowerSinkActiveStateAction');
        SetPowerSrcActiveState('Set Power Source Active State','SetPowerSrcActiveStateAction')
        SetPowerStorageActiveState('Set Power Storage Active State','SetPowerStorageActiveStateAction')
        SetSensorActiveState('Set Sensor Active State','SetSensorActiveStateAction');
        SetSensorMaxRange('Set Sensor Max Range','SetSensorMaxRangeAction');
        SetConicalSensorAngle('Set Conical Sensor Half Angle','SetConicalSensorAngleAction');
        SetSensorSteeringModel('Set Sensor Pointing Model', 'SetSensorSteeringModelAction');
        SetRectangularSensorAzAngle('Set Rectangular Sensor Azimuth Angle','SetRectangularlSensorAzAngleAction');
        SetRectangularSensorDecAngle('Set Rectangular Sensor Declination Angle','SetRectangularlSensorDecAngleAction');
        SetSolarRadPressModelAction('Set Solar Radiation Pressure Model', 'SetSolarRadPressPropertiesAction');
        SetPluginVarValueAction('Set Plugin Variable Value', 'SetLvdPluginVarValueAction');
    end
    
    properties
        nameStr char = '';
        classNameStr char = '';
    end
    
    methods
        function obj = EventActionEnum(nameStr, classNameStr)
            obj.nameStr = nameStr;
            obj.classNameStr = classNameStr;
        end
    end
    
    methods(Static)
        function termCondStrs = getActionTypeNameStrs()
            [m,~] = enumeration('EventActionEnum');
            
            termCondStrs = {};
            for(i=1:length(m)) %#ok<*NO4LP>
                termCondStrs{end+1} = m(i).nameStr; %#ok<AGROW>
            end
        end
        
        function ind = getIndOfListboxStrsForAction(action)
            [m,~] = enumeration('EventActionEnum');
            inputClass = class(action);
            
            ind = -1;
            for(i=1:length(m))
                if(strcmpi(m(i).classNameStr,inputClass))
                    ind = i;
                    break;
                end
            end
        end
    end
end