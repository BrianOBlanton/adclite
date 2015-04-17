
%%  ToggleElements
%%% ToggleElements
%%% ToggleElements
function ToggleElements(hObj,~)

    FigThatCalledThisFxn=gcbf;
    Handles=get(FigThatCalledThisFxn,'UserData');
    cv=get(Handles.TriSurf,'EdgeColor');
    if strcmp(cv,'none')
        set(Handles.TriSurf,'EdgeColor','k');
        set(hObj,'String','Hide Elements');
    else
        set(Handles.TriSurf,'EdgeColor','none');
        set(hObj,'String','Show Elements');
    end
    
end

