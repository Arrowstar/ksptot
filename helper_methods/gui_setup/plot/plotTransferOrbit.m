function plotTransferOrbit(departAxis, varargin)
%plotTransferOrbit Summary of this function goes here
%   Detailed explanation goes here

    axes(departAxis);
    cla(departAxis);
    view([0,89]);
    
    uselegend=true;
    if(nargin==2)
        uselegend = varargin{1};
    end
    
    hold(departAxis,'on');
    
    axisUserData = get(departAxis,'UserData');
    
    celBodyData = axisUserData{1,3};
    departBody = axisUserData{1,15};
    arrivalBody =  axisUserData{2,1};
    departUT = axisUserData{2,2};
    arrivalUT = axisUserData{2,3};
    gmuXfr = axisUserData{2,4};
    smaX = axisUserData{2,5};
    eccX = axisUserData{2,6};
    incX = axisUserData{2,7};
    raanX = axisUserData{2,8};
    argX = axisUserData{2,9};
    anomAX = axisUserData{2,10};
    anomDX = axisUserData{2,11};
    
    hVectX = computeHVect(smaX, eccX, incX, raanX, argX, gmuXfr);
    
    legendTxt = {};
    legendH = [];
    
    dSMA = celBodyData.(lower(departBody)).sma;
    dECC = celBodyData.(lower(departBody)).ecc;
    dINC = celBodyData.(lower(departBody)).inc*pi/180;
    dRAAN = celBodyData.(lower(departBody)).raan*pi/180;
    dARG = celBodyData.(lower(departBody)).arg*pi/180;    
%     h = plotOrbit('r', dSMA, dECC, dINC, dRAAN, dARG, 0, 2*pi, gmuXfr);
    h = plotBodyOrbit(celBodyData.(lower(departBody)), '', gmuXfr);
    legendH(end+1) = h;
    legendTxt{end+1} = [cap1stLetter(departBody), ' Orbit'];
    
    aSMA = celBodyData.(lower(arrivalBody)).sma;
    aECC = celBodyData.(lower(arrivalBody)).ecc;
    aINC = celBodyData.(lower(arrivalBody)).inc*pi/180;
    aRAAN = celBodyData.(lower(arrivalBody)).raan*pi/180;
    aARG = celBodyData.(lower(arrivalBody)).arg*pi/180;  
    aHVect = computeHVect(aSMA, aECC, aINC, aRAAN, aARG, gmuXfr);
%     h = plotOrbit('b', aSMA, aECC, aINC, aRAAN, aARG, 0, 2*pi, gmuXfr);
    h = plotBodyOrbit(celBodyData.(lower(arrivalBody)), '', gmuXfr);
    legendH(end+1) = h;
    legendTxt{end+1} = [cap1stLetter(arrivalBody), ' Orbit'];

    if(anomAX > anomDX) 
        h = plotOrbit('w', smaX, eccX, incX, raanX, argX, anomDX, anomAX, gmuXfr);
        legendH(end+1) = h;
        legendTxt{end+1} = 'Transfer Orbit';
        if(anomDX < pi && anomAX > pi)
            r = getStatefromKepler(smaX, eccX, incX, raanX, argX, pi, gmuXfr);
            hold(departAxis,'on');
            h = plot3(r(1),r(2),r(3), 'gp', 'MarkerEdgeColor', 'g', 'MarkerFaceColor', 'g', 'MarkerSize', 7);
        end
    elseif(anomAX < anomDX) 
        h = plotOrbit('w', smaX, eccX, incX, raanX, argX, anomDX, 2*pi, gmuXfr);
        plotOrbit('w', smaX, eccX, incX, raanX, argX, 0, anomAX, gmuXfr);
        legendH(end+1) = h;
        legendTxt{end+1} = 'Transfer Orbit';
        
        r = getStatefromKepler(smaX, eccX, incX, raanX, argX, 0, gmuXfr);
        hold(departAxis,'on');
        h = plot3(r(1),r(2),r(3), 'gd', 'MarkerEdgeColor', 'g', 'MarkerFaceColor', 'g', 'MarkerSize', 7);
        if(anomAX > pi || anomDX < pi)
            r = getStatefromKepler(smaX, eccX, incX, raanX, argX, pi, gmuXfr);
            hold(departAxis,'on');
            h = plot3(r(1),r(2),r(3), 'gp', 'MarkerEdgeColor', 'g', 'MarkerFaceColor', 'g', 'MarkerSize', 7);
        end
    end
    
    dRa = dSMA*(1+dECC);
    aRa = aSMA*(1+aECC);
    RAANVectLength = abs(smaX*(1+eccX));
    RAANVectLength = min(RAANVectLength, max(dRa,aRa));
    nVect = abs(RAANVectLength)*(cross(aHVect, hVectX)/norm(cross(aHVect, hVectX)));
    hold(departAxis,'on');
    plot3([-nVect(1) nVect(1)], [-nVect(2) nVect(2)], [-nVect(3) nVect(3)], '--w', 'LineWidth', 1);
    
    [rVecD, ~] = getStateAtTime(celBodyData.(departBody), departUT, gmuXfr);
    [rVecA, ~] = getStateAtTime(celBodyData.(arrivalBody), arrivalUT, gmuXfr);
    [rVecAatDUT, ~] = getStateAtTime(celBodyData.(arrivalBody), departUT, gmuXfr);
    hold(departAxis,'on');
    h = plot3(rVecAatDUT(1),rVecAatDUT(2),rVecAatDUT(3), 'ro', 'MarkerEdgeColor', 'r', 'MarkerFaceColor', 'r', 'MarkerSize', 10);
    legendH(end+1) = h;
    legendTxt{end+1} = [cap1stLetter(arrivalBody), ' at Departure'];
    
    hold(departAxis,'on');
    h = plot3([rVecD(1) rVecA(1)], [rVecD(2) rVecA(2)], [rVecD(3) rVecA(3)], 'g*');
%     plot3(0,0,0, 'yo', 'MarkerEdgeColor', 'y', 'MarkerFaceColor', 'y', 'MarkerSize', 10);
    
    cBodyInfo = getParentBodyInfo(celBodyData.(lower(departBody)), celBodyData);
    bColor = cBodyInfo.bodycolor;
    cmap = colormap(bColor);
    bColorRGB = mean(cmap,1);
    plot3(0,0,0, 'o', 'Color', bColorRGB, 'MarkerEdgeColor', bColorRGB, 'MarkerFaceColor', bColorRGB, 'MarkerSize', 10);
    
    set(departAxis,'Color',[0 0 0]);
    set(departAxis,'XTick',[], 'XTickMode', 'manual');
    set(departAxis,'YTick',[], 'YTickMode', 'manual');
    set(departAxis,'ZTick',[], 'ZTickMode', 'manual');
    
    if(uselegend)
        legend_h = legend(legendH, legendTxt, 'Location', 'Best', 'EdgeColor', 'w', 'TextColor', 'w', 'LineWidth', 1.5);
        legtxt=findobj(legend_h,'type','text');
        for(i=1:length(legtxt))
            set(legtxt(i),'color','w')
        end
    end
    
    axis equal;
    hold off;
end