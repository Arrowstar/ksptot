function[F,Fp,Fpp]=LambertEQ(x,tao,N,sig)
%% Description
% this function calculates components of the Lambert function given by
% Der Asrtodynamics for the Der_Sun_Lambert.m program. See page 27 of 
% 'The Superior Lambert Algorithm' by Gim J. Der
%% Input
% x - the value we are iterating to solve
% tao - from equation 9 in the paper
% N - number of revolutions
% sig - found earlier in the Der_Sun_Lamber.m problem

%% Calculations
temp1=x;
x=abs(x);

% determine y(x)
if sig^2~=0
    y=sign(sig)*sqrt(1-sig^2*(1-x^2));
elseif sig^2==1
    y=1;
end
if acot(x/sqrt(1-x^2))<0
    disp('Error1')
end
if acot(x/sqrt(1-x^2))>pi
    disp('Error2')
end
if acot(y/sqrt(1-y^2))<-pi/2
    disp('Error3')
end
if acot(y/sqrt(1-y^2))>pi/2
    disp('Error4')
end

theta = @(x) acot(x/sqrt(1-x^2))-1/(3*x)*(2+x^2)*sqrt(1-x^2);

% F(x,y) (as given by page 27 of article)
% added the absolute value to ensure the first term never goes below zero
% and the third term never goes imaginary
F=1/sqrt((1-x^2)^3)*(acot(x/sqrt(1-x^2))-acot(y/sqrt(1-y^2))-sqrt(x*(1-x^2))+sqrt(y*(1-y^2))+N*pi-tao);



%x=temp1; % restores the sign of x
% dF(x,y)/dx 
Fp=1/(1-x^2)*(3*x*tao-2*(1-sig^3)*x/abs(y));

% d^2F(x,y)/dx^2
Fpp=1/(x*(1-x^2))*((1+4*x^2)*Fp+2*(1-sig^5)*x^3/abs(y)^3);

%% Alternate:
%F=theta(x)+theta(y)-N*pi-tao;
%Fp=2*(1-x^2)^3/2*(sig^6*x^3*sqrt(1-x^2)+sqrt(-sig^2*(-1+x^2)*y)+sig^2*(-1+x^2)*sqrt(-sig^2*(-1+x^2)*y))/...
%    (3*x^2*sqrt(-sig^2*(-1+x^2))*y^3/2);
%Fpp=1/(x*(1-x^2))*((1+4*x^2)*Fp+2*(1-sig^5)*x^3/abs(y)^3);


    