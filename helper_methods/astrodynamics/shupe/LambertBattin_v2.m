function [v_0_vec, v_vec, a, e, p] = LambertBattin_v2(r_0_vec, r_vec, delta_t, t_m, N)
%
% USAGE = [v_0_vec, v_vec, a, e, p] = LambertBattin_v2(r_0_vec, r_vec, delta_t, t_m, N)
%

% Function constants
% mu = 3.986e5;
mu = 398600.4418; % Sun gravitational constant (km^3/sec^2)
tol = 1e-6;
iter_max = 500;

r_0 = norm(r_0_vec);
r = norm(r_vec);

cos_delta_nu = dot(r_0_vec, r_vec) / (r_0 * r);
sin_delta_nu = t_m * sqrt(1 - cos_delta_nu^2);
delta_nu = atan2(sin_delta_nu, cos_delta_nu);
if delta_nu < 0
    
    delta_nu = 2 * pi + delta_nu;
    
end

c = sqrt(r_0^2 + r^2 - 2 * r_0 * r * cos_delta_nu);
s = (r_0 + r + c) / 2;

epsilon = (r - r_0) / r_0;
tan_sq_2w = (epsilon^2 / 4) / (sqrt(r / r_0) + (r / r_0) * (2 + sqrt(r / r_0)));
r_0p = sqrt(r_0 * r) * ((cos(delta_nu / 4))^2 + tan_sq_2w);

sin_sq_delta_nu_4 = (sin(delta_nu / 4))^2;
cos_sq_delta_nu_4 = (cos(delta_nu / 4))^2;
cos_delta_nu_2 = cos(delta_nu / 2);
if (delta_nu > 0) && (delta_nu < pi)
    
    l = (sin_sq_delta_nu_4 + tan_sq_2w) / (sin_sq_delta_nu_4 + tan_sq_2w + cos_delta_nu_2);
    
elseif (delta_nu > pi) && (delta_nu < 2*pi)
    
    l = (cos_sq_delta_nu_4 + tan_sq_2w - cos_delta_nu_2) / (cos_sq_delta_nu_4 + tan_sq_2w);
    
else
    
    error('Delta_nu out of range');
    
end

m = (mu * delta_t^2) / (8 * r_0p^3); 

if N == 0 
    
    % Initial estimate for x
    x_new = l;
    
    loop_flag = 1;
    i_iter = 1;
    while loop_flag == 1
    
        x_old = x_new;
        [x_new, y] = original_sub(x_old, l, m, N);
        
        if abs(x_new - x_old) < tol
            
            loop_flag = 0;
            
        elseif i_iter < iter_max
            
            i_iter = i_iter + 1;
            
        else
            
            loop_flag = 0;
            x_new = NaN;
            y = NaN;
            
        end
        
    end
    
    x_f = x_new;
    y_f = y;
    
else % N > 0
    
    loop_flag_R = 1;
    loop_flag_L = 1;
    i_iter_R = 1;
    i_iter_L = 1;
    
    % Initial estimate for x_R
    x_new = l;
    
    while loop_flag_R == 1
        
        x_old = x_new;
        [x_new, y] = reverse_sub(x_old, l, m, N);
        
        if y < 1
            
            % In divergent region for the reversed successive substitution
            % Begin original successive substitution to find x_L
            x_new = l;
            x_old = x_new;
            [x_new, y] = original_sub(x_old, l, m, N);
            
            while loop_flag_L == 1
                
                x_old = x_new;
                [x_new, y] = original_sub(x_old, l, m, N);

                if abs(x_new - x_old) < tol

                    loop_flag_L = 0;

                elseif i_iter_R < iter_max

                    i_iter_R = i_iter_R + 1;

                else

                    loop_flag_L = 0;
                    x_new = NaN;
                    y = NaN;

                end
                
            end
            
            y_L = y;
            x_L = x_new;
            
            % Reset initial guess for x_R
            x_new = x_new / 2;
            x_old = x_new - 2 * tol;
            
        end
        
        if abs(x_new - x_old) < tol
            
            loop_flag_R = 0;
            
        elseif i_iter_R < iter_max
            
            i_iter_R = i_iter_R + 1;
            
        else
            
            loop_flag_R = 0;
            x_new = NaN;
            y = NaN;
            
        end
        
    end
    
    y_R = y;
    x_R = x_new;
    
    % Only continue if x_L and y_L were not found in above iteration
    if loop_flag_L == 1
        
        % Initial estimate for x_L & y
        x_new = 2 * x_R;
        
        while loop_flag_L == 1

            x_old = x_new;
            [x_new, y] = original_sub(x_old, l, m, N);

            if abs(x_new - x_old) < tol

                loop_flag_L = 0;

            elseif i_iter_L < iter_max

                i_iter_L = i_iter_L + 1;

            else

                loop_flag_L = 0;
                x_new = NaN;
                y = NaN;

            end

        end
        
        y_L = y;
        x_L = x_new;
        
    end
    
    y_f = [y_R; y_L];
    x_f = [x_R; x_L];
    
end

if N == 0
    
    n = 1;
    
else
    
    n = 2;
    
end

a = zeros(n,1);
e = zeros(n,1);
p = zeros(n,1);
v_vec = zeros(n,3);
v_0_vec = zeros(n,3);
for i = 1:n

    a(i) = mu * delta_t^2 / (16 * r_0p^2 * x_f(i) * y_f(i)^2);
    e(i) = sqrt((epsilon^2 + 4 * (r / r_0) * (sin(delta_nu / 2))^2 * ((l - x_f(i)) / (l + x_f(i)))^2) / (epsilon^2 + 4 * (r / r_0) * (sin(delta_nu / 2))^2));
    p(i) = (4 * r_0p^2 * r_0 * r * y_f(i)^2 * (1 + x_f(i))^2 * (sin(delta_nu / 2))^2) / (mu * delta_t^2);
    if a(i) > 0
        
        f = 1 - (r / p(i)) * (1 - cos_delta_nu);
        g = (r * r_0 * sin_delta_nu) / sqrt(mu * p(i));
        g_dot = 1 - (r_0 / p(i)) * (1 - cos_delta_nu);
        
    else
        
        alpha_h = 2 * asinh(sqrt(s / (-2 * a(i))));
        beta_h = 2 * asinh(sqrt((s - c) / (-2 * a(i))));
        
        delta_H = alpha_h - beta_h;
        
        f = 1 - a(i) * (1 - cosh(delta_H)) / r;
        g = delta_t - sqrt(-a(i)^3 / mu) * (sinh(delta_H) - delta_H);
        g_dot = 1 - a(i) * (1 - cosh(delta_H)) / r;
        
    end
    
    v_0_vec(i,:) = (1 / g) .* (r_vec - f .* r_0_vec);
    v_vec(i,:) = (1 / g) .* (g_dot .* r_vec - r_0_vec);
    
end

%--------------------------------------------------------------------------

function [y] = cubic_solv(c1, c2, c3)

P = c2 - c1^2 / 3;
Q = c3 + (2 * c1^3 - 9 * c1 * c2) / 27;
D = Q^2 / 4 + P^3 / 27;

T = (-Q / 2 + sqrt(D))^(1/3) + (-Q/2 - sqrt(D))^(1/3);
y = T - c1 / 3;

%--------------------------------------------------------------------------

function [x_new, y] = original_sub(x_old, l, m, N)

E = 2 * atan(sqrt(x_old));
c = -m * (N * pi + E - sin(E)) / (4 * (tan(E / 2))^3);
y = cubic_solv(-1, 0, c);
x_new = sqrt(((1 - l) / 2)^2 + (m / y^2)) - ((1 + l) / 2);

%--------------------------------------------------------------------------

function [x_new, y] = reverse_sub(x_old, l, m, N)

y = sqrt(m / ((l + x_old) * (1 + x_old)));
E_0 = 2 * atan(sqrt(x_old));
E = y2E(E_0, y, m, N);
x_new = (tan(E / 2))^2;

%--------------------------------------------------------------------------

function [E] = y2E(E_0, y, m, N)

tol = 1e-6;
iter_max = 200;

q = 4 * (y^3 - y^2) / m;
h = (N * pi + E_0 - sin(E_0)) / (tan(E_0 / 2))^3 - q;

if h < 0
    
    loop_flag_h = 1;
    i_iter_h = 1;
    while loop_flag_h == 1
        
        E_0 = E_0 / 2;
        h = (N * pi + E_0 - sin(E_0)) / (tan(E_0 / 2))^3 - q;
        
        if h >= 0
            
            loop_flag_h = 0;
            
        elseif i_iter_h < iter_max
            
            i_iter_h = i_iter_h + 1;
            
        else
            
            loop_flag_h = 0;
            E_0 = NaN;
            
        end
        
    end
    
end

i_iter_E = 1;
loop_flag_E = 1;
while loop_flag_E == 1

    h = (N * pi + E_0 - sin(E_0)) / (tan(E_0 / 2))^3 - q;    
    h_prime = (-3 * (cos(E_0 / 2))^2) * (N * pi + E_0 - sin(E_0)) / (2 * (sin(E_0 / 2))^4) + (1 - cos(E_0)) / (tan(E_0 / 2))^3;
    E = E_0 - h / h_prime;
    
    if abs(E - E_0) < tol
        
        loop_flag_E = 0;
        
    elseif i_iter_E < iter_max
       
        i_iter_E = i_iter_E + 1;
        E_0 = E;
        
    else
        
        loop_flag_E = 0;
        E = NaN;
        
    end
    
end

