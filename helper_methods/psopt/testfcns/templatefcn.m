function f = templatefcn(x)
% Template for writing custom test/demonstration functions for psodemo.
% Change the function name and save as a different file to preserve this
% template for future use.
%
% NOTE: defining KnownMin is only for the purposes of demonstration
% plotting. It does not help the particle swarm algorithm in any way.

if strcmp(x,'init')
% Opportunity to set custom options before psodemo actually calls pso.
%
% Some examples:
%     f.PopInitRange = [-2; 2] ;
%     f.KnownMin = [0,0] ; % For plotting purposes only
%     f.PopulationSize = 100 ;
%
% Set f.Vectorized = 'on' if the test function is able to take a matrix
% input, with swarm individuals on each row. That is, x is size n x nvars,
% where n is the number of individuals in the swarm, and the test function
% returns f as an nx1 vector representing the fitness scores for all
% particles.
else
    % Write the actual function here.
    f = x.^2 ;
end