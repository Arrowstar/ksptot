function [c,T,errOrder]=TT(x,derv)
    % Determine the coefficents to a finite differencing scheme
    % ie. find the coeffs [c1,c2,c3] that are appropriate for the 2nd order
    %     cent. diff. approx. to the first derivative :
    
    % (du/dx)[j] = 1/dx*(c1*u[j-1] + c2*u[j] + c3*u[j+1]) + error terms
    
    % Inputs:
    %     x - vector containing relative distances to sampling points
    %       ie. for example above would be x=[-1,0,1]
    %       ie. 5 terms full forward: x = [0,1,2,3,4]
    %       ie. 5 terms central :     x = [-2,-1,0,1,2]
    %
    %     derv - order of the derivative to approximate
    
    % Ouputs:
    %     c - the coefficients you're looking for!
    %     T optional output matrix showing the Taylor Table coefficents
    %     errOrder - lowest order of higher order terms
    %                (order of accuracy, ie. H.O.T. = O(dx^2) is 2nd order) 
%% The code:
    N=numel(x);  %number of unknowns
    T=zeros(N,N);
    for j=1:N  % do for each x
        for n=0:N+6 % Do for each coeff of the Taylor expansion
                    % (Expand out 6 extra terms for higher order accuracies
                    %   at higher derivatives)
            T(j,n+1)=-1/factorial(n)*x(j)^n;      
        end
    end
    % Vector holding place of the derivative
    d=zeros(N,1);
    d(derv+1)=-1;
 
    % Calculate the coefficients
    c=T(:,1:N)'\d;
    
    for i=1:numel(c)  % set any small value to 0
        if abs(c(i))<1E-10
            c(i)=0;
        end
   end
            
%% Determine the order of accuracy
    a=c'*T; %  Multiply the Taylor table coefficients by the finite difference
            %    coefficients and add up all like terms
            %  Terms that don't add to zero are the objective derivative
            %    and the residual higher order terms
            
        for i = 1:numel(a) % make sure values near zero = zero
            if abs(a(i))<1E-5;
                a(i)=0;
            end
        end
        
    pos=find(a,2);    % location of first nonzero term is the order of
                      % derivative you're approximating. Second nonzero
                      % term tells the lowest order of the higher order terms
    errOrder=pos(2)-1-derv;
                      % ie.   H.O.T. = O(dx^2) is 2nd order accuracy
                      %       H.O.T. = O(dx^4) is 4th order accuracy
    
    T=T(:,1:N); % Only output Taylor Table terms that are used   
