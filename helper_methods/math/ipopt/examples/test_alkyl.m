%
% Original source
% http://www.mat.univie.ac.at/~neum/glopt/coconut/Benchmark/Library1/alkyl.mod
%
function test_alkyl
  
  addpath('../lib') ;

  auxdata = {} ;
  options.lb = [ 0, 0,   0,   0, 0, 0.85, 0.9,  3,  1.2, 1.45, 0.99, 0.99, 0.9, 0.99 ] ;
  options.ub = [ 2, 1.6, 1.2, 5, 2, 0.93, 0.95, 12, 4,   1.62, 1.01010101010101, 1.01010101010101, 1.11111111111111, 1.01010101010101 ] ;

  % The constraint functions are bounded to zero
  options.cl = zeros(1,7); %  constraints
  options.cu = zeros(1,7);
  
  % Set up the auxiliary data.
  options.auxdata = auxdata ;
  
  % Set the IPOPT options.
  options.ipopt.jac_d_constant   = 'no';
  options.ipopt.hessian_constant = 'no';
  options.ipopt.mu_strategy      = 'adaptive';
  options.ipopt.max_iter         = 400;
  options.ipopt.tol              = 1e-10;
  options.ipopt.linear_solver    = 'ma57';
  %options.ipopt.linear_solver    = 'mumps';
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
    options.ipopt.limited_memory_update_type = 'bfgs' ; % {bfgs}, sr1 = 6; % {6}
    options.ipopt.derivative_test            = 'first-order';
  end

  % Run IPOPT.
  x0 = [ 1.745,   ...
         1.2,     ...
         1.1,     ...
         3.048,   ...
         1.974,   ...
         0.893,   ...
         0.928,   ...
         8,       ...
         3.6,     ...
         1.45,    ...
         1,       ...
         1,       ...
         1,       ...
         1 ] ; 

  tic
  [x, info] = ipopt_auxdata(x0,funcs,options);
  elapsed = toc ;

  info;

  x

end

%%
% map the indices with the corresponding index in the spase matrix
function f = objective( x, auxdata )
  x2  = x(1) ;
  x3  = x(2) ;
  x4  = x(3) ;
  x5  = x(4) ;
  x6  = x(5) ;
  x7  = x(6) ;
  x8  = x(7) ;
  x9  = x(8) ;
  x10 = x(9) ;
  x11 = x(10) ;
  x12 = x(11) ;
  x13 = x(12) ;
  x14 = x(13) ;
  x15 = x(14) ;
  f   = - 6.3*x5*x8 + 5.04*x2 + 0.35*x3 + x4 + 3.36*x6 ;
end

%% 
% map the indices with the corresponding index in the spase matrix
function g = gradient(x,auxdata)
  x2  = x(1) ;
  x3  = x(2) ;
  x4  = x(3) ;
  x5  = x(4) ;
  x6  = x(5) ;
  x7  = x(6) ;
  x8  = x(7) ;
  x9  = x(8) ;
  x10 = x(9) ;
  x11 = x(10) ;
  x12 = x(11) ;
  x13 = x(12) ;
  x14 = x(13) ;
  x15 = x(14) ;
  g   = [ 5.04, 0.35, 1, -6.3*x8, 3.36, 0, -6.3*x5, 0, 0, 0, 0, 0, 0, 0 ] ;
end

function c = constraints(x,auxdata)
  x2  = x(1) ;
  x3  = x(2) ;
  x4  = x(3) ;
  x5  = x(4) ;
  x6  = x(5) ;
  x7  = x(6) ;
  x8  = x(7) ;
  x9  = x(8) ;
  x10 = x(9) ;
  x11 = x(10) ;
  x12 = x(11) ;
  x13 = x(12) ;
  x14 = x(13) ;
  x15 = x(14) ;
  e2  =  - 0.819672131147541*x2 + x5 - 0.819672131147541*x6 ;
  e3  = 0.98*x4 - x7*(0.01*x5*x10 + x4) ;
  e4  =  - x2*x9 + 10*x3 + x6 ;
  e5  = x5*x12 - x2*(1.12 + 0.13167*x9 - 0.0067*x9*x9) ;
  e6  = x8*x13 - 0.01*(1.098*x9 - 0.038*x9*x9) - 0.325*x7 - 0.57425;
  e7  = x10*x14 + 22.2*x11 - 35.82;
  e8  = x11*x15 - 3*x8 + 1.33 ;
  c   = [e2;e3;e4;e5;e6;e7;e8] ;
end

function jac = jacobian(x,auxdata)
  x2  = x(1) ;
  x3  = x(2) ;
  x4  = x(3) ;
  x5  = x(4) ;
  x6  = x(5) ;
  x7  = x(6) ;
  x8  = x(7) ;
  x9  = x(8) ;
  x10 = x(9) ;
  x11 = x(10) ;
  x12 = x(11) ;
  x13 = x(12) ;
  x14 = x(13) ;
  x15 = x(14) ;

  jac = sparse(7,14) ;
  
  jac(1,1) = -0.819672131147541 ;
  jac(1,4) = 1 ;
  jac(1,5) = -0.819672131147541 ;
  
  jac(2,3) = 0.98 - x7 ;
  jac(2,4) = -x7*(0.01*x10);
  jac(2,6) = -(0.01*x5*x10 + x4);
  jac(2,9) = - x7*(0.01*x5);
  
  jac(3,1) = -x9 ;
  jac(3,2) = 10 ;
  jac(3,5) = 1 ;
  jac(3,8) = -x2 ;

  jac(4,1)  = -(1.12 + 0.13167*x9 - 0.0067*x9*x9) ;
  jac(4,4)  = x12 ;
  jac(4,8)  = -x2*(0.13167 - 2*0.0067*x9) ;
  jac(4,11) = x5 ;

  jac(5,6)  = -0.325;
  jac(5,7)  = x13 ;
  jac(5,8)  = - 0.01*(1.098 - 2*0.038*x9) ;
  jac(5,12) = x8 ;

  jac(6,9)  = x14;
  jac(6,10) = 22.2;
  jac(6,13) = x10;

  jac(7,7)  = -3 ;
  jac(7,10) = x15 ;
  jac(7,14) = x11 ;

end

function jac = jacobianstructure(auxdata)
  jac = sparse(7,14) ;
  
  jac(1,1) = 1 ;
  jac(1,4) = 1 ;
  jac(1,5) = 1 ;
  
  jac(2,3) = 1 ;
  jac(2,4) = 1 ;
  jac(2,6) = 1 ;
  jac(2,9) = 1 ;
  
  jac(3,1) = 1 ;
  jac(3,2) = 1 ;
  jac(3,5) = 1 ;
  jac(3,8) = 1 ;

  jac(4,1)  = 1 ;
  jac(4,4)  = 1 ;
  jac(4,8)  = 1 ;
  jac(4,11) = 1 ;

  jac(5,6)  = 1 ;
  jac(5,7)  = 1 ;
  jac(5,8)  = 1 ;
  jac(5,12) = 1 ;

  jac(6,9)  = 1 ;
  jac(6,10) = 1 ;
  jac(6,13) = 1 ;

  jac(7,7)  = 1 ;
  jac(7,10) = 1 ;
  jac(7,14) = 1 ;
end

function H = hessian(x, sigma, L, auxdata)

  x2  = x(1) ;
  x3  = x(2) ;
  x4  = x(3) ;
  x5  = x(4) ;
  x6  = x(5) ;
  x7  = x(6) ;
  x8  = x(7) ;
  x9  = x(8) ;
  x10 = x(9) ;
  x11 = x(10) ;
  x12 = x(11) ;
  x13 = x(12) ;
  x14 = x(13) ;
  x15 = x(14) ;

  Hf = sparse(14,14) ;
  Hf(4,7) = -6.3 ;
  Hf(7,4) = -6.3 ;

  H2 = sparse(14,14) ;
  H2(3,6) = -1 ;
  H2(6,3) = -1;
  H2(4,6) = -(0.01*x10) ;
  H2(6,4) = -(0.01*x10);
  H2(4,9) = -x7*0.01 ;
  H2(9,4) = -x7*0.01 ;
  H2(6,9) = -(0.01*x5);
  H2(9,6) = -(0.01*x5);

  H3 = sparse(14,14) ;
  H3(1,8)  = -1 ;
  H3(8,1)  = -1 ;

  H4 = sparse(14,14) ;
  H4(1,8)  = -(0.13167 - 2*0.0067*x9) ;
  H4(8,1)  = -(0.13167 - 2*0.0067*x9) ;
  H4(4,11) = 1 ;
  H4(11,4) = 1 ;
  H4(8,8)  = x2*2*0.0067 ;

  H5 = sparse(14,14) ;
  H5(7,12) = 1 ;
  H5(12,7) = 1 ;
  H5(8,8)  = 0.01*(2*0.038) ;

  H6 = sparse(14,14) ;  
  H6(9,13) = 1;
  H6(13,9) = 1;

  H7 = sparse(14,14) ;
  H7(10,14) = 1 ;
  H7(14,10) = 1 ;

  H  = tril(sparse(sigma * Hf + L(2)*H2 + L(3)*H3 + L(4)*H4 + L(5)*H5 + L(6)*H6 + L(7)*H7)) ;
end

function H = hessianstructure(auxdata)

  Hf = sparse(14,14) ;
  Hf(4,7) = 1;
  Hf(7,4) = 1;

  H2 = sparse(14,14) ;
  H2(3,6) = 1;
  H2(6,3) = 1;
  H2(4,6) = 1;
  H2(6,4) = 1;
  H2(4,9) = 1;
  H2(9,4) = 1;
  H2(6,9) = 1;
  H2(9,6) = 1;

  H3 = sparse(14,14) ;
  H3(1,8) = 1;
  H3(8,1) = 1;

  H4 = sparse(14,14) ;
  H4(1,8)  = 1;
  H4(8,1)  = 1;
  H4(4,11) = 1;
  H4(11,4) = 1;
  H4(8,8)  = 1;

  H5 = sparse(14,14) ;
  H5(7,12) = 1;
  H5(12,7) = 1;
  H5(8,8)  = 1;

  H6 = sparse(14,14) ;  
  H6(9,13) = 1;
  H6(13,9) = 1;

  H7 = sparse(14,14) ;
  H7(10,14) = 1 ;
  H7(14,10) = 1 ;

  H = tril(sparse(Hf+H2+H3+H4+H5+H6+H7)) ;
end
