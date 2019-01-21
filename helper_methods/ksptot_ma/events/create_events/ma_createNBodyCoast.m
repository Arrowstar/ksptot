function coast = ma_createNBodyCoast(name, coastType, coastToValue, revs, refBody, vars, soiSkipIds, lineColor, lineStyle, lineWidth, massLoss, forceModel, maxPropTime)
%ma_createNBodyCoast Summary of this function goes here
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
    coast.name          = name;
    coast.type          = 'NBodyCoast';
    coast.coastType     = coastType;
    coast.coastToValue  = coastToValue;
    coast.revs          = revs;
    coast.refBody       = refBody;
    coast.id            = rand(1);
    coast.vars          = vars;
    coast.soiSkipIds    = soiSkipIds;
    coast.forceModel    = forceModel;
    coast.lineColor     = lineColor;
    coast.lineStyle     = lineStyle;
    coast.lineWidth     = lineWidth;
    coast.massloss      = massLoss;
    coast.maxPropTime   = maxPropTime;
end

