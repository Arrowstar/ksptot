classdef TerminationConditionEnum < matlab.mixin.SetGet
    %TerminationConditionEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Altitude('Altitude','AltitudeTermCondition');
        AngleOfAttack('Angle of Attack','AngleOfAttackTermCondition');
        BankAngle('Bank Angle','BankAngleTermCondition');
        EventDuration('Event Duration','EventDurationTermCondition');
        Latitude('Latitude','LatitudeTermCondition');
        PitchAngle('Pitch Angle','PitchTermCondition');
        RollAngle('Roll Angle','RollTermCondition');
        SideSlipAngle('Side Slip Angle','SideSlipAngleTermCondition');
        SoITrans('Next SoI Transition','SoITransitionTermCondition');
        TankMass('Tank Mass','TankMassTermCondition');
        ThrottleSetting('Throttle Setting','ThrottleTermCondition');
        ThrustToWeightRatio('Thrust to Weight Ratio (Sea Level)','SeaLevelThrustToWeightTermCondition');
        TrueAnomaly('True Anomaly','TrueAnomalyTermCondition');
        YawAngle('Yaw Angle','YawTermCondition');
    end
    
    properties
        nameStr(1,:) char = '';
        classNameStr(1,:) char = '';
    end
    
    methods
        function obj = TerminationConditionEnum(nameStr, classNameStr)
            obj.nameStr = nameStr;
            obj.classNameStr = classNameStr;
        end
    end
    
    methods(Static)
        function termCondStrs = getTermCondTypeNameStrs()
            [m,~] = enumeration('TerminationConditionEnum');
            
            termCondStrs = {};
            for(i=1:length(m)) %#ok<*NO4LP>
                termCondStrs{end+1} = m(i).nameStr; %#ok<AGROW>
            end
        end
        
        function ind = getIndOfListboxStrsForTermCond(termCond)
            [m,~] = enumeration('TerminationConditionEnum');
            inputClass = class(termCond);
            
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