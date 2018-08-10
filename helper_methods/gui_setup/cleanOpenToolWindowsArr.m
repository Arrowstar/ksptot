function openToolWindows = cleanOpenToolWindowsArr(openToolWindows)
    openToolWindows(~ishghandle(openToolWindows)) = [];
end