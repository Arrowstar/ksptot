
function test_McCormick
  
  addpath('../lib') ;

  auxdata = {} ;

  options.lb = [ -1.5, -3 ] ; % Lower bound on the variables.
  options.ub = [    4,  3 ] ; % Upper bound on the variables.

  % The constraint functions are bounded to zero
  options.cl = []; %  constraints
  options.cu = [];
  
  % Set up the auxiliary data.
  options.auxdata = auxdata ;
  
  % Set the IPOPT options.
  options.ipopt.jac_d_constant   = 'no';
  options.ipopt.hessian_constant = 'no';
  options.ipopt.mu_strategy      = 'adaptive';
  options.ipopt.max_iter         = 400;
  options.ipopt.tol              = 1e-10;
  options.ipopt.linear_solver    = 'mumps'; % ma57, pardiso
  
  % The callback functions.
  funcs.objective         = @objective;
  funcs.constraints       = @constraints;
  funcs.gradient          = @gradient;
  funcs.jacobian          = @jacobian;
  funcs.jacobianstructure = @jacobianstructure;
  if true
    funcs.hessian           = @hessian;
    funcs.hessianstructure  = @hessianstructure;
    options.ipopt.derivative_test = 'second-order';
  else
    options.ipopt.hessian_approximation      = 'limited-memory';
    %options.ipopt.limited_memory_update_type = 'bfgs' ; % {bfgs}, sr1 = 6; % {6}
    %options.ipopt.limited_memory_update_type = 'sr1' ;
    options.ipopt.limited_memory_update_type = 'bfgs' ; % {bfgs}, sr1 = 6; % {6}
  end

  % Run IPOPT.
  x0 = [ 0, 0 ] ; 

  tic
  [x, info] = ipopt_auxdata(x0,funcs,options);
  elapsed = toc ;

  info;

  x

end

%%
% map the indices with the corresponding index in the spase matrix
function f = objective( x, auxdata )
  x1 = x(1) ;
  x2 = x(2) ;
  f  = sin(x1+x2)+(x1-x2)^2-1.5*x1+2.5*x2+1 ;
end

%% 
% map the indices with the corresponding index in the spase matrix
function g = gradient(x,auxdata)
  x1 = x(1) ;
  x2 = x(2) ;
  g  = [ cos(x1+x2)+2*(x1-x2)-1.5, cos(x1+x2)-2*(x1-x2)+2.5 ] ;
end

function f = constraints(x,auxdata)
  f = zeros(0,1) ;
end

function jac = jacobian(x,auxdata)
  jac = sparse(0,0) ;
end

function jac = jacobianstructure(auxdata)
  jac = sparse(0,0) ;
end

function H = hessian(x, sigma, lambda, auxdata)
  x1 = x(1) ;
  x2 = x(2) ;
  tmp = -sin(x1+x2) ;
  H   = sigma * tril(sparse([ tmp+2, tmp-2 ; tmp-2, tmp+2 ])) ;
end

function H = hessianstructure(auxdata)
  H = tril(sparse( [ 1, 1 ; 1, 1 ])) ;
end
