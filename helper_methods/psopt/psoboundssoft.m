function state = ...
    psoboundssoft(state,Aineq,bineq,Aeq,beq,LB,UB,nonlcon,options)

x = state.Population ;
% v = state.Velocities ;

for i = 1:size(state.Population,1)
    lowindex = [] ; highindex = [] ;
    if ~isempty(LB), lowindex = x(i,:) < LB ; end
    if ~isempty(UB), highindex = x(i,:) > UB ; end
    
    outofbounds = any([lowindex,highindex]) ;
    if ~outofbounds && ~isempty(Aineq) % Check linear inequalities
        outofbounds = any(Aineq*x(i,:)' - bineq > options.TolCon) ;
    end % if ~isempty
    if ~outofbounds && ~isempty(Aeq) % Check linear equalities
        outofbounds = any(abs(Aeq*x(i,:)' - beq) > options.TolCon) ;
    end % if ~isempty
    if ~outofbounds && ~isempty(nonlcon) % Nonlinear constraint check
        [c,ceq] = nonlcon(x(i,:)) ;
        outofbounds = any(c > options.TolCon) ;
        outofbounds = outofbounds || any(abs(ceq) > options.TolCon) ;
    end
    
    if outofbounds
        state.Score(i) = inf ;
    end % if outofbounds
    
    state.OutOfBounds(i) = outofbounds ;
end % for i

state.Population = x ;
% state.Velocities = v ;