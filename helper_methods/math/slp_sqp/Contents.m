% SLP_SQP folder for slp_trust.m, sqp_trust.m and sqp.m optimization functions
%
% Copyright (c) 2020, Robert A. Canfield. All rights reserved.
%                     Virginia Tech and Air Force Institute of Technology
%                     bob.canfield@vt.edu
%                    <http://www.aoe.vt.edu/people/faculty/canfield.html>
%                     See accompanying LICENSE.txt file for conditions.
%
% m-Files
%   slp_trust - Sequential Linear Programming (SLP) with Trust Region Strategy
%   sqp_trust - Sequential Quadratic Programming (SQP) with Trust Region Strategy
%   sqp       - Schittkowski's Sequential Quadratic Programming method
%   foptions  - Default parameters used by the optimization routines
%   initOctave- Initialize for Octave by loading packages
%   isOctave  - Function to detect Octave environment
%   Contents  - This text document describing files
%
% Documentation
%   README.md   - ReadMe text file (markdown format)
%   sqp.pdf     - User's Guide for sqp.m (Adobe portable document format)
%   LICENSE.txt - Open Source License notice
%
% Examples
%   run*.m    - Scripts to run example problems
%   f*.m      - Functions to evaluate objective, f, and constraints, g
%   g*.m      - Functions to evaluate gradients of f and g
%
% Private folder
%   Utility functions called by sqp.m, slp_trust.m and sqp_trust.m

type LICENSE.txt