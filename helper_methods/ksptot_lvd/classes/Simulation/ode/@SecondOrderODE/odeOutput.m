function status = odeOutput(t,y,yp,flag, intStartTime, maxIntegrationDuration)
    integrationDuration = toc(intStartTime);

    status = 0;
    if(integrationDuration > maxIntegrationDuration)
        status = 1;
    end
end