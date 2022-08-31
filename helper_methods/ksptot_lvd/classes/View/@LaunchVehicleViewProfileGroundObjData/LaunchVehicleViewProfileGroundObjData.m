classdef LaunchVehicleViewProfileGroundObjData < matlab.mixin.SetGet
    %LaunchVehicleViewProfileGroundObjData Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        groundObj LaunchVehicleGroundObject
        celBodyData CelestialBodyData
        
        timesArr(1,:) cell = {};
        xInterps(1,:) cell = {};
        yInterps(1,:) cell = {};
        zInterps(1,:) cell = {};
%         xInterpsSc(1,:) cell = {};
%         yInterpsSc(1,:) cell = {};
%         zInterpsSc(1,:) cell = {};

        vehPosVelData LaunchVehicleViewPosVelInterp
        
        viewFrames(1,:) AbstractReferenceFrame
        showGrdObjLoS(1,:) logical
        
        markerPlot(1,:) cell = {}
        losMarkerPlot(1,:) cell = {};
    end
    
    methods
        function obj = LaunchVehicleViewProfileGroundObjData(groundObj, vehPosVelData, celBodyData)
            obj.groundObj = groundObj;
            obj.vehPosVelData = vehPosVelData;
            obj.celBodyData = celBodyData;
        end
        
        function addData(obj, times, rVectsGrdObj, viewInFrame, showGrdObjLoS)
            obj.timesArr(end+1) = {times};
            
            obj.xInterps{end+1} = griddedInterpolant(times, rVectsGrdObj(1,:), 'spline', 'linear');
            obj.yInterps{end+1} = griddedInterpolant(times, rVectsGrdObj(2,:), 'spline', 'linear');
            obj.zInterps{end+1} = griddedInterpolant(times, rVectsGrdObj(3,:), 'spline', 'linear');
            
%             obj.xInterpsSc{end+1} = griddedInterpolant(times, rVectsSc(1,:), 'spline', 'linear');
%             obj.yInterpsSc{end+1} = griddedInterpolant(times, rVectsSc(2,:), 'spline', 'linear');
%             obj.zInterpsSc{end+1} = griddedInterpolant(times, rVectsSc(3,:), 'spline', 'linear');
            
            obj.viewFrames(end+1) = viewInFrame;
            obj.showGrdObjLoS(end+1) = showGrdObjLoS;
            
            obj.markerPlot{end+1} = [];
            obj.losMarkerPlot{end+1} = [];
        end
        
        function plotBodyMarkerAtTime(obj, time, hAx)
            [rVect, ~] = obj.vehPosVelData.getPositionVelocityAtTime(time);
            rVectInd = 1;
            
            for(i=1:length(obj.timesArr))
                times = obj.timesArr{i};
                
                if(time >= min(floor(times)) && time <= max(ceil(times)))
                    xInterp = obj.xInterps{i};
                    xGrd = xInterp(time);
                    
                    yInterp = obj.yInterps{i};
                    yGrd = yInterp(time);
                    
                    zInterp = obj.zInterps{i};
                    zGrd = zInterp(time);
                    
                    if(not(isempty(obj.markerPlot{i})) && isvalid(obj.markerPlot{i}) && isa(obj.markerPlot{i}, 'matlab.graphics.primitive.Transform'))
                        M = makehgtform('translate',[xGrd,yGrd,zGrd]);
                        set(obj.markerPlot{i},'Matrix',M);
                        obj.markerPlot{i}.Visible = 'on';
                        
                    else
                        hold(hAx,'on');
                        obj.markerPlot{i} = hgtransform('Parent', hAx);
                        hBM = plot3(hAx, 0,0,0, 'MarkerEdgeColor','k', 'Marker',obj.groundObj.markerShape.shape, 'MarkerFaceColor',obj.groundObj.markerColor.color);
                        set(hBM,'Parent',obj.markerPlot{i});
                        
                        M = makehgtform('translate',[xGrd,yGrd,zGrd]);
                        set(obj.markerPlot{i},'Matrix',M);
                        obj.markerPlot{i}.Visible = 'on';
                        
                        hold(hAx,'off');
                    end
                    
                    if(obj.showGrdObjLoS(i))
%                         xInterp = obj.xInterpsSc{i};
%                         xSc = xInterp(time);
%                         
%                         yInterp = obj.yInterpsSc{i};
%                         ySc = yInterp(time);
%                         
%                         zInterp = obj.zInterpsSc{i};
%                         zSc = zInterp(time);
                        
                        xSc = rVect(1, rVectInd);
                        ySc = rVect(2, rVectInd);
                        zSc = rVect(3, rVectInd);
                        rVectInd = rVectInd + 1;

                        if(not(isempty(obj.losMarkerPlot{i})) && isvalid(obj.losMarkerPlot{i})) % && isa(obj.markerPlot{i}, 'matlab.graphics.primitive.Transform')
                            obj.losMarkerPlot{i}.XData = [xGrd xSc];
                            obj.losMarkerPlot{i}.YData = [yGrd ySc];
                            obj.losMarkerPlot{i}.ZData = [zGrd zSc];
                        else
                            hold(hAx,'on');
                            hLoS = plot3(hAx, [xGrd xSc], [yGrd ySc], [zGrd zSc], 'g-');
                            obj.losMarkerPlot{i} = hLoS;
                            
                            hold(hAx,'off');
                        end
                        
                        scFrame = obj.viewFrames(i);
                        bodyInfo = scFrame.getOriginBody;
                        bodyInfoInertialFrame = bodyInfo.getBodyCenteredInertialFrame();
                        
                        scElemSet = CartesianElementSet(time, [xSc; ySc; zSc], [0;0;0], scFrame);
                        scElemSet = scElemSet.convertToFrame(bodyInfoInertialFrame);
                        rVectScConverted = scElemSet.rVect;
                        rVectScConverted = rVectScConverted(:)';
                        
                        stateLogEntry = [time, rVectScConverted];
                        
                        targetBodyInfo = obj.groundObj.centralBodyInfo;
                        
                        allBodyInfo = obj.celBodyData.getAllBodyInfo();
                        hasLoSAll = true;
                        for(j=1:length(allBodyInfo))
                            eclipseBodyInfo = allBodyInfo(j);
                            
                            hasLoS = LoS2Target(stateLogEntry, bodyInfo, eclipseBodyInfo, targetBodyInfo, obj.celBodyData, obj.groundObj);
                            
                            if(hasLoS == 0)
                                hasLoSAll = false;
                                break;
                            end
                        end
                        
                        if(hasLoSAll)
                            obj.losMarkerPlot{i}.Visible = 'on';
                        else
                            obj.losMarkerPlot{i}.Visible = 'off';
                        end
                    else
                        if(not(isempty(obj.losMarkerPlot{i})) && isvalid(obj.losMarkerPlot{i})) %&& isa(obj.losMarkerPlot{i}, 'matlab.graphics.primitive.Transform')
                            obj.losMarkerPlot{i}.Visible = 'off';
                        end
                    end
                else
                    if(not(isempty(obj.markerPlot{i})) && isvalid(obj.markerPlot{i}) && isa(obj.markerPlot{i}, 'matlab.graphics.primitive.Transform'))
                        obj.markerPlot{i}.Visible = 'off';
                    end
                    
                    if(not(isempty(obj.losMarkerPlot{i})) && isvalid(obj.losMarkerPlot{i})) %&& isa(obj.losMarkerPlot{i}, 'matlab.graphics.primitive.Transform')
                        obj.losMarkerPlot{i}.Visible = 'off';
                    end
                end
            end
        end
    end
end