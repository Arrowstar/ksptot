function retval = isOctave
%   isOctave  - Function to detect Octave environment
%
% Return: true if the environment is Octave.
% isOctave used by private/qp.m, sqpcrkopts.m, sao_trust.m, sqp.m

%  Written by:   Blake M. Van Winkle
%                Naval Surface Warfare Center Dahlgren Division
%  e-mail:       blake.vanwinkle@navy.mil
%
%  Created:      11/11/17
%  Modified:     11/ 3/19 - included in slp_sqp
%                 7/23/20 - initOctave installs (optionally) & loads optim

  persistent cacheval;  % speeds up repeated calls

  if isempty (cacheval)
    cacheval = (exist ('OCTAVE_VERSION','builtin') > 0);
    if cacheval && ~exist('quadprog','builtin')
       initOctave
    end
  end
  retval = cacheval;
end
