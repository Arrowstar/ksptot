
function test_BartholomewBiggs
  
  addpath('../lib') ;

  auxdata = {} ;

  options.lb = [ 1, 1, 1, 1 ] ; % Lower bound on the variables.
  options.ub = [ 5, 5, 5, 5 ] ; % Upper bound on the variables.

  % The constraint functions are bounded to zero
  options.cl = [0,   0]; %  constraints
  options.cu = [inf, 0];
  
  % Set up the auxiliary data.
  options.auxdata = auxdata ;
  
  % Set the IPOPT options.
  options.ipopt.jac_d_constant   = 'no';
  options.ipopt.hessian_constant = 'no';
  options.ipopt.mu_strategy      = 'adaptive';
  options.ipopt.max_iter         = 400;
  options.ipopt.tol              = 1e-10;
  %options.ipopt.linear_solver    = 'ma57';
  options.ipopt.linear_solver    = 'mumps';
  %options.ipopt.linear_solver    = 'pardiso';
  
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
  x0 = [ 1, 5, 5, 1 ] ; 

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
  x3 = x(3) ;
  x4 = x(4) ;
  f  = x1*x4*(x1+x2+x3) + x3 ;
end

%% 
% map the indices with the corresponding index in the spase matrix
function g = gradient(x,auxdata)
  x1 = x(1) ;
  x2 = x(2) ;
  x3 = x(3) ;
  x4 = x(4) ;
  g  = [ x4*(2*x1+x2+x3), x1*x4, x1*x4 + 1, x1*(x1+x2+x3)] ;
end

function c = constraints(x,auxdata)
  x1 = x(1) ;
  x2 = x(2) ;
  x3 = x(3) ;
  x4 = x(4) ;
  c  = [ x1*x2*x3*x4 ; x1^2+x2^2+x3^2+x4^2 - 40 ] ;
end

function jac = jacobian(x,auxdata)
  x1 = x(1) ;
  x2 = x(2) ;
  x3 = x(3) ;
  x4 = x(4) ;
  jac = sparse([ x2*x3*x4, x1*x3*x4, x1*x2*x4, x1*x2*x3 ; ...
                 2*x1, 2*x2, 2*x3, 2*x4 ]) ;
end

function jac = jacobianstructure(auxdata)
  jac = sparse(ones(2,4)) ;
end

function H = hessian(x, sigma, lambda, auxdata)
  x1 = x(1) ;
  x2 = x(2) ;
  x3 = x(3) ;
  x4 = x(4) ;
  Hf = [ 2*x4,      x4,  x4, 2*x1+x2+x3 ; ...
         x4,         0,   0, x1         ; ...
         x4,         0,   0, x1         ; ...
         2*x1+x2+x3, x1, x1, x1         ] ;
         
  H1 = [ 0, x3*x4, x2*x4, x2*x3 ; ...
         x3*x4, 0, x1*x4, x1*x3 ; ...
         x2*x4, x1*x4, 0, x1*x2 ; ...
         x2*x3, x1*x3, x1*x2, 0 ] ;

     H2 = 2*eye(4,4) ;
  H  = tril(sparse(sigma * Hf + lambda(1)*H1 + lambda(2)*H2)) ;
end

function H = hessianstructure(auxdata)
  H = tril(sparse(ones(4,4))) ;
end
