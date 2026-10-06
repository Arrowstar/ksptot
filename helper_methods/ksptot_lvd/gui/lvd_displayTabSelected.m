function lvd_displayTabSelected(app)
%lvd_displayTabSelected Main window TabGroup SelectionChangedFcn: draws a
%ground track that plotTrajectory deferred while its tab was hidden.
    if(app.TabGroup.SelectedTab == app.GroundTrackTab)
        lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData');
        lvdData.viewSettings.selViewProfile.plotDeferredGroundTrack(lvdData, app);
    end
end
