function saveTightFigure(h,outfilename)
% SAVETIGHTFIGURE(H,OUTFILENAME) Saves figure H in file OUTFILENAME without
%   the white space around it. 
%
% by ``a grad student"
% http://tipstrickshowtos.blogspot.com/2010/08/how-to-get-rid-of-white-margin-in.html

% get the current axes
ax = get(h, 'CurrentAxes');

% make it tight
ti = get(ax,'TightInset');
set(ax,'Position',[ti(1) ti(2) 1-ti(3)-ti(1) 1-ti(4)-ti(2)]);

% adjust the papersize
set(ax,'units','centimeters');
pos = get(ax,'Position');
ti = get(ax,'TightInset');
set(h, 'PaperUnits','centimeters');
set(h, 'PaperSize', [pos(3)+ti(1)+ti(3) pos(4)+ti(2)+ti(4)]);
set(h, 'PaperPositionMode', 'manual');
set(h, 'PaperPosition',[0 0  pos(3)+ti(1)+ti(3) pos(4)+ti(2)+ti(4)]);

% save it
saveas(h,outfilename);

% Copyright (c) 2011, Emre Akbas
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
% 
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.
