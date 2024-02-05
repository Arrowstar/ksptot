function [out,LM]=sqpstructout(opts,lambda_g,lambda_lb,lambda_ub,mg,nit,...
                               fval,nfcn,ngrd,alpha,normGradLagr)
% SQP.m utility function to return output as a data structure
out.fval       = opts(8);
out.funcCount  = opts(10);
out.gradCount  = opts(11);
out.iterations = opts(14);
out.constrviolation = mg;
out.options    = opts;
LM.ineq  = lambda_g;
LM.lower = lambda_lb;
LM.upper = lambda_ub;
out.lambda = LM;
if nargin>5,  out.iteration = nit;   end
if nargin>6,  out.fval      = fval;  end
if nargin>7,  out.funcCount = nfcn;  end
if nargin>8,  out.gradCount = ngrd;  end
if nargin>9,  out.stepsize  = alpha; end
if nargin>10, out.firstorderopt = normGradLagr; end
end
