classdef SphericalSolarRadiationPressureModel < AbstractSolarRadiationPressureModel
    %SphericalSolarRadiationPressureModel Summary of this class goes here
    %   Detailed explanation goes here

    properties
        refSolarFlux(1,1) double {mustBeGreaterThanOrEqual(refSolarFlux,0)} = 1367; %W/m^2
        solarFluxRefDist(1,1) double {mustBeGreaterThanOrEqual(solarFluxRefDist,0)}= 13599840.256; %km
                
        cR(1,1) double {mustBeGreaterThanOrEqual(cR, 0), mustBeLessThanOrEqual(cR,2)} = 1; %reflectivity coefficient
        area(1,1) double {mustBeGreaterThanOrEqual(area,0)} = 1; %m^2
    end

    properties(Constant)
        enum = SolarRadPressModelEnum.Spherical;
    end

    methods
        function obj = SphericalSolarRadiationPressureModel(solarFlux, solarFluxRefDist, cR, area)
            arguments
                solarFlux(1,1) double = 1367;
                solarFluxRefDist(1,1) double = 13599840.256;
                cR(1,1) double = 1;
                area(1,1) double = 1;
            end

            obj.refSolarFlux = solarFlux;
            obj.solarFluxRefDist = solarFluxRefDist;
            obj.cR = cR;
            obj.area = area;
        end

        function fSR = getSolarRadiationForce(obj, elemSet, steeringModel)
            arguments
                obj(1,1) SphericalSolarRadiationPressureModel
                elemSet(1,1) AbstractElementSet
                steeringModel(1,1) AbstractSteeringModel
            end

            bodyInfo = elemSet.frame.getOriginBody();
            [hasSunLoS, ~, elemSetSun] = AbstractLaunchVehicleSolarPanel.getExpensiveSolarPanelInputs(elemSet, bodyInfo, steeringModel);

            if(hasSunLoS)
                %Get vectors related to sun and spacecraft
                ce = elemSetSun.convertToCartesianElementSet();
                rSun2Sc = ce.rVect;                    % km
                rSun2ScNormMeter = norm(rSun2Sc)*1000; % m
                rSun2ScHat = normVector(rSun2Sc);
                
                %Compute solar pressure, pSF
                sunPower = 4*pi * (obj.solarFluxRefDist*1000)^2 * obj.refSolarFlux; % watts
                solarFlux = sunPower / (4*pi*rSun2ScNormMeter^2); % watt/m^2
                pSF = solarFlux / (obj.c); %watt/m^2 / (m/s) = W*s/m^3 = N/m^2

                %Compute solar radiation force
                fSR = pSF * obj.cR * obj.area * rSun2ScHat; %N/m^2 * [] * m^2 * [] = N, Vallado Eq 8-43

                %Convert units, all forces are returned in units of mT*km/s^2
                fSR = fSR/(1000^2); % N * (1 mT/1000 kg) * (1 km / 1000 m) = kg*m/s^2 * (mT/kg) * (km/m) = mT*km/s^2

                %Do frame rotation to convert sun-relative force to
                %body-relative force
                sunif = bodyInfo.celBodyData.getTopLevelBody().getBodyCenteredInertialFrame();
                bci = bodyInfo.getBodyCenteredInertialFrame();
        
                ut = elemSet.time;
                R_sunif_to_global_inertial = sunif.getRotMatToInertialAtTime(ut,[],[]);
                R_bci_to_global_inertial = bci.getRotMatToInertialAtTime(ut,[],[]);
                R_sunif_to_bci = R_bci_to_global_inertial' * R_sunif_to_global_inertial;
        
                fSR = R_sunif_to_bci * fSR;
                    
            else
                fSR = [0;0;0];
            end
        end

        function openEditDialog(obj, lvdData)
            arguments   
                obj(1,1) SphericalSolarRadiationPressureModel
                lvdData(1,1) LvdData
            end
            
            out = AppDesignerGUIOutput({false});
            lvd_EditSphericalSolarRadPressModel_App(obj, out);
        end
    end
end