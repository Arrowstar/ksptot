function [teout,ieout,qeout,peout,stop] = gnievents(odefile,E0,E1,P0,P1,Q0,Q1,T,direction,terminal,varargin)
	H=T(2) - T(1);
    H2=H*H;
    DIFF=(Q1-Q0)/H;
    
    P0DIF=P0-DIFF;
    P1DIF=P1-DIFF;

	teout = [];
	ieout = [];
	qeout = [];
	peout = [];
	stop = logical(0);
	LeftSave = [];
	RightSave = [];
	TSave = [];
	
	LeftCur = E0;
	RightCur = E1;
	TCur = T;
	StateCur = ((E0.*E1) <= 0) & (E1 ~= 0) & (direction .* (E1-E0) >= 0);
	
	Level = 0;
	
	while (max(StateCur) == 1)
		Time = (TCur(2)+TCur(1))/2;

    	XM0=Time-T(1);
    	XM1=Time-T(2);
    	POLQ=Q0+XM0*(DIFF+XM1*(P1DIF*XM0+P0DIF*XM1)/H2);
	    POLP=DIFF+(XM0*(2*XM1+XM0)*P1DIF+XM1*(2*XM0+XM1)*P0DIF)/H2;
		CurVal = feval(odefile,Time,[POLQ;POLP],'events',varargin{:});

		StateR = (CurVal.*RightCur) <= 0;
		StateL = (CurVal.*LeftCur) <= 0;
		stopit = logical((TCur(1) == Time) | (TCur(2) == Time));
		if (StateR == StateCur)
			LeftCur = CurVal;
			TCur(1) = Time;
		elseif (StateL == StateCur)
			RightCur = CurVal;
			TCur(2) = Time;
		else
			Level = Level+1;
			LeftSave = [LeftSave,CurVal];
			RightSave = [RightSave,RightCur];
			TSave = [TSave,[Time;TCur(2)]];

			RightCur = CurVal;
			TCur(2) = Time;
			StateCur = StateL;
		end
		if stopit
			indices = (find(StateCur));
			teout = [teout;Time*ones(size(indices))'];
			ieout = [ieout;indices];
			qeout = [qeout;ones(size(indices))'*POLQ'];
			peout = [peout;ones(size(indices))'*POLP'];
			if (max(terminal(indices)) == 1)
				stop = logical(1);
				break;
			end
			if (Level > 0)
				TCur = TSave(:,Level);
				LeftCur = LeftSave(:,Level);
				RightCur = RightSave(:,Level);
				StateCur = ((LeftCur.*RightCur) <= 0) & (direction .* (RightCur - LeftCur) >= 0);
				Level = Level-1;

				TSave = TSave(:,1:Level);
				LeftSave = LeftSave(:,1:Level);
				RightSave = RightSave(:,1:Level);
			else
				break;
			end
		end
	end
	
