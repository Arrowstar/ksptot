function state = psoplotswarm(options,state,flag,ijk)
% Plots the positions of particle swarm.
%
% ijk is an additional parameter, in the form of a 1x3 vector. It lists the
% dimension of the problem to be plotted, for a multidimensional problem.
%
% Updated this to conform with MATLAB GA toolbox specifications.

% We'll only plot the first two dimensions by default. User can
% set different dimensions to be plotted using ijk.

if nargin < 4 && size(state.Population,2) > 1 % Go to defaults
    ijk = [1,2] ; % k doesn't exist
elseif size(state.Population,2) == 1 % For 1-D problems
    ijk = 1 ;
else % Robust input check
    ijk = reshape(ijk,1,[]) ;
end

% Input checking
if size(ijk,2) > 3
    warning('PSO:Plotting:tooManyDimensions',...
        'Unable to plot %g dimensions. Plotting first 3 only',...
        length(ijk))
end % if length

if strcmpi(flag(1:4),'init') % Initialize
    delete(findobj(gca,'-regexp','Tag','*Locations'))
    initLoc = line(state.Population(:,ijk(1)),state.Population(:,ijk(2)),...
        'Color',0.75*ones(1,3),...
        'Marker','.',...
        'LineStyle','none',...
        'Tag','Initial Locations') ;
    
    % Set reasonable axes limits
    % ---------------------------------------------------------------------
    xlim([options.PopInitRange(1,ijk(1)) options.PopInitRange(2,ijk(1))])
    if size(ijk,2) > 1
        ylim([options.PopInitRange(1,ijk(2)) ...
            options.PopInitRange(2,ijk(2))])
        if size(ijk,2) > 2
            zlim([options.PopInitRange(1,ijk(3)) ...
                options.PopInitRange(2,ijk(3))])
        end % if size
    end % if size
    % ---------------------------------------------------------------------
    
    title('Swarm positions')
    set(gca,'Tag','Swarm Plot','NextPlot','add')
    
    % Initialize plots
    % ---------------------------------------------------------------------
    if size(ijk,2) == 1 %  One dimensional
        currentLoc = line(state.Population(:,ijk(1)),...
            zeros(size(state.Population,1),1)) ;
    elseif size(ijk,2) == 2 % Two dimensional
        currentLoc = line(state.Population(:,ijk(1)),...
            state.Population(:,ijk(2))) ;
    elseif size(ijk,2) == 3 % Three dimensional
        currentLoc = line(state.Population(:,ijk(1)),...
            state.Population(:,ijk(2)),...
            state.Population(:,ijk(3))) ;
    end % if size
    set(currentLoc,...
            'LineStyle','none',...
            'Marker','.',...
            'Color','blue',...
            'Tag','Swarm Locations') ;
    % ---------------------------------------------------------------------
elseif strcmpi(flag(1:4),'iter') % Iterate
    currentLoc = findobj(gca,'Tag','Swarm Locations','Type','line') ;
    if size(ijk,2) == 1 %  One dimensional
        set(currentLoc,'XData',state.Population(:,ijk(1)))
    elseif size(ijk,2) == 2 % Two dimensional
        set(currentLoc,...
            'XData',state.Population(:,ijk(1)),...
            'YData',state.Population(:,ijk(2)))
    elseif size(ijk,2) == 3 % Three dimensional
        set(currentLoc,...
            'XData',state.Population(:,ijk(1)),...
            'YData',state.Population(:,ijk(2)),...
            'ZData',state.Population(:,ijk(3)))
    end
end

if strcmpi(flag(1:4),'init')
    legend([initLoc,currentLoc],{'Initial Positions','Current Positions'})
end