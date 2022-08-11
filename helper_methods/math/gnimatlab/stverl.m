function [outP,outQ] = stverl(t,P,Q,ode,ha,hb,hc,first,last,flags,varargin)
global EP;
global EQ;

if isempty(flags)
	if (first)
		EQ = EQ + ha*P;
		outQ = Q + EQ;
		EQ = EQ + (Q - outQ);
		Q = outQ;
	end
	F = feval(ode,t,Q,varargin{:});
	
	EP = EP + hb*F;
	outP = P + EP;
	EP = EP + (P - outP);
	
	EQ = EQ + hc*outP;
	outQ = Q + EQ;
	EQ = EQ + (Q - outQ);
	return;
else switch flags
	case 'init',
		EQ = 0;
		EP = 0;
	case 'done',
	end
end

