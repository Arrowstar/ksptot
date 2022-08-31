function minLoc = overlaysurface(fitnessfcn,options)
% Overlays surface and marks known minimum for demo cases of pso. Called by
% PSOPLOTSWARMSURF.
%
% See also: PSODEMO, PSOPLOTSWARMSURF

xBound = options.PopInitRange(:,1) ;
yBound = options.PopInitRange(:,2) ;
[XX,YY] = meshgrid(xBound(1):(xBound(2)-xBound(1))/50:xBound(2),...
    yBound(1):(yBound(2)-yBound(1))/50:yBound(2)) ;
ZZ = zeros(size(XX)) ;
clear xBound yBound

for i = 1:size(XX,1)
    for j = 1:size(XX,2)
        ZZ(i,j) = fitnessfcn([XX(i,j) YY(i,j)]) ;
    end
end

if strcmpi(options.DemoMode,'pretty') || strcmpi(options.DemoMode,'on')
    surface(XX,YY,ZZ,'LineStyle','none',...
        'FaceAlpha',0.4,...
        'FaceLighting','gouraud',...
        'FaceColor','interp')
    flagfill = [1 0 0] ;
    flaglines = [1 0 0] ;
    set(gcf,'Colormap',1-colormap('cool'))
else
    surface(XX,YY,ZZ,'LineStyle','-',...
        'FaceColor','none',...
        'EdgeColor',[1 0.5 0.5])
    flagfill = 'none' ;
    flaglines = [0 0.5 0] ;
%     set(gca,'Color','none')
%     set(gcf,'Colormap',colormap('summer'))
end
axis tight

% Mark known minimum location, if it exists
if ~isempty(options.KnownMin)
    xmin = options.KnownMin(1) ;
    ymin = options.KnownMin(2) ;
    zminmax = get(gca,'ZLim') ;
    minLoc = line([xmin xmin],[ymin ymin],zminmax,...
        'Color',flaglines,...
        'LineWidth',1) ;
    aspr = get(gca,'DataAspectRatio') ;
    flagtip = 0.125*diff(zminmax)*aspr(1)/aspr(3) ;
    patch([xmin xmin xmin + flagtip],...
        [ymin ymin ymin],...
        [zminmax(2),...
         zminmax(2) + 0.1*diff(zminmax),...
         zminmax(2) + 0.05*diff(zminmax)],[1 0 0],...
         'FaceColor',flagfill,...
         'LineWidth',1,...
         'EdgeColor',flaglines)
     clear xmin ymin
end

axis tight
camlight
set(gca,...
    'XLimMode','manual',...
    'YLimMode','manual',...
    'ZLimMode','manual',...
    'PlotBoxAspectRatio',[1 1 1])