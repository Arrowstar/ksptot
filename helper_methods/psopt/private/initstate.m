function state = initstate(nvars,options,n,itr)
% Initialize swarm condition. Called by PSO.

% Initial particle velocities
state.Velocities = zeros(n,nvars) ;

% Initialize particle positions
state.Population = ...
    repmat(options.PopInitRange(1,:),n,1).*ones(n,nvars) + ...
    repmat((options.PopInitRange(2,:) - options.PopInitRange(1,:)),n,1) ...
    .*rand(n,nvars) ;

% Initialize the global and local fitness to the worst possible
state.fGlobalBest = ones(itr,1)*inf; % Global best fitness score
state.fLocalBests = ones(n,1)*inf ; % Individual best fitness score

% Initialize global and local best positions
state.xGlobalBest = ones(1,nvars)*inf ;
state.xLocalBests = ones(n,nvars)*inf ;