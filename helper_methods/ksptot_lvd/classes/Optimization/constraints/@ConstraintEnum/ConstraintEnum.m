classdef ConstraintEnum < matlab.mixin.SetGet
    %ConstraintEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        UniversalTime('Universal Time','GenericMAConstraint','Universal Time')

        PosX('Position Vector (X)','GenericMAConstraint','Position Vector (X)')
        PosY('Position Vector (Y)','GenericMAConstraint','Position Vector (Y)')
        PosZ('Position Vector (Z)','GenericMAConstraint','Position Vector (Z)')
        VelX('Velocity Vector (X)','GenericMAConstraint','Velocity Vector (X)')
        VelY('Velocity Vector (Y)','GenericMAConstraint','Velocity Vector (Y)')
        VelZ('Velocity Vector (Z)','GenericMAConstraint','Velocity Vector (Z)')
        
        PosVectMag('Position Vector Magnitude','GenericMAConstraint','Position Vector Magnitude')
        VelVectMag('Velocity Vector Magnitude','GenericMAConstraint','Velocity Vector Magnitude')
        
        SMA('Semi-major Axis','GenericMAConstraint','Semi-major Axis')
        Ecc('Eccentricity','GenericMAConstraint','Eccentricity')
        Inc('Inclination','GenericMAConstraint','Inclination')
        RAAN('Right Asc. of the Asc. Node','GenericMAConstraint','Right Asc. of the Asc. Node')
        ArgPeri('Argument of Periapsis','GenericMAConstraint','Argument of Periapsis')
        TrueAnom('True Anomaly','GenericMAConstraint','True Anomaly')
        MeanAnom('Mean Anomaly','GenericMAConstraint','Mean Anomaly')
        OrbitPeriod('Orbital Period','GenericMAConstraint','Orbital Period')
        
        RadiusPeriapsis('Radius of Periapsis','GenericMAConstraint','Radius of Periapsis')
        RadiusApoapsis('Radius of Apoapsis','GenericMAConstraint','Radius of Apoapsis')
        AltitudeApoapsis('Altitude of Apoapsis','GenericMAConstraint','Altitude of Apoapsis')
        AltitudePeriapsis('Altitude of Periapsis','GenericMAConstraint','Altitude of Periapsis')
        
        H1('Equinoctial H1','GenericMAConstraint','Equinoctial H1')
        K1('Equinoctial K1','GenericMAConstraint','Equinoctial K1')
        H2('Equinoctial H2','GenericMAConstraint','Equinoctial H2')
        K2('Equinoctial K2','GenericMAConstraint','Equinoctial K2')
        
        FlightPathAngle('Flight Path Angle','GenericMAConstraint','Flight Path Angle');
        Longitude('Longitude (East)','GenericMAConstraint','Longitude (East)')
        Latitude('Latitude (North)','GenericMAConstraint','Latitude (North)')
        Altitude('Altitude','GenericMAConstraint','Altitude')
        VelAz('Velocity Azimuth','GenericMAConstraint','Velocity Azimuth')
        VelEl('Velocity Elevation','GenericMAConstraint','Velocity Elevation')
        LongitudeDriftRate('Longitudinal Drift Rate','GenericMAConstraint','Longitudinal Drift Rate')
        
        C3Energy('C3 Energy','GenericMAConstraint','C3 Energy');
        SecPastPeri('Seconds Past Periapsis','GenericMAConstraint','Seconds Past Periapsis');
        
        SurfaceVelocity('Surface Velocity','GenericMAConstraint','Surface Velocity')
        VerticalVel('Vertical Velocity','GenericMAConstraint','Vertical Velocity')
        
        HyperVelUnitX('Hyperbolic Velocity Unit Vector X','GenericMAConstraint','Hyperbolic Velocity Unit Vector X')
        HyperVelUnitY('Hyperbolic Velocity Unit Vector Y','GenericMAConstraint','Hyperbolic Velocity Unit Vector Y')
        HyperVelUnitZ('Hyperbolic Velocity Unit Vector Z','GenericMAConstraint','Hyperbolic Velocity Unit Vector Z')
        HyperVelRA('Hyperbolic Velocity Vector Right Ascension','GenericMAConstraint','Hyperbolic Velocity Vector Right Ascension')
        HyperVelDec('Hyperbolic Velocity Vector Declination','GenericMAConstraint','Hyperbolic Velocity Vector Declination')
        HyperVelMag('Hyperbolic Velocity Magnitude','GenericMAConstraint','Hyperbolic Velocity Magnitude')
        
        SolarBetaAngle('Solar Beta Angle','GenericMAConstraint','Solar Beta Angle')
        TotalScMass('Total Spacecraft Mass','GenericMAConstraint','Total Spacecraft Mass')        
        
        PitchAngle('Pitch Angle','PitchAngleConstraint',[]);
        RollAngle('Roll Angle','RollAngleConstraint',[]);
        YawAngle('Yaw Angle','YawAngleConstraint',[]);
        Throttle('Throttle','ThrottleConstraint',[]);
        
        BankAngle('Bank Angle','BankAngleConstraint',[]);
        AngleOfAttack('Angle of Attack','AngleOfAttackConstraint',[]);
        SideSlipAngle('Side Slip Angle','SideSlipAngleConstraint',[]);
        
        InertialAngleOfAttack('Inertial Angle of Attack','InertialAngleOfAttackConstraint',[]);
        InertialBankAngle('Inertial Bank Angle','InertialBankAngleConstraint',[]);
        InertialSideSlipAngle('Inertial Side Slip Angle','InertialSideSlipAngleConstraint',[]);
        
        TotalThrust('Total Thrust','TotalThrustConstraint',[]);
        
        StopwatchValue('Stopwatch Value','StopwatchValueConstraint',[]);
        ExtremumValue('Extremum Value','ExtremumValueConstraint',[]);
        
        TwoBodyImpactTime('Two-Body Time To Impact','TwoBodyImpactPointTime',[]);
        TwoBodyImpactLong('Two-Body Impact Longitude','TwoBodyImpactPointLongitude',[]);
        TwoBodyImpactLat('Two-Body Impact Latitude','TwoBodyImpactPointLatitude',[]);
        
        EventDeltaVExpended('Event Delta-V Expended','EventDeltaVExpendedConstraint',[]);
               
        CalculusCalculation('Calculus Calculation','CalculusCalculationValueConstraint',[]);
        
        CumulativePwrStorageStateOfCharge('Electrical Power Cumulative Storage State of Charge', 'CumPwrStorageStateOfChargeConstraint', []);
        
        GroundObjAz('Ground Object Azimuth', 'GroundObjAzConstraint', []);
        GroundObjEl('Ground Object Elevation', 'GroundObjElConstraint', []);
        GroundObjRng('Ground Object Range', 'GroundObjRangeConstraint', []);
        
        GeoVectorMagntide('Geometric Vector Magnitude', 'GeometricVectorMagConstraint', []);
        GeoAngleMagnitude('Geometric Angle Magnitude', 'GeometricAngleMagConstraint', []);
        
        TankMass('Tank Mass', 'TankMassConstraint', []);
        TankMassFlowRate('Tank Mass Flow Rate', 'TankMassFlowRateConstraint', []);
    end
    
    enumeration(Hidden)
        BodyCentricPositionX('Body-centric Position (X)','GenericMAConstraint','Body-centric Position (X)')
        BodyCentricPositionY('Body-centric Position (Y)','GenericMAConstraint','Body-centric Position (Y)')
        BodyCentricPositionZ('Body-centric Position (Z)','GenericMAConstraint','Body-centric Position (Z)')
        BodyCentricVelocityX('Body-centric Velocity (X)','GenericMAConstraint','Body-centric Velocity (X)')
        BodyCentricVelocityY('Body-centric Velocity (Y)','GenericMAConstraint','Body-centric Velocity (Y)')
        BodyCentricVelocityZ('Body-centric Velocity (Z)','GenericMAConstraint','Body-centric Velocity (Z)')
        SunCentricPositionX('Sun-centric Position (X)','GenericMAConstraint','Sun-centric Position (X)')
        SunCentricPositionY('Sun-centric Position (Y)','GenericMAConstraint','Sun-centric Position (Y)')
        SunCentricpositionZ('Sun-centric Position (Z)','GenericMAConstraint','Sun-centric Position (Z)')
        
        RadiusSpacecraft('Radius of Spacecraft','GenericMAConstraint','Radius of Spacecraft')
        SpeedOfSpacecraft('Speed of Spacecraft','GenericMAConstraint','Speed of Spacecraft')
        
        DistToRefCelBody('Distance to Ref. Celestial Body','GenericMAConstraint','Distance to Ref. Celestial Body')
        
        CentralBodyId('Central Body ID','GenericMAConstraint','Central Body ID')
        FuelOxMass('Liquid Fuel/Ox Mass','GenericMAConstraint','Liquid Fuel/Ox Mass')
        MonopropMass('Monopropellant Mass','GenericMAConstraint','Monopropellant Mass')
        XenonMass('Xenon Mass','GenericMAConstraint','Xenon Mass') 
        
        TimeContinuity('Time Continuity','TimeContinuityConstraint',[]);
        PositionContinuityX('Position Continuity (X)','PositionContinuityConstraintX',[]);
        PositionContinuityY('Position Continuity (Y)','PositionContinuityConstraintY',[]);
        PositionContinuityZ('Position Continuity (Z)','PositionContinuityConstraintZ',[]);
        VelocityContinuityX('Velocity Continuity (X)','VelocityContinuityConstraintX',[]);
        VelocityContinuityY('Velocity Continuity (Y)','VelocityContinuityConstraintY',[]);
        VelocityContinuityZ('Velocity Continuity (Z)','VelocityContinuityConstraintZ',[]);
    end
    
    properties
        name char = '';
        class char = '';
        constructorInput1
    end
    
    methods
        function obj = ConstraintEnum(name, class, constructorInput1)
            obj.name = name;
            obj.class = class;
            obj.constructorInput1 = constructorInput1;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('ConstraintEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('ConstraintEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
    end
end

