function [Obj,x0,A,b,Aeq,beq,vlb,vub,Con,Opts]=sqpcrkfmincon(Problem)
% SQP.m utility function to convert fmincon's Problem data structure
% to input argument list for sqp.
if isstruct(Problem)
   Obj  = Problem.objective;
   x0   = Problem.x0;
   if isfield(Problem,'lb'), vlb = Problem.lb; else vlb=[]; end
   if isfield(Problem,'ub'), vub = Problem.ub; else vub=[]; end
   if isfield(Problem,'nonlcon'), Con  = Problem.nonlcon; else Con=[];  end
   if isfield(Problem,'Aineq'),   A    = Problem.Aineq;   else A=[]; end
   if isfield(Problem,'bineq'),   b    = Problem.bineq;   else b=[]; end
   if isfield(Problem,'Aeq'),     Aeq  = Problem.Aeq;     else Aeq=[];  end
   if isfield(Problem,'beg'),     beq  = Problem.beq;     else beq=[];  end
   if isfield(Problem,'options'), Opts = Problem.options; else Opts=[]; end
else
   error('sqp:sqpcrkfmincon','Single argument to sqp must be a data structure.')
end
end
