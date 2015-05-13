function state = ...
    psocheckbounds(options,state,Aineq,bineq,Aeq,beq,LB,UB,nonlcon)
% Check the the swarm population against all constraints.
%
% May 15, 2013
% Deprecated, replaced by PSOBOUNDSPENALIZE in the ./psopt folder.

x = state.Population ;
v = state.Velocities ;
n = size(state.Population,1) ;
state.OutOfBounds = false(n,1) ;
state.InBounds = false(n,1) ;

for i = 1:n
    lowindex = [] ; highindex = [] ;
    if ~isempty(LB), lowindex = x(i,:) < LB ; end
    if ~isempty(UB), highindex = x(i,:) > UB ; end
    % Four constraint types
    if strcmpi(options.ConstrBoundary,'soft')
        outofbounds = any([lowindex,highindex]) ;
        if ~outofbounds && ~isempty(Aineq)
            outofbounds = any(Aineq*x(i,:)' - bineq > options.TolCon) ;
        end % if ~isempty
        if ~outofbounds && ~isempty(Aeq)
            outofbounds = any(abs(Aeq*x(i,:)' - beq) > options.TolCon) ;
        end % if ~isempty
        
        if ~outofbounds && ~isempty(nonlcon) % Nonlinear constraint check
            c = nonlcon(x(i,:)) ;
            outofbounds = any(c > options.TolCon) ;
%                 any(abs(ceq) > options.TolCon);
        end
        
        if outofbounds
            state.Score(i) = inf ;
        end % if outofbounds
        
        state.OutOfBounds(i) = outofbounds ;
    elseif strcmpi(options.ConstrBoundary,'reflect')
        x(i,lowindex) = LB(lowindex) ;
        x(i,highindex) = UB(highindex) ;
        v(i,lowindex) = -v(i,lowindex) ;
        v(i,highindex) = -v(i,highindex);
    elseif strcmpi(options.ConstrBoundary,'absorb')
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
    elseif strcmpi(options.ConstrBoundary,'penalize')
        [c,ceq] = nonlconwrapper(nonlcon,Aineq,bineq,Aeq,beq,LB,UB,...
            options.TolCon,x(i,:)) ;

        % Tolerances already dealt with in nonlconwrapper
        if sum([c,ceq]) ~= 0
            state.OutOfBounds(i) = true ;
             % Sticky boundaries: kills the inertia of the particle if
             % it is in a non-feasible region of the design space.
            v(i,:) = 0 ;
        end

        if i == 1;
            nbrConstraints = size([c ceq],2) ;
            state.ConstrViolations = ...
                zeros(size(x,1),nbrConstraints) ;
            state.ConstrViolations(i,:) = [c,ceq] ;
        else
            state.ConstrViolations(i,:) = [c,ceq] ;
        end
    end % if strcmpi
end % for i

state.InBounds(setdiff((1:n)',find(state.OutOfBounds))) = true ;
state.Population = x ;
state.Velocities = v ;

function [c,ceq] = nonlconwrapper(nonlcon,Aineq,bineq,Aeq,beq,LB,UB,...
    TolCon,x)
% Wrapper function for combining evaluation of all constraints

c = [] ; ceq = [] ;
if ~isempty(nonlcon)
    [c,ceq] = nonlcon(x) ;
    c = reshape(c,1,[]) ; ceq = reshape(ceq,1,[]) ; % Robustness
end

if ~isempty(Aineq)
    c = [c, (Aineq*x' - bineq)'] ;
end

if ~isempty(LB)
    c = [c, LB - x] ;
end

if ~isempty(UB)
    c = [c, x - UB] ;
end

if ~isempty(Aeq)
    ceq = [ceq, abs(Aeq*x' - beq)'] ;
end

% Tolerances
if ~isempty(c)
    ceq(abs(ceq) < TolCon) = 0 ;
    c(c < 0) = 0 ;
end