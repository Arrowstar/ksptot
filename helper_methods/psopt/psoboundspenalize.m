function state = ...
    psoboundspenalize(state,Aineq,bineq,Aeq,beq,LB,UB,nonlcon,options)
% This is like "soft" boundaries, except that some kind of penalty value
% must be calculated from the degree of each constraint violation.

x = state.Population ;
v = state.Velocities ;
n = size(state.Population,1) ;
state.OutOfBounds = false(n,1) ;
% state.InBounds = false(n,1) ;

for i = 1:n
    [c,ceq] = nonlconwrapper(nonlcon,Aineq,bineq,Aeq,beq,LB,UB,...
        options.TolCon,x(i,:)) ;

    if isempty([c,ceq])
        state.ConstrViolations = zeros(n,1) ;
        break
    end
    
    % Tolerances already dealt with in nonlconwrapper
    if sum([c,ceq]) ~= 0
        state.OutOfBounds(i) = true ;
         % Sticky boundaries: kills the inertia of the particle if
         % it is in a non-feasible region of the design space.
        v(i,:) = 0 ;
    end

    if i == 1
        nbrConstraints = size([c ceq],2) ;
        state.ConstrViolations = zeros(size(x,1),nbrConstraints) ;
    end
    state.ConstrViolations(i,:) = [c,ceq] ;
end % for i

% state.InBounds(setdiff((1:n)',find(state.OutOfBounds))) = true ;
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