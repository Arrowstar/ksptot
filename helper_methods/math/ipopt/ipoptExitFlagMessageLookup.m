function message = ipoptExitFlagMessageLookup(exitFlag)
    switch exitFlag
        case 0
            message = 'solved';
        case 1
            message = 'solved to acceptable level';
        case 2
            message = 'infeasible problem detected';
        case 3
            message = 'search direction becomes too small';
        case 4
            message = 'diverging iterates';
        case 5
            message = 'user requested stop';
            
        case -1
            message = 'maximum number of iterations exceeded';
        case -2
            message = 'restoration phase failed';
        case -3
            message = 'error in step computation';
        case -10
            message = 'not enough degrees of freedom';
        case -11
            message = 'invalid problem definition';
        case -12
            message = 'invalid option';
        case -13
            message = 'invalid number detected';
            
        case -100
            message = 'unrecoverable exception';
        case -101
            message = 'non-ipopt exception thrown';
        case -102
            message = 'insufficient memory';
        case -109
            message = 'internal error';
        otherwise
            message = 'Unknown exit flag';
    end
    
%           0  solved
%           1  solved to acceptable level
%           2  infeasible problem detected
%           3  search direction becomes too small
%           4  diverging iterates
%           5  user requested stop
%       
%          -1  maximum number of iterations exceeded
%          -2  restoration phase failed
%          -3  error in step computation
%         -10  not enough degrees of freedom
%         -11  invalid problem definition
%         -12  invalid option
%         -13  invalid number detected
%  
%        -100  unrecoverable exception
%        -101  non-ipopt exception thrown
%        -102  insufficient memory
%        -199  internal error
end