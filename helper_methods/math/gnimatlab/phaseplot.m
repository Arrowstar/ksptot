function status = phaseplot(t,y,flag)
%   Example of custom output function. It has to be used in 
%   a GNI options structure as 
%
%      gniset('OutputFcn','phaseplot');
%
%   If 2*N components are given, it plots the N last components
%   as functions of the N first components.
status = 0; 
chunk = 128;

if nargin < 3 | isempty(flag)
  ud = get(gcf,'UserData');

  nt = length(t);
  chunk = max(chunk,nt);
  [cols,rows] = size(ud.x);
  
  if ud.i + nt > rows
    ud.x = [ud.x, zeros(ud.N,chunk)];
    ud.y = [ud.y, zeros(ud.N,chunk)];
  end
  ud.x(1:ud.N,(ud.i+1):(ud.i+nt)) = y(1:ud.N,:);
  ud.y(1:ud.N,(ud.i+1):(ud.i+nt)) = y((ud.N+1):(2*ud.N),:);
  ud.i = ud.i + nt;
  set(gcf,'UserData',ud);
  
  if ud.stop == 1
    status = 1;
    phaseplot([],[],'done');
  else
    xlim = get(gca,'xlim');
    ylim = get(gca,'ylim');
    if (ud.i == nt+1) | (min(y(1:ud.N,1:nt)) < xlim(1)) | ...
    	(xlim(2) < max(y(1:ud.N,1:nt))) | ...
    	(min(y((ud.N+1):(2*ud.N),1:nt)) < ylim(1)) | ...
    	(ylim(2) < max(y((ud.N+1):(2*ud.N),1:nt)))
  	for i=1:ud.N
		set(ud.lines(i),'Xdata',ud.x(i,1:ud.i),'Ydata',ud.y(i,1:ud.i));
	end
    else
  	for i=1:ud.N
		set(ud.line(i),'Xdata',ud.x(i,1:ud.i),'Ydata',ud.y(i,1:ud.i));
	end
    end
  end
  
else
  switch(flag)
  case 'init'
    ud = [];
    ud.N = floor(size(y) / 2);
    ud.N = ud.N(1);
    ud.x = zeros(ud.N,chunk);
    ud.y = zeros(ud.N,chunk);
    ud.i = 1;
    for i=1:ud.N
   		ud.x(i,1) = y(i);
    	ud.y(i,1) = y(i+ud.N);
    end
    
    f = figure(gcf);
	hold on
	colr = ['b','r','g','m','c'];
	for i=1:ud.N
		ud.line(i) = plot(ud.x(i,1),ud.y(i,1),...
			strcat(colr(mod(i-1,5)+1),'o-'),'EraseMode','none');
		ud.lines(i) = plot(ud.x(i,1),ud.y(i,1),...
			strcat(colr(mod(i-1,5)+1),'o-'));
	end
    set(gca,'XLimMode','auto');
    set(gca,'YLimMode','auto');
	hold off
    
    % The STOP button.
    h = findobj(f,'Tag','stop');
    if isempty(h)
      ud.stop = 0;
      pos = get(0,'DefaultUicontrolPosition');
      pos(1) = pos(1) - 15;
      pos(2) = pos(2) - 15;
      str = 'ud=get(gcf,''UserData''); ud.stop=1; set(gcf,''UserData'',ud);';
      uicontrol( ...
          'Style','push', ...
          'String','Stop', ...
          'Position',pos, ...
          'Callback',str, ...
          'Tag','stop');
    else
      set(h,'Visible','on');
      if ishold
        oud = get(f,'UserData');
        ud.stop = oud.stop; 
      else
        ud.stop = 0;
      end
    end
    set(f,'UserData',ud);
    
  case 'done' 
    f = gcf;
    ud = get(f,'UserData'); 
    ud.x = ud.x(1:ud.N,1:ud.i);
    ud.y = ud.y(1:ud.N,1:ud.i);
    set(f,'UserData',ud);
  	for i=1:ud.N
		set(ud.line(i),'Xdata',ud.x(i,1:ud.i),'Ydata',ud.y(i,1:ud.i));
	end
    set(findobj(f,'Tag','stop'),'Visible','off');
    refresh;
  end
end

drawnow;
