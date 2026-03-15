function test_debug()
    body = KSPTOT_BodyInfo();
    body.gm = 398600.4415;
    body.radius = 6378.137;
    frame = body.getBodyCenteredInertialFrame();
    
    ut = [0, 100, 200];
    rVects = [[7000;0;0], [7100;0;0], [7200;0;0]];
    vVects = [[0;7.5;0], [0;7.4;0], [0;7.3;0]];
    
    carts = CartesianElementSet(ut, rVects, vVects, frame);
    fprintf('Carts size: %d x %d\n', size(carts,1), size(carts,2));
    
    try
        keps = carts.convertToKeplerianElementSet();
        fprintf('Conversion successful\n');
    catch ME
        fprintf('Error ID: %s\n', ME.identifier);
        fprintf('Error message: %s\n', ME.message);
        for i=1:length(ME.stack)
            fprintf('  File: %s, Name: %s, Line: %d\n', ME.stack(i).file, ME.stack(i).name, ME.stack(i).line);
        end
    end
end
