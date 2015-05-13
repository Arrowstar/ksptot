function state = psoboundsabsorb(state,Aineq,bineq,Aeq,beq,LB,UB,...
    nonlcon,options)

x = state.Population ;
v = state.Velocities ;

for i = 1:size(state.Population,1)
    lowindex = [] ; highindex = [] ;
    if ~isempty(LB), lowindex = x(i,:) < LB ; end
    if ~isempty(UB), highindex = x(i,:) > UB ; end
    % Check against bounded constraints
    x(i,lowindex) = LB(lowindex) ;
    x(i,highindex) = UB(highindex) ;
    v(i,lowindex) = 0 ;
    v(i,highindex) = 0 ;
    
    % Linear and nonlinear constraints
    if ~isempty(Aineq) || ~isempty(Aeq) || ~isempty(nonlcon)
        % "Sticky" linear inequality constraints
        if ~isempty(Aineq)
            if max(Aineq*x(i,:)' - bineq) > options.TolCon
                v(i,:) = 0 ;
            end % if Aineq
        end % if ~isempty
        
        % Won't do set velocities to zero for particles outside of
        % equality constraints, or else particles will rarely ever
        % move. This could change if "slippery" bounds are implemented
        % for linear constraints.
        
        % Finally update all particle positions
        if isempty(nonlcon)
            x(i,:) = linprog([],Aineq,bineq,Aeq,beq,LB,UB,...
                x(i,:),state.LinprogOptions) ;
        else % Check nonlinear constraints
            [c,ceq] = nonlcon(state.Population(i,:)) ;
            if any(c > options.TolCon) || ...
                    any(abs(ceq) > options.TolCon)
                v(i,:) = 0 ; % Sticky
                x(i,:) = fmincon(@void,state.Population(i,:),...
                    Aineq,bineq,Aeq,beq,LB,UB,...
                    nonlcon,state.LinprogOptions) ;
            end % if any
        end % if isempty
    end % if ~isempty
end % for i

state.Population = x ;
state.Velocities = v ;