%%  SetColorMap
function SetColorMap(hObj,~) 

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    axes(Handles.MainAxes);

    nc=size(colormap,1);

    val = get(hObj,'Value');
    if val==1
        colormap(noaa_cmap(nc));
    elseif val ==2
        colormap(jet(nc))
    elseif val == 3
        colormap(hsv(nc))
    elseif val == 4
        colormap(hot(nc))
    elseif val == 5
        colormap(cool(nc))
    elseif val == 6
        colormap(gray(nc))
    elseif val == 7
        colormap(parula(nc))
    end
    
end
