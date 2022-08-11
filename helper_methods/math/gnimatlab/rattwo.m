function [outP,outQ] = rattwo(t,P,Q,ode,ha,hb,hc,first,last,flags,varargin)
if isempty(flags)
	F = feval(ode,t,Q,varargin{:});	
	EP = P - ha*F;
	EQ = Q + hb*EP;
	
	EE1 = EQ(1:3)'*EQ(1:3);
	EQ1 = EQ(1:3)'*Q(1:3);
	EE2 = EQ(4:6)'*EQ(4:6);
	EQ2 = EQ(4:6)'*Q(4:6);

	BET1 = 1 - EE1;
	ALAM1 = -BET1/(hb*(EQ1+sqrt(BET1+EQ1^2)));
	BET2 = 1 - EE2;
	ALAM2 = -BET2/(hb*(EQ2+sqrt(BET2+EQ2^2)));
	
	outP = EP - [ALAM1*Q(1:3);ALAM2*Q(4:6)];
	outQ = Q + hb*outP;

	if (last)
		F = feval(ode,t,outQ,varargin{:});
		outP = outP - hc*F;
		AMU1 = sum(outP(1:3).*outQ(1:3));
		AMU2 = sum(outP(4:6).*outQ(4:6));
		outP = outP - [AMU1*outQ(1:3);AMU2*outQ(4:6)];
	end
	return;
else switch flags
	case 'init',
	case 'done',
	end
end

