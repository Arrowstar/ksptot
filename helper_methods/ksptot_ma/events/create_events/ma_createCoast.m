function coast = ma_createCoast(name, coastType, coastToValue, revs, refBody, vars)
%ma_createCoast Summary of this function goes here
%   Detailed explanation goes here

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Valid coast type strings:
    % goto_ut        - goes to a specific Universal Time
    % goto_dt        - goes to a specific delta-time from the input state
    % goto_tru       - goes to a specific true anomaly
    % goto_apo       - goes to the next apogee
    % goto_peri      - goes to the next perigee
    % goto_asc_node  - goes to ascending node
    % goto_desc_node - goes to the descending node (asc node + pi)
    % goto_soi_trans - goes to the next SOI transition
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    coast = struct();
    coast.name         = name;
    coast.type         = 'Coast';
    coast.coastType    = coastType;
    coast.coastToValue = coastToValue;
    coast.revs         = revs;
    coast.refBody      = refBody;
    coast.id           = rand(1);
    coast.vars         = vars;
end

