function TransMatrix=Euler313(BigOmega,inc,theta)

    TransMatrix(1,1,:)=cos(BigOmega).*cos(theta) - sin(BigOmega).*cos(inc).*sin(theta);
    TransMatrix(1,2,:)=-cos(BigOmega).*sin(theta) - sin(BigOmega).*cos(inc).*cos(theta);
    TransMatrix(1,3,:)=sin(BigOmega).*sin(inc);

    TransMatrix(2,1,:)=sin(BigOmega).*cos(theta) + cos(BigOmega).*cos(inc).*sin(theta);
    TransMatrix(2,2,:)=-sin(BigOmega).*sin(theta) + cos(BigOmega).*cos(inc).*cos(theta);
    TransMatrix(2,3,:)=-cos(BigOmega).*sin(inc);

    TransMatrix(3,1,:)=sin(inc).*sin(theta);
    TransMatrix(3,2,:)=sin(inc).*cos(theta);
    TransMatrix(3,3,:)=cos(inc);
end