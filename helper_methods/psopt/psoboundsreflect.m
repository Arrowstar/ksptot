function state = ...
    psoboundsreflect(state,Aineq,bineq,Aeq,beq,LB,UB,nonlcon,options)

x = state.Population ;
v = state.Velocities ;

for i = 1:size(state.Population,1)
    lowindex = [] ; highindex = [] ;
    if ~isempty(LB), lowindex = x(i,:) < LB ; end
    if ~isempty(UB), highindex = x(i,:) > UB ; end
    
    x(i,lowindex) = LB(lowindex) ;
    x(i,highindex) = UB(highindex) ;
    v(i,lowindex) = -v(i,lowindex) ;
    v(i,highindex) = -v(i,highindex);
end % for i

state.Population = x ;
state.Velocities = v ;