function [ax,hfill]=cbarf(v,L,mode,scale);
%CBARF   Real filled colorbar.
%   Similar to the well known colorbarf but more realistic.
%   There are two things missing in colorbar and colorbarf:
%   1. the colorbar ticks are scaled according to the size of each
%   interval. If you don't want this, set SCALE to 'nonlinear'.
%   2. when color is saturated at the upper limit, or when is white,
%   below the lower limit, a triangle is added. The triangle
%   means "more/less than". Such information is not provided by the
%   existing tools, colorbar and colorbarf.
%   See the examples.
%   Besides, there is a bug (?) with contourf: in some cases, even
%   with the levels specified, one additional level is added and
%   corrensponds to the sourrounding line! In such case, colorbarf
%   adds one box for this fake level!
%
%   Syntax:
%      H=CBARF(DATA,LEVELS,MODE,SCALE)
%
%   Inputs:
%      DATA   The data used to create the contourf
%               (or alternative [min max] values for cbarf)
%      LEVELS Levels used (ex: contourf(x,y,DATA,LEVELS)
%      MODE   How the colorbar is placed [{'vertical'}, 'horiz']
%      SCALE  Colorbar ticks scaling [{'linear'},'nonlinear']
%
%   Output:
%       H   Handle for the axes created
%
%   Comment:
%      If you need to redraw the colorbar because caxis change for
%      instace, then just call cbarf without input arguments
%
%   Examples:
%      v=peaks;
%      L=[-5:-1 1:5];
%      figure
%      subplot(2,1,1)
%      contourf(v,L);
%      h1=cbarf(v,L);
%
%      caxis([-10 10])
%      cbarf;
%
%      subplot(2,1,2)
%      L=[5:15];
%      contourf(v,L);
%      h2=cbarf(v,L);
%
%   MMA 15-3-2007, martinho@fis.ua.pt

%   13-07-2007 - Added option SCALE, updated by Hvid Ribergaard
%   14-05-2008 - Corrected colors for the nonlinear case

% Martinho Marta Almeida
%    Department of Physics
%    University of Aveiro, Portugal
%
% Mads Hvid Ribergaard
%    Center for Ocean and Ice
%    Danish Meteorological Institute

% find previous cbarf:
ax0=gca;
%ax=[findobj(gcf,'tag','cbarf_horiz') findobj(gcf,'tag','cbarf_vertical')];
ax=get(gca,'userdata');
if isempty(ax), newCbar=1; else newCbar=0; end
if ~newCbar
  tag=get(ax,'tag');
  i=find(tag=='_');
  mode=tag(i(1)+1:i(2)-1);
  scale=tag(i(2)+1:end);
  ud=get(ax,'userdata');
  L=ud.L;
  Mm=ud.Mm;
  mv=Mm(1); Mv=Mm(2);
end

% if no cbarf yet, then input arguments are needed:
if newCbar
  if nargin < 4
    scale='linear';
  end
  if nargin < 3
    mode='vertical';
  end
  if nargin < 2
    disp(['## ',mfilename,' : not enough input arguments'])
    return
  end
  mv=min(v(:));
  Mv=max(v(:));
end

% Mode
if isequal(lower(mode(1)),'h')
  isVertical=0;
  mode='horiz';
else
  isVertical=1;
  mode='vertical';
end

% Scale
if isequal(lower(scale(1)),'l')
  isLinear=1;
  scale='linear';
else
  isLinear=0;
  scale='nonlinear';
end

clim=get(ax0,'clim');
cmap=get(gcf,'colormap');

% create nex axes if needed:
au=get(ax0,'units');
set(ax0,'units','pixel'); ap=get(ax0,'position');
W=25;
dW=20;
if newCbar
  if isVertical
    ax0Pos = [ap(1) ap(2) ap(3)-dW-W  ap(4)];
    axPos  = [ap(1)+ap(3)-W  ap(2) W ap(4)];
  else
    ax0Pos = [ap(1) ap(2)+dW+W ap(3) ap(4)-dW-W];
    axPos  = [ap(1) ap(2) ap(3) W];
  end
  set(ax0,'position',ax0Pos)
  ud.L=L;
  ud.Mm=[mv Mv];
  ax=axes('units','pixel','tag',['cbarf_',mode,'_',scale],'userdata',ud);
  set(ax0,'userdata',ax);
else
  if isVertical
    axPos  = [ap(1)+ap(3)+dW  ap(2) W ap(4)];
  else
    axPos  = [ap(1) ap(2)-dW-W ap(3) W];
  end
  cla(ax)
  axes(ax)
end
set(ax0,'units',au)
set(ax,'units','pixel','position',axPos)
set(ax,'units','normalized')

% find start and end indices of L:
i1=find(L>mv); i1=i1(1)-1;
i2=find(L<Mv); i2=i2(end);

% check if need to add triangles at top/right and bottom/left:
addUp  = 0;
addBot = 0;
if L(end) < Mv, addUp  = 1; end
if L(1)   > mv, addBot = 1; end

% draw the rectangles:
Nrec=1;
a=max(1,i1);
b=min(i2,length(L)-1);
step=(L(b+1)-L(a))/length(a:b);  % scale for Nonlinear
for i=a:b
  cor=caxcolor(L(i),clim,cmap); hold on
  if isVertical
    if isLinear
      fill([0 1 1 0],[L(i) L(i) L(i+1) L(i+1)],cor);
    else
      fill([0 1 1 0],L(a)+[(Nrec-1)*step (Nrec-1)*step Nrec*step Nrec*step],cor);
    end
  else
    if isLinear
      fill([L(i) L(i) L(i+1) L(i+1)],[0 1 1 0],cor);
    else
      fill(L(a)+[(Nrec-1)*step (Nrec-1)*step Nrec*step Nrec*step],[0 1 1 0],cor);
    end
  end
  Nrec=Nrec+1;
end
yl=[L(a) L(b+1)];

% add triangle at top/right:
if addUp
  cor=caxcolor(Mv,clim,cmap);
  ap=get(ax,'position');
  if isVertical
    fill([0 1 .5],[L(end) L(end) L(end)+diff(yl)/15],cor,'clipping','off');
    set(ax,'position',[ap(1:3) ap(4)-ap(4)/15])
  else
    fill([L(end) L(end) L(end)+diff(yl)/15],[0 1 .5],cor,'clipping','off');
    set(ax,'position',[ap(1:2) ap(3)-ap(3)/15 ap(4)])
    Nrec=Nrec+1;
  end
end

% add triangle at bottom/left:
if addBot
  ap=get(ax,'position');
  if isVertical
    fill([0 1 .5],[L(1) L(1) L(1)-diff(yl)/15],'w','clipping','off');
    set(ax,'position',[ap(1) ap(2)+ap(4)/15 ap(3) ap(4)-ap(4)/15])
  else
    fill([L(1) L(1) L(1)-diff(yl)/15],[0 1 .5],'w','clipping','off');
    set(ax,'position',[ap(1)+ap(3)/15 ap(2) ap(3)-ap(3)/15  ap(4)])
  end
  Nrec=Nrec+1;
end

% set limits, ticks and ticklabels:
if isVertical
  yt=get(ax,'ytick');
  if length(L(a:b+1)) <=10
    yt=L(a:b+1);
  else
    yt=intersect(yt,L(a:b+1));
  end
  if isLinear
    ytl=yt;
  else
    Ntick=length(get(ax,'Children'))+1-addBot-addUp;
    yt=linspace(yl(1),yl(2),Ntick);
    ytl=L(a:b+1);
  end
  set(ax,'xtick',[],'yaxislocation','right','ytick',yt,'yticklabel',ytl);
  ylim(yl)
else
  xt=get(ax,'xtick');
  if length(L(a:b+1)) <=10
    xt=L(a:b+1);
  else
    xt=intersect(xt,L(a:b+1));
  end
  if isLinear
    xtl=xt;
  else
    Ntick=length(get(ax,'Children'))+1-addBot-addUp;
    xt=linspace(yl(1),yl(2),Ntick);
    xtl=L(a:b+1);
  end
  set(ax,'ytick',[],'xaxislocation','bottom','xtick',xt,'xticklabel',xtl);
  xlim(yl)
end
hfill=get(ax,'Children');
axes(ax0)



function cor = caxcolor(val,cax,cmap)
% calc color based on the colormap, caxis and value:
n=size(cmap,1);
i= (val-cax(1))/diff(cax) * (n-1) +1;
a=i-floor(i);
i=floor(i);
i=max(min(i,n),1);
if i==n
  cor=cmap(n,:);
elseif i==1
  cor=cmap(1,:);
else
  cor=cmap(i,:)*(1-a) + cmap(i+1,:)*a;
end
