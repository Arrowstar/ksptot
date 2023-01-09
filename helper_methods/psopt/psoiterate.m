function [state,flag] = psoiterate(options,state,flag)
% Updates swarm positions and velocities. Called to iterate the swarm from
% the main PSO function. This function can handle binary and double-vector
% "genomes".

% Weightings for inertia, local, and global influence.
C0 = state.ParticleInertia ;
C1 = options.CognitiveAttraction ; % Local (self best point)
C2 = options.SocialAttraction ; % Global (overall best point)
n = size(state.Population,1) ;
nvars = size(state.Population,2) ;

% lowerinertia = (C1 + C2)/2 - 1 ;
lowerinertia = 0.4 ;
upperinertia = max(0.9,lowerinertia) ;

% Random number seed
R1 = rand(n,nvars) ;
R2 = rand(n,nvars) ;

R1(isinf(state.fLocalBests),:) = 0 ;

% Calculate matrix of velocities state.Velocities for entire population
if strncmpi(options.PopulationType,'double',6) % Double vector
    state.Velocities = C0.*state.Velocities + ...
        C1.*R1.*(state.xLocalBests - state.Population) + ...
        C2.*R2.*(repmat(state.xGlobalBest,n,1) - state.Population) ;
    state = checkmaxvelocities(state,options) ;
    state.Population = state.Population + state.Velocities ;
elseif strncmpi(options.PopulationType,'bi',2) % Bit string
    state.Velocities = C0.*state.Velocities + ...
        C1.*(state.xLocalBests - state.Population) + ...
        C2.*(repmat(state.xGlobalBest,n,1) - state.Population) ;
    state = checkmaxvelocities(state,options) ;
    state.Population = false(n,nvars) ;
    state.Population(R1 < sigmoid(state.Velocities)) = true ;
end

% Update behavioral parameters: reduced inertial term
state.ParticleInertia = upperinertia - ...
    lowerinertia*(state.Generation-1) / ...
    (options.Generations-1) ;

function state = checkmaxvelocities(state,options)
% Checks the particle velocities against options.VelocityLimit

if ~isempty(options.VelocityLimit) && ... % Check max velocities
        any(isfinite(options.VelocityLimit))
    state.Velocities = min(state.Velocities, ...
        repmat(options.VelocityLimit,n,1)) ;
    state.Velocities = max(state.Velocities, ...
        repmat(-options.VelocityLimit,n,1)) ;
end

function s = sigmoid(v)
% Sigmoid function for bit string iteration

s = 1./(1+exp(-v)) ;