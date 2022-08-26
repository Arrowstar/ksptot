function msg = psogenerateoutputmessage(options,output,exitflag)

if exitflag == 0
    msg = sprintf('Reached limit of %g iterations', options.Generations) ;
elseif exitflag == 1
    msg = sprintf('Average cumulative change in value of the fitness') ;
    msg = sprintf('%s function over %g generations less than', msg, ...
        options.StallGenLimit) ;
    msg = sprintf('%s %g and constraint violation less than %g,', ...
        msg, options.TolFun, options.TolCon) ;
    msg = sprintf('%s after %g generations.', msg, output.generations) ;
elseif exitflag == 2
    msg = sprintf('Fitness limit %g reached and constraint violation', ...
        options.FitnessLimit) ;
    msg = sprintf('%s less than %g.', msg, options.TolCon) ;
elseif exitflag == 3
    msg = sprintf('The value of the fitness function did not improve in') ;
    msg = sprintf('%s the last %g generations and', ...
        msg, options.StallGenLimit) ;
    msg = sprintf('%s maximum constraint violation is less than %g,', ...
        msg, options.TolCon) ;
    msg = sprintf('%s after %g generations.', msg, output.generations) ;
elseif exitflag == -1
    msg = sprintf('Optimization stopped by user.') ;
elseif exitflag == -4
    msg = sprintf('The value of the fitness function did not improve in') ;
    msg = sprintf('%s the last %g seconds and', ...
        msg, options.StallTimeLimit) ;
    msg = sprintf('%s maximum constraint violation is less than %g,', ...
        msg, options.TolCon) ;
    msg = sprintf('%s after %g generations.', msg, output.generations) ;
elseif exitflag == -5
    msg = sprintf('Time limit of %s reached.',options.TimeLimit) ;
else
    msg = sprintf('Unrecognized exitflag value') ;
end % if exitflag