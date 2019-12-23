function plotAllFlybys(hAxis, cBodyInfo, xferOrbits, bodiesInfo, numRev, celBodyData)
%plotAllFlybys Summary of this function goes here
%   Detailed explanation goes here
    axes(hAxis);
    cla(hAxis, 'reset');
    set(hAxis,'Color',[0 0 0]);
    set(hAxis,'XTick',[], 'XTickMode', 'manual');
    set(hAxis,'YTick',[], 'YTickMode', 'manual');
    set(hAxis,'ZTick',[], 'ZTickMode', 'manual');

    legendHs = [];
    legendStrs = {};
    
    hold on;
    bColor = cBodyInfo.bodycolor;
    cmap = colormap(bColor);
    bColorRGB = mean(cmap,1);
    plot3(0,0,0, 'o', 'Color', bColorRGB, 'MarkerEdgeColor', bColorRGB, 'MarkerFaceColor', bColorRGB, 'MarkerSize', 10);
    
    usedIds = [];
    for(i=1:length(bodiesInfo)) %#ok<*NO4LP>
        bodyInfo = bodiesInfo{i};
        gmu = getParentGM(bodyInfo, celBodyData);
        
        bColor = bodyInfo.bodycolor;
        cmap = colormap(bColor);
        midRow = round(size(cmap,1)/2);
        bColorRGB = cmap(midRow,:);
        
        hold on;
        h=plotBodyOrbit(bodyInfo, bColorRGB, gmu);
        if(~ismember(bodyInfo.id,usedIds))
            legendHs(end+1) = h; %#ok<AGROW>
            legendStrs{end+1} = [cap1stLetter(lower(bodyInfo.name)), ' Orbit']; %#ok<AGROW>
            usedIds(end+1) = bodyInfo.id; %#ok<AGROW>
        end
        
        if(i==1)
            orbitB = xferOrbits(i,:);
            t = orbitB(8);
        else
            orbitB = xferOrbits(i-1,:);
            t = orbitB(9);
        end
        
        [rVect, ~] = getStateAtTime(bodyInfo, t, gmu);
        hold on;
        plot3(rVect(1),rVect(2),rVect(3), 'o', 'Color', bColorRGB, 'MarkerEdgeColor', bColorRGB, 'MarkerFaceColor', bColorRGB, 'MarkerSize', 10);
    end
    
    lineSpec = {'-.','-','--'};
    for(i=1:size(xferOrbits,1))
        orbit = xferOrbits(i,:);
        
        ind = mod(i,3)+1;
        
        hold on;
        if(abs(numRev(i)) > 0)
            plotOrbit('w', orbit(1), orbit(2), orbit(3), orbit(4), orbit(5), 0, 2*pi, orbit(10), gca, [0;0;0], 1.5, lineSpec{ind});
        end
        
        h=plotOrbit('w', orbit(1), orbit(2), orbit(3), orbit(4), orbit(5), orbit(6), orbit(7), orbit(10), gca, [0;0;0], 1.5, lineSpec{ind});
        legendHs(end+1) = h;
        legendStrs{end+1} = ['Phase ',num2str(i),' Xfer Orbit'];
    end
    
    hL = legend(legendHs,legendStrs,'Location','SouthEast','orientation','vertical','EdgeColor','w','LineWidth',2,'TextColor','w');
    hText = findobj(hL, 'type', 'text');
    set(hText,'Color', 'w');
    
    hold on;
    view([0 89]);
    axis equal;
    v = axis;
    axis(v*1.05);
    hold off;
    zoom reset;
end

