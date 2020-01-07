function minLoc = overlaycontour(fitnessfcn,xmin,ymin,xBound,yBound)
% Overlays contour and marks known minimum for demo cases of pso.

minLoc = line(xmin,ymin,fitnessfcn(xmin,ymin),'Color','Red',...
    'Marker','o',...
    'MarkerSize',10,...
    'LineWidth',1.5,...
    'LineStyle','none') ;

[XX,YY] = meshgrid(xBound(1):(xBound(2)-xBound(1))/50:xBound(2),...
    yBound(1):(yBound(2)-yBound(1))/50:yBound(2)) ;
ZZ = zeros(size(XX)) ;

for i = 1:size(XX,1)
    for j = 1:size(XX,2)
        ZZ(i,j) = fitnessfcn([XX(i,j) YY(i,j)]) ;
    end
end

contour(XX,YY,ZZ)