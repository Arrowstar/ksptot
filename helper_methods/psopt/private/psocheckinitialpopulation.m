function [state,options,Aineq,bineq,Aeq,beq] = ...
    psocheckinitialpopulation(state,Aineq,bineq,Aeq,beq,LB,UB,nonlcon,...
    options)
% Checks initial population with respect to linear constraints. Requires
% optimization toolbox.

if exist('linprog','file') ~= 2
    msg = sprintf('Could not find a required function in Optimization ') ;
    msg = sprintf('%s Toolbox. Ignoring (non)linear constraints ',msg) ;
    msg = sprintf('%s for initial population distribution and',msg) ;
    warning('pso:linearconstraints:missingtoolbox',...
        '%s setting constraint behavior to ''soft''.',msg)
    options.ConstrBoundary = 'soft' ;
    return
end

% Some robustness for older versions of optimset
% vv = ver ;
% vernos = {vv.Version} ;
% if str2double(vernos{strcmpi({vv.Name},'MATLAB')}) < 7.7
%     state.LinprogOptions = optimset('Simplex','off',...
%         'LargeScale','off',...
%         'Display','off') ;
% else
    state.LinprogOptions = optimset('Simplex','off',...
        'LargeScale','off',...
        'Algorithm','active-set',...
        'Display','off') ;
% end

state.OutOfBounds = false(options.PopulationSize,1) ;

hw = waitbar(0,'Finding feasible initial positions...') ;
for i = 1:size(state.Population,1)
    if strcmpi(options.LinearConstr.type,'linearconstraints')
        if (~isempty([Aineq,bineq]) && any(Aineq*state.Population(i,:)' - bineq > options.TolCon)) ...
                || (~isempty([Aeq,beq]) && any(abs(Aeq*state.Population(i,:)' - beq) > ...
                options.TolCon))
            % Reposition the ith particle if it is outside of linear
            % constraint boundaries
            [newpoint,unused,exitflag] = ...
                linprog([],Aineq,bineq,Aeq,beq,LB,UB,...
                state.Population(i,:),...
                state.LinprogOptions) ;
            clear unused
            if exitflag == -2
                error('Problem is infeasible due to constraints')
            else
                state.Population(i,:) = reshape(newpoint,1,[]) ;
            end % if exitflag
        end
    elseif strcmpi(options.LinearConstr.type,'nonlinearconstraints')
        [c,ceq] = nonlcon(state.Population(i,:)) ;
        lineq = false ;
        if ~isempty(Aineq)
            lineq = Aineq*state.Population(i,:)' - bineq > ...
                    options.TolCon ;
        end
                
        % Check constraint boundary type
        if i==1 && ~isempty(ceq) && strcmpi(options.ConstrBoundary,'soft')
            msg = '''Soft'' boundaries don''t work with nonlinear' ;
            msg = sprintf('%s equality constraints.',msg) ;
            warning('pso:initpop:nonlcon',...
                '%s Changing options.ConstrBoundary to ''absorb''.',...
                msg)
            options.ConstrBoundary = 'absorb' ;
        end
        
        if isempty(ceq) && isempty(Aeq)
            % Keep trying random points within PopInitRange until we
            % find one that satisfies the nonlinear constraints.
            % This method is faster, but it depends on the user setting
            % appropriate values for PopInitRange. It doesn't work with
            % equality constraints, linear or nonlinear. If LB and UB
            % exist, PopInitRange should already have been set to match
            % them.
            while any(c > options.TolCon) || any(lineq)
                state.Population(i,:) = options.PopInitRange(1,:) + ...
                    rand(1,size(options.PopInitRange,2)) .* ...
                    (options.PopInitRange(2,:) - ...
                    options.PopInitRange(1,:)) ;
                c = nonlcon(state.Population(i,:)) ;
                if ~isempty(Aineq)
                    lineq = Aineq*state.Population(i,:)' - bineq > ...
                        options.TolCon ;
                end
            end % while any
        elseif any(c > options.TolCon) || any(abs(ceq) > options.TolCon)
%         if any(c > options.TolCon) || any(abs(ceq) > options.TolCon)
            % Random point rejection is much faster, and produces
            % a more uniform distribution of points within the bounded
            % region. However, using fmincon to find acceptable points will
            % allow simultaneous compliance with linear and boundary
            % constraints, as well as dealing well with nonlinear equality
            % constraints. Appropriate setting of PopInitRange will prevent
            % the initial points from accumulating near the boundaries.
            [newpoint,unused,exitflag] = ...
                fmincon(@void,state.Population(i,:),...
                Aineq,bineq,Aeq,beq,LB,UB,nonlcon,state.LinprogOptions) ;
            clear unused
            if exitflag == -2
                error('Problem is infeasible due to nonlinear constraints')
            else
                state.Population(i,:) = reshape(newpoint,1,[]) ;
            end % if exitflag
        end % if isempty
    end % if strcmpi
    waitbar(i/options.PopulationSize,hw)
end % for i
if ishandle(hw), close(hw), end