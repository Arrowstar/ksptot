function message = nomadExitFlagMessageLookup(exitflag)
    %as far as I know these only apply to NOMAD 3.9
    switch exitflag
        case 1
            message = 'Feasibility reached.';
        case 0
            message = 'One or more stop criteria maximums was reached.';
        case -1
            message = 'Solution did not converge.';
        case -2
            message = 'X0 or P1 fail.';
        case -3
            message = 'Unknown NOMAD stop reason.';
        case -5
            message = 'User requested stop.';
            
        otherwise
            message = 'Unknown NOMAD stop reason.';
    end
end

% double getStatus(int stat)
% {
%     switch((int)stat)
%     {        
%         case 5:         //mesh minimum
%         case 8:         //min mesh size
%         case 9:         //min poll size
%         case 20:        //ftarget reached
%         case 19:        //feas reached
%             return 1;
%             break;
%         case 12:        //max time
%         case 13:        //max bb eval
%         case 14:        //max sur eval
%         case 15:        //max evals
%         case 16:        //max sim bb evals
%         case 17:        //max iter   
%         case 23:        //max multi bb evals
%         case 24:        //max mads runs
%             return 0;
%             break;
%         case 10:        //max mesh index
%         case 11:        //mesh index limits
%         case 18:        //max consec fails
%         case 25:        //stagnation
%         case 26:        //no pareto
%         case 27:        //max cache memory
%             return -1;
%         case 6:         //x0 fail
%         case 7:         //p1_fail            
%             return -2;
%         case 2:         //Unknown stop reason
%             return -3; 
%         case 3:         //Ctrl-C
%         case 4:         //User-stopped
%             return -5;
%         default:        //Not assigned flag
%             return -3;        
%     }
% }