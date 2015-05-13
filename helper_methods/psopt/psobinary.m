function [xOpt,fval,exitflag,output,population,scores] = ...
    psobinary(fitnessfcn,nvars,options)
% Particle swarm optimization for binary genomes.
%
% Syntax:
% psobinary(fitnessfcn,nvars)
% psobinary(fitnessfcn,nvars,options)
%
% This function will optimize fitness functions where the variables are
% row vectors of size 1xnvars consisting of only 0s and 1s.
%
% PSOBINARY is provided as a wrapper for PSO, to avoid any confusion. This
% is because the binary optimization scheme is not designed to take any
% constraints. PSOBINARY does not allow the passing of constraints. It
% takes a given optimization problem with binary variables, and
% automatically sets the options structure so that 'PopulationType'
% is 'bitstring'.
%
% This has exactly the same effect as setting the appropriate options
% manually, except that it is not possible to unintentionally define
% constraints, which would be ignored by the binary variable optimizer
% anyway.
%
% Problems with hybrid variables (double-precision and bit-string
% combined) cannot be solved yet.
%
% The output variables for PSOBINARY is the same as for PSO.
%
% See also:
% PSO, PSOOPTIMSET, PSODEMO

if ~exist('options','var') % Set default options
    options = struct ;
end % if ~exist
options = psooptimset(options,'PopulationType','bitstring') ;

[xOpt,fval,exitflag,output,population,scores] = ...
    pso(fitnessfcn,nvars,[],[],[],[],[],[],[],options) ;