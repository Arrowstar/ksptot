classdef SolarSailSolarRadiationPressureModel < AbstractSolarRadiationPressureModel
    %SolarSailSolarRadiationPressureModel Summary of this class goes here
    %   Detailed explanation goes here

    properties
        refSolarFlux(1,1) double = 1367; %W/m^2
        solarFluxRefDist(1,1) double = 13599840.256; %km
                
        cRa(1,1) double {mustBeGreaterThanOrEqual(cRa, 0), mustBeLessThanOrEqual(cRa,1)} = 0.10; %reflectivity coefficient (Absorption)
        cRs(1,1) double {mustBeGreaterThanOrEqual(cRs, 0), mustBeLessThanOrEqual(cRs,1)} = 0.85; %reflectivity coefficient (Speculative Reflection)
        cRd(1,1) double {mustBeGreaterThanOrEqual(cRd, 0), mustBeLessThanOrEqual(cRd,1)} = 0.05; %reflectivity coefficient (Diffuse Reflection)

        area(1,1) double {mustBeGreaterThan(area,0)} = 1; %m^2
        areaBodyFrameNormVector(3,1) double = [1;0;0];
    end

    properties(Constant)
        enum = SolarRadPressModelEnum.SolarSail;
    end

    methods
        function obj = SolarSailSolarRadiationPressureModel(solarFlux, solarFluxRefDist, cRa, cRs, cRd, area, areaBodyFrameNormVector)
            arguments
                solarFlux(1,1) double = 1367;
                solarFluxRefDist(1,1) double = 13599840.256;
                cRa(1,1) double = 0.10;
                cRs(1,1) double = 0.85;
                cRd(1,1) double = 0.05;
                area(1,1) double = 1;
                areaBodyFrameNormVector(3,1) double = [1;0;0];
            end
            
            obj.refSolarFlux = solarFlux;
            obj.solarFluxRefDist = solarFluxRefDist;
            obj.cRa = cRa;
            obj.cRs = cRs;
            obj.cRd = cRd;
            obj.area = area;
            obj.areaBodyFrameNormVector = areaBodyFrameNormVector;
        end

        function fSR = getSolarRadiationForce(obj, elemSet, steeringModel)
            arguments
                obj(1,1) SolarSailSolarRadiationPressureModel
                elemSet(1,1) AbstractElementSet
                steeringModel(1,1) AbstractSteeringModel
            end

            bodyInfo = elemSet.frame.getOriginBody();
            [hasSunLoS, body2InertDcm, elemSetSun] = AbstractLaunchVehicleSolarPanel.getExpensiveSolarPanelInputs(elemSet, bodyInfo, steeringModel);

            if(hasSunLoS)
                %Get vectors related to sun and spacecraft
                ce = elemSetSun.convertToCartesianElementSet();
                rSun2Sc = ce.rVect;                    % km
                rSun2ScNormMeter = norm(rSun2Sc)*1000; % m
                rSun2ScHat = normVector(rSun2Sc);
                
                %Get vectors and angles related to vehicle pointing from Vallado
                sHat = -rSun2ScHat;                                 %See Vallado Figure 8-18
                nHat = body2InertDcm * obj.areaBodyFrameNormVector; %See Vallado Figure 8-18
                incidenceAngle = abs(dang(sHat, nHat)); % <---should there be an abs() around this?
                if(incidenceAngle > pi/2) %The normal always needs to be facing the sun for this to work, so incidence angle must be less than 90 deg
                    nHat = -nHat;
                    incidenceAngle = dang(sHat, nHat);
                end

                %Compute solar pressure, pSF
                sunPower = 4*pi * (obj.solarFluxRefDist*1000)^2 * obj.refSolarFlux; % watts
                solarFlux = sunPower / (4*pi*rSun2ScNormMeter^2); % watt/m^2
                pSF = solarFlux / obj.c; %watt/m^2 / (m/s) = W*s/m^3 = N/m^2

                %Compute solar radiation forces, right before Vallado Equation 8-44
                fSRa = -pSF * obj.cRa * obj.area * cos(incidenceAngle) * sHat;                % absorption force, N/m^2 * [] * m^2 * [] = N
                fSRs = -2* pSF * obj.cRs * obj.area * cos(incidenceAngle)^2 * nHat;           % speculative reflection force, N/m^2 * [] * m^2 * [] = N
                fSRd = -pSF * obj.cRd * obj.area * cos(incidenceAngle) * ((2/3)*nHat + sHat); % diffuse reflection force, N/m^2 * [] * m^2 * [] = N
                fSR = fSRa + fSRs + fSRd;   %sum forces, N              

                %Convert units, all forces are returned in units of mT*km/s^2
                fSR = fSR/(1000^2); % N * (1 mT/1000 kg) * (1 km / 1000 m) = kg*m/s^2 * (mT/kg) * (km/m) = mT*km/s^2

                %Do frame rotation to convert sun-relative force to
                %body-relative force
                sunif = bodyInfo.celBodyData.getTopLevelBody().getBodyCenteredInertialFrame();
                bci = bodyInfo.getBodyCenteredInertialFrame();
        
                ut = elemSet.time;
                R_sunif_to_global_inertial = sunif.getRotMatToInertialAtTime(ut,[],[]);
                R_bci_to_global_inertial = bci.getRotMatToInertialAtTime(ut,[],[]);
                R_sunif_to_bci = R_bci_to_global_inertial' * R_sunif_to_global_inertial; %<-- Sun inertial frame to central body inertial frame
        
                fSR = R_sunif_to_bci * fSR;

            else
                fSR = [0;0;0];
            end
        end

        function openEditDialog(obj, lvdData)
            arguments   
                obj(1,1) SolarSailSolarRadiationPressureModel
                lvdData(1,1) LvdData
            end
            
            out = AppDesignerGUIOutput({false});
            lvd_EditSolarSailSolarRadPressModel_App(obj, out);
        end
    end
end