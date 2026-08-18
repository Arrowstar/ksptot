function [mu, tau] = control_barrierUpdate(mu, Emu, opts)
%CONTROL_BARRIERUPDATE  Monotone Fiacco-McCormick barrier schedule.
%   [mu, tau] = adamnlopt.control_barrierUpdate(mu, Emu, opts) decreases the
%   barrier parameter mu only once the current (mu-perturbed) KKT error Emu has
%   been driven below kappaMu*mu. The new mu follows the superlinear rule
%       mu <- max(muMin, min(muGamma*mu, mu^muBeta)),
%   and tau (the fraction-to-boundary factor) is pushed toward 1 as mu -> 0 so
%   steps can approach the boundary near the solution.
%
%   Inputs:
%     mu   - current barrier parameter (scalar > 0).
%     Emu  - current mu-perturbed KKT error (scalar >= 0) used to gate the
%            decrease: mu is only reduced once Emu <= kappaMu*mu.
%     opts - options struct with fields kappaMu, muMin, muGamma, muBeta, tau.
%
%   Outputs:
%     mu  - updated (monotonically non-increasing) barrier parameter.
%     tau - updated fraction-to-boundary factor, pushed toward 1 as mu -> 0.
%
%   See also CONTROL_MODECONTROLLER, STEP_FRACTIONTOBOUNDARY.

if Emu <= opts.kappaMu * mu
    mu = max(opts.muMin, min(opts.muGamma * mu, mu ^ opts.muBeta));
end
tau = max(opts.tau, 1 - mu);
end
