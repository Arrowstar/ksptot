classdef(Abstract) AbstractLaunchVehicleSolarPanel < AbstractLaunchVehicleElectricalPowerSrcSnk
    %AbstractLaunchVehicleSolarPanel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods        
        function pwrRate = getElectricalPwrRate(obj, elemSet, steeringModel, hasSunLoS, body2InertDcm, elemSetSun)
            elemSet = elemSet.convertToCartesianElementSet();
            bodyInfo = elemSet.frame.getOriginBody();
%             celBodyData = bodyInfo.celBodyData;

%             sunBodyInfo = getTopLevelCentralBody(celBodyData);
%             sunBodyInfo = celBodyData.getTopLevelBody();
            
            if(isempty(hasSunLoS) || isempty(body2InertDcm) || isempty(elemSetSun))
                [hasSunLoS, body2InertDcm, elemSetSun] = AbstractLaunchVehicleSolarPanel.getExpensiveSolarPanelInputs(elemSet, bodyInfo, steeringModel);
%                 hasSunLoS = true;
%                 eclipseBodies = [bodyInfo, bodyInfo.getParBodyInfo(), bodyInfo.getChildrenBodyInfo()];
%                 for(i=1:length(eclipseBodies))
%                     eclipseBodyInfo = eclipseBodies(i);
% 
%                     if(eclipseBodyInfo == sunBodyInfo)
%                         continue;
%                     end
% 
%                     stateLogEntry = [elemSet.time, elemSet.rVect(:)'];
%                     LoS = LoS2Target(stateLogEntry, bodyInfo, eclipseBodyInfo, sunBodyInfo, celBodyData, []);
%                     if(LoS == 0)
%                         hasSunLoS = false;
%                         break;
%                     end
%                 end
            end
            
            if(hasSunLoS)
%                 body2InertDcm = steeringModel.getBody2InertialDcmAtTime(elemSet.time, elemSet.rVect(:), elemSet.vVect(:), bodyInfo);
                panelBodyFrameNormalVect = obj.getBodyFrameSolarPanelNormalVector(elemSet, steeringModel, body2InertDcm, elemSetSun);
                panelInertialFrameNormalVect = body2InertDcm * panelBodyFrameNormalVect(:);

                if(norm(panelInertialFrameNormalVect) > 1E-10 && norm(panelBodyFrameNormalVect) > 1E-10)
%                     sunInertFrame = sunBodyInfo.getBodyCenteredInertialFrame();
%                     elemSetSun = elemSet.convertToFrame(sunInertFrame);

                    rVectSun2Spacecraft = elemSetSun.rVect(:);
                    rVectSpacecraft2Sun = -rVectSun2Spacecraft;
                    
                    panelIncidAngle = angleNegPiToPi(dang(rVectSpacecraft2Sun,panelInertialFrameNormalVect));

                    if(panelIncidAngle > pi/2 || panelIncidAngle < -pi/2)
                        pwrRate = 0;

                    else
                        ec_rate_ref = obj.getRefChargeRate();
                        r_ref = obj.getRefChargeRateDist();
                        r = norm(rVectSpacecraft2Sun);

                        pwrRate = ec_rate_ref * 1/(r/r_ref)^2 * cos(panelIncidAngle);
                    end
                else
                    pwrRate = 0;
                end
            else
                pwrRate = 0;
            end
        end
        
        panelNormalVect = getBodyFrameSolarPanelNormalVector(obj, elemSet, steeringModel);
        
        refChargeRate = getRefChargeRate(obj)
        
        refChargeRateDist = getRefChargeRateDist(obj)
    end
    
    methods(Static)
        function [hasSunLoS, body2InertDcm, elemSetSun] = getExpensiveSolarPanelInputs(elemSet, bodyInfo, steeringModel)
            celBodyData = bodyInfo.celBodyData;
            sunBodyInfo = celBodyData.getTopLevelBody();
            
            sunInertFrame = sunBodyInfo.getBodyCenteredInertialFrame();
            elemSetSun = elemSet.convertToFrame(sunInertFrame);

            hasSunLoS = true;
            eclipseBodies = [bodyInfo, bodyInfo.getParBodyInfo(), bodyInfo.getChildrenBodyInfo()];
            for(i=1:length(eclipseBodies))
                eclipseBodyInfo = eclipseBodies(i);

                if(eclipseBodyInfo == sunBodyInfo)
                    continue;
                end

                stateLogEntry = [elemSet.time, elemSet.rVect(:)'];
                LoS = LoS2Target(stateLogEntry, bodyInfo, eclipseBodyInfo, sunBodyInfo, celBodyData, [], elemSetSun);
                if(LoS == 0)
                    hasSunLoS = false;
                    break;
                end
            end

            body2InertDcm = steeringModel.getBody2InertialDcmAtTime(elemSet.time, elemSet.rVect(:), elemSet.vVect(:), bodyInfo);
        end
    end
end