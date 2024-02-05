%% initOctave -- initialize Octave with packages for sqp/slp_trust
%  Written by:   Robert A. Canfield
%  e-mail:       bob.canfield@vt.edu
%
%  Created:      11/11/17 - by Blake M. Van Winkle for isOctave.m
%  Modified:      5/27/19 - included in slp_sqp (RAC)
%                 7/23/20 - install optim pkg first if missing
%
if exist ('OCTAVE_VERSION','builtin')
   % Tested with Octave versions 4.4.1 and 5.1.0 on Mac OSX 10.13.16
   % Manually move checkbounds.m to private directory or add its path
   MSGID = 'Octave:possible-matlab-short-circuit-operator';
   warning('off',MSGID);
   % source this script from slp_sqp directory
   % or specify full directory path in addpath
   listpkg = pkg("list","optim");
   if isempty(listpkg)
      pkg install -forge io
      pkg install -forge statistics
      pkg install -forge struct
      pkg install -forge optim
   end
   pkg load optim
   addpath('examples:private:private/Octave')
end