classdef LaunchVehicleEngine < matlab.mixin.SetGet
    %LaunchVehicleEngine Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stage LaunchVehicleStage
               
        bodyFrameThrustVect(3,1) double = [1;0;0]; %ND
        
        minThrottle(1,1) double = 0.0; %must be 0<=x<=1
        maxThrottle(1,1) double = 1.0; %must be 0<=x<=1
        
        fuelThrottleCurve FuelThrottleCurve
        thrustPressCurve ThrustPressureCurve
        ispPressCurve IspPressureCurve
        
        %EPS
        hasAlternator(1,1) logical = false;
        altPwrRate(1,1) double = 0;
        
        reqsElecCharge(1,1) logical = false;
        pwrUsageRate(1,1) double = 0;
        
        name char = 'Untitled Engine';
        id(1,1) double = 0;

        %mixtureFluidTypes/mixtureFractions Engine propellant mixture: each
        %entry pairs a TankFluidType with its share of the engine's total
        %mass flow (fractions must be > 0 and sum to 1).  EMPTY (default)
        %means "legacy single pool": no species split, every connected
        %non-empty tank shares the flow per connection priority/weight, so
        %missions saved before mixtures existed propagate identically.  Use
        %setMixture()/clearMixture() to write; getMixtureSpec() to read
        %(with the single-type default resolved).
        mixtureFluidTypes TankFluidType = TankFluidType.empty(1,0);
        mixtureFractions double = double.empty(1,0);
    end
    
    %deprecated
    properties
        vacThrust(1,1) double = 0     %kN
        vacIsp(1,1) double =    1E-6  %sec
        seaLvlThrust(1,1) double = 0  %kN
        seaLvlIsp(1,1) double = 1E-6  %sec
    end
    
    properties(Dependent)
        lvdData
    end
    
    properties(Constant)
        vacPress = 0;            %kPa
        seaLvlPress = 101.325;   %kPa
    end
    
    methods
        function obj = LaunchVehicleEngine(stage)
            if(nargin>0)
                obj.stage = stage;
                
                obj.fuelThrottleCurve = FuelThrottleCurve.getDefaultFuelThrottleCurve();
                obj.thrustPressCurve = ThrustPressureCurve.getDefaultThrustPressureCurve();
                obj.ispPressCurve = IspPressureCurve.getDefaultIspPressureCurve();
            end
            
            if(isempty(obj.fuelThrottleCurve))
                obj.fuelThrottleCurve = FuelThrottleCurve.getDefaultFuelThrottleCurve();
            end
            
            if(isempty(obj.thrustPressCurve))
                obj.thrustPressCurve = ThrustPressureCurve.getDefaultThrustPressureCurve();
            end
            
            if(isempty(obj.ispPressCurve))
                obj.ispPressCurve = IspPressureCurve.getDefaultIspPressureCurve();
            end
            
            obj.id = rand();
        end
        
        function lvdData = get.lvdData(obj)
            lvdData = obj.stage.launchVehicle.lvdData;
        end
        
        function val = getVacThrust(obj)
%             val = obj.vacThrust;
            [val, ~] = obj.getThrustIspForPressure(LaunchVehicleEngine.vacPress);
        end
        
        function val = getVacIsp(obj)
%             val = obj.vacIsp;
            [~, val] = obj.getThrustIspForPressure(LaunchVehicleEngine.vacPress);
        end
        
        function val = getSeaLvlThrust(obj)
%             val = obj.seaLvlThrust;
            [val, ~] = obj.getThrustIspForPressure(LaunchVehicleEngine.seaLvlPress);
        end
        
        function val = getSeaLvlIsp(obj)
%             val = obj.seaLvlIsp;
            [~, val] = obj.getThrustIspForPressure(LaunchVehicleEngine.seaLvlPress);
        end
        
        function val = getMinThrottle(obj)
            val = obj.minThrottle;
        end
        
        function val = getMaxThrottle(obj)
            val = obj.maxThrottle;
        end
        
        function engineSummStr = getEngineSummaryStr(obj)
            engineSummStr = {};
            
            engineSummStr{end+1} = sprintf('\t\t\t%s', obj.name);
            engineSummStr{end+1} = sprintf('\t\t\t\tVacuum Thrust = %.3f kN', obj.getVacThrust());
            engineSummStr{end+1} = sprintf('\t\t\t\tVacuum Isp = %.3f sec', obj.getVacIsp());
            engineSummStr{end+1} = sprintf('\t\t\t\tSea Level Thrust = %.3f kN', obj.getSeaLvlThrust());
            engineSummStr{end+1} = sprintf('\t\t\t\tSea Level Isp = %.3f sec', obj.getSeaLvlIsp());
            engineSummStr{end+1} = sprintf('\t\t\t\tThrottle Range: %.3f%% -> %.3f%%', 100*obj.minThrottle, 100*obj.maxThrottle);
            
            if(obj.hasAlternator)
                engineSummStr{end+1} = sprintf('\t\t\t\tAlternator Charge Rate = %.3f EC/s', obj.altPwrRate);
            end
            
            if(obj.reqsElecCharge)
                engineSummStr{end+1} = sprintf('\t\t\t\tElectric Engine Discharge Rate = %.3f EC/s', obj.pwrUsageRate);
            end
            
            lv = obj.lvdData.launchVehicle;
            conns = lv.getEngineToTankConnsForEngine(obj);
            engineSummStr{end+1} = sprintf('\t\t\t\tConnected Tanks:');
            if(~isempty(conns))
                tanks = LaunchVehicleTank.empty(1,0);
                for(i=1:length(conns))
                    tanks(end+1) = conns(i).tank; %#ok<AGROW>
                end    
                
                tanks = unique(tanks, 'stable');
                for(i=1:length(tanks)) %#ok<*NO4LP> 
                    engineSummStr{end+1} = sprintf('\t\t\t\t\t%s', tanks(i).name); %#ok<AGROW>
                end
            else
                engineSummStr{end+1} = sprintf('\t\t\t\t\tNo Tanks Connected');
            end            
        end
        
        function [thrust, isp] = getThrustIspForPressure(obj, presskPa)
            thrust = obj.thrustPressCurve.evalCurve(presskPa);
            thrust = max(thrust, 0);
            
            isp = obj.ispPressCurve.evalCurve(presskPa);
            isp = max(isp, 1E-6);
        end
        
        function [thrust, mdot] = getThrustFlowRateForPressure(obj, presskPa)
            [thrust, isp] = getThrustIspForPressure(obj, presskPa);
            
            mdot = -(thrust/(getG0() * isp)); %kN/(m/s/s * s) = kN/(m/s) = (1/1000) N / (m/s) = (1/1000) kg*m/s/s /(m/s) = (1/1000) kg/s = mT/s
        end
        
        function newThrottle = adjustThrottle(obj, inputThrottle, fuelRemainingPct)
            % if(inputThrottle < obj.minThrottle)
            %     newThrottle = obj.minThrottle;
            % elseif(inputThrottle > obj.maxThrottle)
            %     newThrottle = obj.maxThrottle;
            % else
            %     newThrottle = inputThrottle;
            % end
            newThrottle = min(max(inputThrottle, obj.minThrottle), obj.maxThrottle);
            
            if(not(isempty(fuelRemainingPct)))
                newThrottle = newThrottle * obj.fuelThrottleCurve.evalCurve(fuelRemainingPct);
            end
        end
        
        function tf = isInUse(obj)
            tf = obj.lvdData.usesEngine(obj);
        end

        function tf = hasCustomMixture(obj)
            %hasCustomMixture True once setMixture() has stored a mixture.
            %The mass-flow kernel branches on this: false takes the legacy
            %single-pool path, true the two-level mixture/priority split.
            tf = not(isempty(obj.mixtureFluidTypes));
        end

        function [types, fracs] = getMixtureSpec(obj)
            %getMixtureSpec Stored mixture, or the single-type default
            %(first fluid type at fraction 1) when none was set.
            if(obj.hasCustomMixture())
                types = obj.mixtureFluidTypes;
                fracs = obj.mixtureFractions;
            else
                types = obj.lvdData.launchVehicle.tankTypes.getTypeForInd(1);
                fracs = 1;
            end
        end

        function setMixture(obj, types, fracs)
            %setMixture Store a propellant mixture.  types is a
            %TankFluidType array, fracs a matching row of shares that must
            %be positive and sum to 1 within 1e-9.
            if(not(isa(types, 'TankFluidType')))
                error('LaunchVehicleEngine:invalidMixture', ...
                    'Mixture types must be TankFluidType objects.');
            end
            fracs = fracs(:)';
            if(numel(types) ~= numel(fracs) || isempty(types))
                error('LaunchVehicleEngine:invalidMixture', ...
                    'Mixture needs one fraction per fluid type (got %u types, %u fractions).', ...
                    numel(types), numel(fracs));
            end
            if(any(~isfinite(fracs)) || any(fracs <= 0))
                error('LaunchVehicleEngine:invalidMixture', ...
                    'Mixture fractions must be finite and positive.');
            end
            if(abs(sum(fracs) - 1) > 1e-9)
                error('LaunchVehicleEngine:invalidMixture', ...
                    'Mixture fractions must sum to 1 (got %.12g).', sum(fracs));
            end
            obj.mixtureFluidTypes = types;
            obj.mixtureFractions = fracs;
        end

        function clearMixture(obj)
            %clearMixture Drop back to the legacy single-pool behavior.
            obj.mixtureFluidTypes = TankFluidType.empty(1,0);
            obj.mixtureFractions = double.empty(1,0);
        end

        function frac = getMixtureFractionForFluidType(obj, fluidType)
            %getMixtureFractionForFluidType Share for one fluid type, or 0
            %when the (custom) mixture does not include it.
            frac = 0;
            if(obj.hasCustomMixture())
                bool = obj.mixtureFluidTypes == fluidType;
                if(any(bool))
                    frac = obj.mixtureFractions(find(bool, 1));
                end
            else
                frac = 1;
            end
        end
        
        function newEngine = copy(obj)
            newEngine = LaunchVehicleEngine(obj.stage);
            
            newEngine.vacThrust = obj.vacThrust;
            newEngine.vacIsp = obj.vacIsp;
            newEngine.seaLvlThrust = obj.seaLvlThrust;
            newEngine.seaLvlIsp = obj.seaLvlIsp;
            
            newEngine.bodyFrameThrustVect = obj.bodyFrameThrustVect;
            
            newEngine.minThrottle = obj.minThrottle;
            newEngine.maxThrottle = obj.maxThrottle;
            
            newEngine.fuelThrottleCurve = obj.fuelThrottleCurve.copy();
            newEngine.thrustPressCurve = obj.thrustPressCurve.copy();
            newEngine.ispPressCurve = obj.ispPressCurve.copy();

            newEngine.mixtureFluidTypes = obj.mixtureFluidTypes;
            newEngine.mixtureFractions = obj.mixtureFractions;
            
            newEngine.name = sprintf('Copy of %s', obj.name);
        end
        
        function pwrRate = getPowerRate(obj, throttle)
            pwrRate = 0;
            
            if(obj.hasAlternator)
                pwrRate = pwrRate + obj.altPwrRate * throttle;
            end
            
            if(obj.reqsElecCharge)
                pwrRate = pwrRate + obj.pwrUsageRate * throttle;
            end
        end
        
%         function tf = eq(A,B)
%             tf = [A.id] == [B.id];
%         end
    end
    
    methods(Static) 
        function obj = loadobj(obj)
            if(isempty(obj.fuelThrottleCurve))
                obj.fuelThrottleCurve = FuelThrottleCurve.getDefaultFuelThrottleCurve();
            end
            
            if(isempty(obj.thrustPressCurve))
                pressPts = [LaunchVehicleEngine.vacPress,LaunchVehicleEngine.seaLvlPress];
                thrustPts = [obj.vacThrust, obj.seaLvlThrust];
                obj.thrustPressCurve = ThrustPressureCurve.getCurveFromPoints(pressPts, thrustPts);
                
                obj.thrustPressCurve.sortElems();
                obj.thrustPressCurve.generateCurve();
            end
            
            if(isempty(obj.ispPressCurve))
                pressPts = [LaunchVehicleEngine.vacPress,LaunchVehicleEngine.seaLvlPress];
                ispPts = [obj.vacIsp, obj.seaLvlIsp];
                obj.ispPressCurve = IspPressureCurve.getCurveFromPoints(pressPts, ispPts);
                
                obj.ispPressCurve.sortElems();
                obj.ispPressCurve.generateCurve();
            end
        end
    end
end