function test_ipopt

  auxdata = {} ;

  options.lb = [ -Inf, -Inf ] ;  % Lower bound on the variables.
  options.ub = [  Inf, Inf ] ;  % Upper bound on the variables.

  % The constraint functions are bounded to zero
  options.cl = [ 0, 0, -Inf ]; %  constraints
  options.cu = [ Inf, Inf, 0];
  
  % Set up the auxiliary data.
  options.auxdata = auxdata ;
  
  % Set the IPOPT options.
  options.ipopt.jac_d_constant   = 'no';
  options.ipopt.hessian_constant = 'no';
  options.ipopt.mu_strategy      = 'adaptive';
  options.ipopt.max_iter         = 400;
  options.ipopt.tol              = 1e-10;
  
  % The callback functions.
  funcs.objective         = @objective;
  funcs.constraints       = @constraints;
  funcs.gradient          = @gradient;
  funcs.jacobian          = @jacobian;
  funcs.jacobianstructure = @jacobianstructure;
  if true
    options.ipopt.derivative_test = 'first-order';
    funcs.hessian           = @hessian;
    funcs.hessianstructure  = @hessianstructure;
  else
    options.ipopt.hessian_approximation      = 'limited-memory';
    %options.ipopt.limited_memory_update_type = 'bfgs' ; % {bfgs}, sr1 = 6; % {6}
    %options.ipopt.limited_memory_update_type = 'sr1' ;
    options.ipopt.limited_memory_update_type = 'bfgs' ; % {bfgs}, sr1 = 6; % {6}
  end

  % Run IPOPT.
  x0 = [-2, 1] ; 

  tic
  [x, info] = ipopt_auxdata(x0,funcs,options);
  elapsed = toc ;

  info;

  x

end

%%
% map the indices with the corresponding index in the spase matrix
function f = objective(x,auxdata)
  f = 100*(x(2)-x(1)^2)^2+(1-x(1))^2 ;
end

%% 
% map the indices with the corresponding index in the spase matrix
function g = gradient(x,auxdata)
  g = [ 400*x(1)*(x(1)^2-x(2))+2*x(1)-2, ...
        200*(x(2)-x(1)^2) ] ;
end

function f = constraints(x,auxdata)
  f = zeros(3,1) ;
  f(1) = x(1)*x(2)-1 ; % = 0
  f(2) = x(1) + x(2)^2 ; % >= 0
  f(3) = x(1) ;
end

function jac = jacobian(x,auxdata)
  jac = sparse([ x(2), x(1)   ; ...
                 1,    2*x(2) ; ...
                 1,    0 ]) ;
end

function jac = jacobianstructure(auxdata)
  jac = sparse(ones(3,2)) ;
end

function H = hessian(x, sigma, lambda, auxdata)
  H = sigma * [ 1200*x(1)^2-400*x(2)+2, 0 ; ...
                 -400*x(1)               200] ;
  H = H + lambda(1) * [ 0 0 ; 1 0 ] ;
  H = H + lambda(2) * [ 0 0 ; 0 2 ] ;
  H = sparse(H) ;
end

function H = hessianstructure(auxdata)
  H = sparse([ 1 0 ; 1 1]) ;
end
