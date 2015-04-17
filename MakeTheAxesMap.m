%%  MakeTheAxesMap
%%% MakeTheAxesMap
%%% MakeTheAxesMap
function Handles=MakeTheAxesMap(Handles)

    global TheGrids Debug
    if Debug,fprintf('SSViz++ Function = %s\n',ThisFunctionName);end
   
    TheGrid=TheGrids{1};

    axes(Handles.MainAxes);
    
    FontSizes=getappdata(Handles.MainFigure,'FontSizes');    
    SSVizOpts=getappdata(Handles.MainFigure,'SSVizOpts');              
    ColorBarLocation=SSVizOpts.ColorBarLocation;
    HOME=SSVizOpts.HOME;
    DisableContouring=SSVizOpts.DisableContouring;

    axx=SSVizOpts.BoundingBox;
    if isnan(axx),axx=[min(TheGrid.x) max(TheGrid.x) min(TheGrid.y) max(TheGrid.y)];end
    cla
    
    Handles.GridBoundary=plotbnd(TheGrid,'Color','k');
    set(Handles.GridBoundary,'Tag','GridBoundary');
    nz=2*ones(size(get(Handles.GridBoundary,'XData')));
    set(Handles.GridBoundary,'ZData',nz)
    axis('equal')
    axis(axx)
    grid on
    box on
    hold on
    view(2)
    
    if ~isempty(which('contmex5'))  && ~DisableContouring
        SetUIStatusMessage('** Drawing depth contours ... \n')
        DepthContours=get(Handles.DepthContours,'String');
        DepthContours=sscanf(DepthContours,'%d');
        Handles.BathyContours=lcontour(TheGrid,TheGrid.z,DepthContours,'Color','k');
        
        for i=1:length(Handles.BathyContours)
            nz=2*ones(size(get(Handles.BathyContours(i),'XData')));
            set(Handles.BathyContours(i),'ZData',nz)
        end
        set(Handles.BathyContours,'Tag','BathyContours');
    else
        SetUIStatusMessage(sprintf('Contouring routine contmex5 not found for arch=%s.  Skipping depth contours.\n',computer))
        set(Handles.DepthContours,'Enable','off')
    end
 
%     if exist([HOME '/private/gomex_wdbII.cldat'],'file')
%         load([HOME '/private/gomex_wdbII.cldat'])
%         Handles.Coastline=line(gomex_wdbII(:,1),gomex_wdbII(:,2),...
%             'Tag','Coastline');
%     end
    if exist([HOME '/private/states.cldat'],'file')
        load([HOME '/private/states.cldat'])
        Handles.States=line(states(:,1),states(:,2),'Tag','States');
    end
    
    % add colorbar
    pms=Handles.ColormapSetter.String;
    idx=Handles.ColormapSetter.Value;
    cmap=eval(pms{idx});
    colormap(cmap)
    Handles.ColorBar=colorbar('Location',ColorBarLocation);
    set(Handles.ColorBar,'FontSize',FontSizes(2))
    set(get(Handles.ColorBar,'ylabel'),'FontSize',FontSizes(1));
    set(Handles.AxisLimits,'String',num2str(axx))

    SetUIStatusMessage('** Done.\n')

end
