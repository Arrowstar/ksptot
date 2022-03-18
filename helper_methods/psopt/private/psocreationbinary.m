function state = psocreationbinary(options,nvars)
% Generates uniformly distributed swarm consisting of binary bitstrings.

n = options.PopulationSize ;
itr = options.Generations ;

[state,nbrtocreate] = psogetinitialpopulation(options,n,nvars) ;

% Initialize particle positions
state.Population(n-nbrtocreate+1:n,:) = randi([0 1],nbrtocreate,nvars) ;

% Initial particle velocities are zero by default (should be already set in
% PSOGETINTIALPOPULATION).

% Initialize the global and local fitness to the worst possible
state.fGlobalBest = ones(itr,1)*inf; % Global best fitness score
state.fLocalBests = ones(n,1)*inf ; % Individual best fitness score

% Initialize global and local best positions
state.xGlobalBest = ones(1,nvars)*inf ;
state.xLocalBests = ones(n,nvars)*inf ;