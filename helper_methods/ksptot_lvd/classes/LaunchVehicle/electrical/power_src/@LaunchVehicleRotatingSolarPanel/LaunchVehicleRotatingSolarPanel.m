classdef LaunchVehicleRotatingSolarPanel < AbstractLaunchVehicleSolarPanel
    %LaunchVehicleRotatingSolarPanel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stage LaunchVehicleStage
        
        name(1,:) char  = 'Untitled Rotating Solar Panel';
        
        bodyFrameRotAxis(3,1) double = [0;1;0];
        refChargeRate(1,1) double = 0;
        refChargeRateDist(1,1) = 13599840.256;
        
        id = rand();
    end
    
    methods            
        function obj = LaunchVehicleRotatingSolarPanel(stage)
            obj.stage = stage;
            
            obj.id = rand();
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function stage = getAttachedStage(obj)
            stage = obj.stage;
        end
        
        function srcState = createDefaultInitialState(obj, stageState)
            srcState = LaunchVehicleRotatingSolarPanelState(stageState, obj);
        end
        
        function useTF = openEditDialog(obj)
            useTF = lvd_EditRotatingSolarPanelGUI(obj);
        end
        
        function tf = isInUse(obj)
            tf = false;
        end
        
        function newPowerSrc = copy(obj)
            newPowerSrc = LaunchVehicleRotatingSolarPanel(obj.stage);
            newPowerSrc.bodyFrameRotAxis = obj.bodyFrameRotAxis;
            newPowerSrc.refChargeRate = obj.refChargeRate;
            newPowerSrc.refChargeRateDist = obj.refChargeRateDist;
            
            newPowerSrc.name = sprintf('Copy of %s', obj.name);
        end
        
        function summStr = getSummaryStr(obj)
            summStr = {};
            
            summStr{end+1} = sprintf('\t\t\t%s', obj.name);
            summStr{end+1} = sprintf('\t\t\t\tRef. Charge Rate = %.3f EC/s', obj.refChargeRate);
            summStr{end+1} = sprintf('\t\t\t\tRef. Distance = %.3f km', obj.refChargeRateDist);
            summStr{end+1} = sprintf('\t\t\t\tRotation Axis = [%.3f, %.3f, %.3f]', obj.bodyFrameRotAxis(1), obj.bodyFrameRotAxis(2), obj.bodyFrameRotAxis(3));
        end
        
        function bodyFrameNormVect = getBodyFrameSolarPanelNormalVector(obj, elemSet, steeringModel, body2InertDcm, elemSetSun)
            %Get sun position relative to spacecraft
%             elemSet = elemSet.convertToCartesianElementSet();
%             bodyInfo = elemSet.frame.getOriginBody();
%             celBodyData = bodyInfo.celBodyData;

%             sunBodyInfo = getTopLevelCentralBody(celBodyData);
%             sunBodyInfo = celBodyData.getTopLevelBody();
%             sunInertFrame = sunBodyInfo.getBodyCenteredInertialFrame();
            
%             elemSetSun = elemSet.convertToFrame(sunInertFrame);
            
            rVectSun2Spacecraft = elemSetSun.rVect(:);
            rVectSpacecraft2Sun = -rVectSun2Spacecraft;
            rVectSpacecraft2SunHat = normVector(rVectSpacecraft2Sun);

            %get panel rotation axis inertially
            panelInertialFrameAxesRotVect = obj.getInertialFrameRotAxis(body2InertDcm);

            %Get body frame normal vector of panel
            rSpacecraft2SunProj = rVectSpacecraft2SunHat - (dotARH(rVectSpacecraft2SunHat, panelInertialFrameAxesRotVect)/norm(panelInertialFrameAxesRotVect)^2) * panelInertialFrameAxesRotVect;
            bodyFrameNormVect = body2InertDcm' * rSpacecraft2SunProj;
        end
        
        function [panelInertialFrameAxesRotVect] = getInertialFrameRotAxis(obj, body2InertDcm)
%             elemSet = elemSet.convertToCartesianElementSet();
%             bodyInfo = elemSet.frame.getOriginBody();
            
%             body2InertDcm = steeringModel.getBody2InertialDcmAtTime(elemSet.time, elemSet.rVect(:), elemSet.vVect(:), bodyInfo);
            panelInertialFrameAxesRotVect = body2InertDcm * obj.bodyFrameRotAxis;
        end
        
        function refChargeRate = getRefChargeRate(obj)
            refChargeRate = obj.refChargeRate;
        end
        
        function refChargeRateDist = getRefChargeRateDist(obj)
            refChargeRateDist = obj.refChargeRateDist;
        end
    end
end