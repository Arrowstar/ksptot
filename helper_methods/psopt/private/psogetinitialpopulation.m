function [state, nbrtocreate] = psogetinitialpopulation(options,n,nvars)
% Gets the initial population (if any) defined by the options structure.
% Common to both PSOCREATIONUNIFORM and PSOCREATIONBINARY

nbrtocreate = n ;
state.Population = zeros(n,nvars) ;
if ~isempty(options.InitialPopulation)
    nbrtocreate = nbrtocreate - size(options.InitialPopulation,1) ;
    state.Population(1:n-nbrtocreate,:) = options.InitialPopulation ;
    if options.Verbosity > 2, disp('Found initial population'), end
end

% Initial particle velocities
state.Velocities = zeros(n,nvars) ;
if ~isempty(options.InitialVelocities)
    state.Velocities(1:size(options.InitialVelocities,1),:) = ...
        options.InitialVelocities ;
    if options.Verbosity > 2, disp('Found initial velocities'), end
end