
%#  NLP written by GAMS Convert at 06/20/02 11:29:54
%#  
%#  Equation counts
%#     Total       E       G       L       N       X
%#         3       2       1       0       0       0
%#  
%#  Variable counts
%#                 x       b       i     s1s     s2s      sc      si
%#     Total    cont  binary integer    sos1    sos2   scont    sint
%#         5       5       0       0       0       0       0       0
%#  FX     0       0       0       0       0       0       0       0
%#  
%#  Nonzero counts
%#     Total   const      NL     DLL
%#        12       6       6       0
%# 
%#  Reformualtion has removed 1 variable and 1 equation
%
%
%var x1 := 50, >= 50, <= 200;
%var x2 := 37.5, >= 37.5, <= 150;
%var x3 := 45, >= 45, <= 180;
%var x4;
%
%minimize obj: 0.00533*x1^2 + 11.669*x1 + 0.00889*x2^2 + 10.333*x2 + 0.00741*x3^
%              2 + 10.833*x3 + 653.1;
%
%subject to
%
%e2:  - (0.01*(0.0676*x1*x1 + 0.00953*x1*x2 - 0.00507*x1*x3 + 0.00953*x2*x1 + 
%    0.0521*x2*x2 + 0.00901*x2*x3 - 0.00507*x3*x1 + 0.00901*x3*x2 + 0.0294*x3*x3
%    ) - 0.000766*x1 - 3.42e-5*x2 + 0.000189*x3) + x4 = 0.040357;
%
%e3:    x1 + x2 + x3 - x4 >= 210;

function test_ipopt

  auxdata = {} ;

  options.lb = [ 50, 37.5, 45, -Inf ] ;  % Lower bound on the variables.
  options.ub = [ 200, 150, 180, Inf ] ;  % Upper bound on the variables.

  % The constraint functions are bounded to zero
  options.cl = [ 0, 0 ]; %  constraints
  options.cu = [ 0, Inf ];
  
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
  x0 = [50, 37.5, 45, 0] ; 

  tic
  [x, info] = ipopt_auxdata(x0,funcs,options);
  elapsed = toc ;

  info;

  x

end

%%
% map the indices with the corresponding index in the spase matrix
function f = objective(x,auxdata)
  f = 0.00533*x(1)^2 + 11.669*x(1) + ...
      0.00889*x(2)^2 + 10.333*x(2) + ...
      0.00741*x(3)^2 + 10.833*x(3) + 653.1 ;
end

%% 
% map the indices with the corresponding index in the spase matrix
function g = gradient(x,auxdata)
  g = [ 0.01066*x(1) + 11.669, 0.01778*x(2) + 10.333, 0.01482*x(3) + 10.833, 0 ] ;
end

function f = constraints(x,auxdata)
  f = zeros(2,1) ;
  f(1) = - (0.01*(0.0676*x(1)^2 + 0.00953*x(1)*x(2) - 0.00507*x(1)*x(3) + ...
                  0.00953*x(2)*x(1) + 0.0521*x(2)^2 + 0.00901*x(2)*x(3) - ...
                  0.00507*x(3)*x(1) + 0.00901*x(3)*x(2) + 0.0294*x(3)*x(3) ) ...
         - 0.000766*x(1) - 3.42e-5*x(2) + 0.000189*x(3)) + x(4) - 0.040357 ; % = 0
  f(2) = x(1) + x(2) + x(3) - x(4) - 210 ; % >= 0
end

function jac = jacobian(x,auxdata)
  jac = [ -0.001352*x(1) - 0.0001906*x(2) + 0.0001014*x(3) + 0.000766, ...
          -0.0001906*x(1) - 0.001042*x(2) - 0.0001802*x(3) + 0.0000342, ...
           0.0001014*x(1) - 0.0001802*x(2) - 0.000588*x(3) - 0.000189, ...
           1 ; 1, 1, 1, -1 ] ;
  jac = sparse(jac) ;
end

function jac = jacobianstructure(auxdata)
  jac = sparse(ones(2,4)) ;
end

function H = hessian(x, sigma, lambda, auxdata)
  H1 = [ 0.01066 0       0       0 ; ...
         0       0.01778 0       0 ; ...
         0       0       0.01482 0 ; ...
         0       0       0       0 ] ;
  H2 = [ -0.1352e-2,          0,         0, 0 ; ...
         -0.1906e-3, -0.1042e-2,         0, 0 ; ...
          0.0001014, -0.1802e-3, -0.588e-3, 0 ; ...
          0,                  0,         0, 0 ] ;
  H = sparse(sigma*H1 + lambda(1)*H2) ;
end

function H = hessianstructure(auxdata)
  H = sparse([ 1 0 0 0 ; 1 1 0 0 ; 1 1 1 0 ; 1 1 1 1 ]) ;
end
