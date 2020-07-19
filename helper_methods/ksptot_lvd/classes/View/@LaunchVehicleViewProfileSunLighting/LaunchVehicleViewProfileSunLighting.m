classdef LaunchVehicleViewProfileSunLighting < matlab.mixin.SetGet
    %LaunchVehicleViewProfileSunLighting Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        dAxes matlab.graphics.axis.Axes
        viewInFrame AbstractReferenceFrame
        hLight(1,:) matlab.graphics.primitive.Light = matlab.graphics.primitive.Light.empty(1,0);
        hSunVectArrow = matlab.graphics.GraphicsPlaceholder.empty(1,0)
    end
    
    methods
        function obj = LaunchVehicleViewProfileSunLighting(dAxes, viewInFrame, showLighting, showSunVect)
            obj.dAxes = dAxes;
            obj.viewInFrame = viewInFrame;
            
            obj.hLight = light(dAxes, 'Style','infinite');
            if(showLighting)
                obj.hLight.Visible = 'on';
            else
                obj.hLight.Visible = 'off';
            end
            
            obj.hSunVectArrow = quiver3(0,0,0,1,1,1, 'Color',[204,204,0]/255, 'LineWidth',2);
            if(showSunVect)
                obj.hSunVectArrow.Visible = 'on';
            else
                obj.hSunVectArrow.Visible = 'off';
            end
        end
        
        function updateSunLightingPosition(obj, time)
            bodyInfo = obj.viewInFrame.getOriginBody();
            rVectBodyToSun = -1.0 * getPositOfBodyWRTSun(time, bodyInfo, bodyInfo.celBodyData);
            
            ce = CartesianElementSet(time, rVectBodyToSun, [0;0;0], bodyInfo.getBodyCenteredInertialFrame());
            ce = ce.convertToFrame(obj.viewInFrame);
            rVectBodyToSun = ce.rVect;
            
            if(not(isempty(obj.hLight)) && isvalid(obj.hLight) && isa(obj.hLight, 'matlab.graphics.primitive.Light'))
                obj.hLight.Position = reshape(rVectBodyToSun,1,3);
            end
            
            if(not(isempty(obj.hSunVectArrow)) && isvalid(obj.hSunVectArrow))
                sunUnitVect = normVector(rVectBodyToSun);
                sunVectToPlot = 2 * bodyInfo.radius * sunUnitVect;
                
                obj.hSunVectArrow.UData = sunVectToPlot(1);
                obj.hSunVectArrow.VData = sunVectToPlot(2);
                obj.hSunVectArrow.WData = sunVectToPlot(3);
            end
        end
    end
end

