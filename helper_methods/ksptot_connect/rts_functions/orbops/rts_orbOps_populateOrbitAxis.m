function rts_orbOps_populateOrbitAxis(hFig, orbitDispAxes,orbitData,celBodyData)
%rts_orbOps_populateOrbitAxis Summary of this function goes here
%   Detailed explanation goes here
    persistent hBodySurf hOrbit hVesselMk hVesselPe hVesselAp hLineOfAN hLineOfDN az el;
    if(ishandle(hBodySurf))
        delete(hBodySurf);
    end
    if(ishandle(hOrbit))
        delete(hOrbit);
    end
    if(ishandle(hVesselMk))
        delete(hVesselMk);
    end
    if(ishandle(hVesselPe))
        delete(hVesselPe);
    end
    if(ishandle(hVesselAp))
        delete(hVesselAp);
    end
    if(ishandle(hLineOfAN))
        delete(hLineOfAN);
    end
    if(ishandle(hLineOfDN))
        delete(hLineOfDN);
    end
    if(isempty(az) || isempty(el))
        az = -37.5;
        el= 30;
    else 
        [az, el] = view(orbitDispAxes);
    end
    
    bodyID = orbitData(13);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    
    sma = orbitData(1);
    ecc = orbitData(2);
    inc = deg2rad(orbitData(3));
    raan = deg2rad(orbitData(4));
    argPe = deg2rad(orbitData(5));
    mean = orbitData(6);
    
    tru = computeTrueAnomFromMean(mean, ecc);
    [rVect,~]=getStatefromKepler(sma, ecc, inc, raan, argPe, tru, bodyInfo.gm);
    [rVectPe,~]=getStatefromKepler(sma, ecc, inc, raan, argPe, 0, bodyInfo.gm);
    if(ecc <1)
        [rVectAp,~]=getStatefromKepler(sma, ecc, inc, raan, argPe, pi, bodyInfo.gm);
    else
        rVectAp=-1;
    end
    
    [parentBodyInfo] = getParentBodyInfo(bodyInfo, celBodyData);
    [iniLB, iniUB, ~] = getOrbitTAPlotBnds(bodyInfo, parentBodyInfo, orbitData);
    
    hold(orbitDispAxes,'on');
    [hVesselMk, hVesselPe, hVesselAp] = plotOrbPosPeAp(orbitDispAxes, rVect, rVectAp, rVectPe);
    hOrbit = plotOrbit('b', sma, ecc, inc, raan, argPe, iniLB, iniUB, bodyInfo.gm, orbitDispAxes);
    [hLineOfAN, hLineOfDN] = plotLineOfNodes(orbitDispAxes, sma, ecc, inc, raan, argPe, bodyInfo.gm);
    hBodySurf = rts_initOrbPlot(hFig, orbitDispAxes, bodyInfo);
    view(orbitDispAxes, az, el);
    hold(orbitDispAxes,'off');
end

function [hLineOfAN, hLineOfDN] = plotLineOfNodes(orbitDispAxes, sma, ecc, inc, raan, argPe, gmu)
    hold(orbitDispAxes,'on');
    equatHVect = [0,0,1];
%     hVect = computeHVect(sma, ecc, inc, raan, argPe, gmu);
%     nVect = (cross(equatHVect, hVect)/norm(cross(equatHVect, hVect)));

    [truOfAN, truOfDN] = computeTruOfAscDescNodes(sma, ecc, inc, raan, arg, gmu, equatHVect);

    rAN = getStatefromKepler(sma, ecc, inc, raan, argPe, truOfAN, gmu);
    rDN = getStatefromKepler(sma, ecc, inc, raan, argPe, truOfDN, gmu);

    hLineOfAN = plot3(orbitDispAxes, [0 rAN(1)], [0 rAN(2)], [0 rAN(3)], '--ks', 'LineWidth', 1, 'MarkerEdgeColor','k', 'MarkerFaceColor','g', 'MarkerSize',7);
    hLineOfDN = plot3(orbitDispAxes, [0 rDN(1)], [0 rDN(2)], [0 rDN(3)], '--kd', 'LineWidth', 1, 'MarkerEdgeColor','k', 'MarkerFaceColor','g', 'MarkerSize',7);
    hold(orbitDispAxes,'off');
end

% function tru = getTAFromLineOfNodes(nodeR_X, raan, inc, argPe) 
%     persistent thetaGuess
%     if(isempty(thetaGuess) || isnan(thetaGuess))
%         thetaGuess = 0;
%     end
%     func = @(theta) cos(raan)*cos(theta) - sin(raan)*cos(inc)*sin(theta) - nodeR_X;
%     [theta] = fzero(func,thetaGuess);
%     thetaGuess = theta;
%     tru = AngleZero2Pi(theta - argPe);
% end

function [hVesselMk, hVesselPe, hVesselAp] = plotOrbPosPeAp(orbitDispAxes, rVect, rVectAp, rVectPe) 

    hVesselMk = plot3(orbitDispAxes, rVect(1),rVect(2),rVect(3),...
                                    'ro',...
                                    'LineWidth',1.0,...
                                    'MarkerEdgeColor','k',...
                                    'MarkerFaceColor','r',...
                                    'MarkerSize',10);
                                
    hVesselPe = plot3(orbitDispAxes, rVectPe(1),rVectPe(2),rVectPe(3),...
                                    'kd',...
                                    'LineWidth',1.0,...
                                    'MarkerEdgeColor','k',...
                                    'MarkerFaceColor','k',...
                                    'MarkerSize',7);
    if(rVectAp ~= -1)
        hVesselAp = plot3(orbitDispAxes, rVectAp(1),rVectAp(2),rVectAp(3),...
                                        'ks',...
                                        'LineWidth',1.0,...
                                        'MarkerEdgeColor','k',...
                                        'MarkerFaceColor','k',...
                                        'MarkerSize',7);
    else
        hVesselAp=-1;
    end

end

