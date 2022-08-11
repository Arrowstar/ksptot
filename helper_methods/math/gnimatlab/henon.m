function [out,out2,out3] = henon(t,q,flag)
%   Example GNI problem file for solving the Henon-Heiles problem.
%   Use it as follows:
%
%       [T,Q,P,TE,QE,PE] = gni_meth('henon');
%       plot3(QE(:,2),PE(:,1),PE(:,2),'o');
%
%   With gni_meth replaced by either gni_irk2, gni_lmm2, or gni_comp.
if (nargin < 3) | isempty(flag)
	out(1,:)=-q(1,:).*(1+2*q(2,:));
	out(2,:)=-q(2,:).*(1-q(2,:)) - q(1,:).^2;
else
	switch flag
	case 'init',
		out = [0 1000];
		out2 = [0.18 0.18 0.18 0.18];
		out3 = gniset('StepSize',0.2,'Vectorized','on',...
			'Events','on','OutputSteps',-1,'OutputFcn','phaseplot');
	case 'events',
		out = [q(1)];
		out2 = [0];
		out3 = [0];
	end
end

