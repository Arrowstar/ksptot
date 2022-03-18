classdef LaunchVehicleViewProfileBodyAxesData < matlab.mixin.SetGet
    %LaunchVehicleViewProfileTrajectoryData Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %         timesArr(1,:) cell = {};
        %         xPosInterps(1,:) cell = {};
        %         yPosInterps(1,:) cell = {};
        %         zPosInterps(1,:) cell = {};
        %
        %         dcm11Interps(1,:) cell = {};
        %         dcm21Interps(1,:) cell = {};
        %         dcm31Interps(1,:) cell = {};
        %
        %         dcm12Interps(1,:) cell = {};
        %         dcm22Interps(1,:) cell = {};
        %         dcm32Interps(1,:) cell = {};
        %
        %         dcm13Interps(1,:) cell = {};
        %         dcm23Interps(1,:) cell = {};
        %         dcm33Interps(1,:) cell = {};
        
        vehPosVelData LaunchVehicleViewPosVelInterp
        vehAttData LaunchVehicleViewProfileAttitudeData
        
        scale(1,1) double = 100;
        markerPlot(1,:) cell = {}
        
        showScBodyAxes(1,1) logical = false;
    end
    
    methods
        function obj = LaunchVehicleViewProfileBodyAxesData(vehPosVelData, vehAttData, scale, showScBodyAxes)
            obj.vehPosVelData = vehPosVelData;
            obj.vehAttData = vehAttData;
            obj.scale = scale;
            obj.showScBodyAxes = showScBodyAxes;
        end
        
        %         function addData(obj, times, rVects, rotMatsBodyToView)
        %             obj.timesArr(end+1) = {times};
        %
        %             if(length(times) >= 3)
        %                 method = 'spline';
        %             else
        %                 method = 'linear';
        %             end
        %
        %             obj.xPosInterps{end+1} = griddedInterpolant(times, rVects(1,:), method, 'linear');
        %             obj.yPosInterps{end+1} = griddedInterpolant(times, rVects(2,:), method, 'linear');
        %             obj.zPosInterps{end+1} = griddedInterpolant(times, rVects(3,:), method, 'linear');
        %
        %             obj.dcm11Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(1,1,:),1,length(times)), method, 'linear');
        %             obj.dcm21Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(2,1,:),1,length(times)), method, 'linear');
        %             obj.dcm31Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(3,1,:),1,length(times)), method, 'linear');
        %
        %             obj.dcm12Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(1,2,:),1,length(times)), method, 'linear');
        %             obj.dcm22Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(2,2,:),1,length(times)), method, 'linear');
        %             obj.dcm32Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(3,2,:),1,length(times)), method, 'linear');
        %
        %             obj.dcm13Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(1,3,:),1,length(times)), method, 'linear');
        %             obj.dcm23Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(2,3,:),1,length(times)), method, 'linear');
        %             obj.dcm33Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(3,3,:),1,length(times)), method, 'linear');
        %
        %             obj.markerPlot{end+1} = [];
        %         end
        
        function plotBodyAxesAtTime(obj, time, hAx)
            if(obj.showScBodyAxes)
                [rVect, ~] = obj.vehPosVelData.getPositionVelocityAtTime(time);
                dcmAll = obj.vehAttData.getDCMatTime(time);
                
                if(numel(obj.markerPlot) < width(rVect))
                    for(i=numel(obj.markerPlot)+1 : width(rVect))
                        obj.markerPlot{end+1} = [];
                    end
                end
                
                for(i=1:width(rVect))
                    pos = rVect(:,i);
                    dcm = dcmAll(:,:,i);
                    
                    if(not(isempty(obj.markerPlot{i})) && isvalid(obj.markerPlot{i}) && isa(obj.markerPlot{i}, 'matlab.graphics.primitive.Transform'))
                        axang = rotm2axangARH(dcm);
                        
                        M = makehgtform('translate',pos, 'axisrotate',axang(1:3),axang(4));
                        set(obj.markerPlot{i},'Matrix',M);
                        obj.markerPlot{i}.Visible = 'on';
                    else
                        hold(hAx,'on');
                        obj.markerPlot{i} = hgtransform('Parent', hAx);
                        
                        xAxis = quiver3(hAx, 0,0,0,obj.scale,0,0, 'Color','r', 'LineWidth',2);
                        set(xAxis,'Parent',obj.markerPlot{i});
                        
                        yAxis = quiver3(hAx, 0,0,0,0,obj.scale,0, 'Color','g', 'LineWidth',2);
                        set(yAxis,'Parent',obj.markerPlot{i});
                        
                        zAxis = quiver3(hAx, 0,0,0,0,0,obj.scale, 'Color','b', 'LineWidth',2);
                        set(zAxis,'Parent',obj.markerPlot{i});
                        
                        axang = rotm2axangARH(dcm);
                        
                        M = makehgtform('translate',pos, 'axisrotate',axang(1:3),axang(4));
                        set(obj.markerPlot{i},'Matrix',M);
                        obj.markerPlot{i}.Visible = 'on';
                        
                        hold(hAx,'off');
                    end
                end
                
                for(i=width(rVect)+1:numel(obj.markerPlot))
                    if(not(isempty(obj.markerPlot{i})) && isvalid(obj.markerPlot{i}) && isa(obj.markerPlot{i}, 'matlab.graphics.primitive.Transform'))
                        obj.markerPlot{i}.Visible = 'off';
                    end
                end
            end
        end
    end
end