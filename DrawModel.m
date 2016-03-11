%%  DrawModel
%%% DrawModel
%%% DrawModel
function DrawModel(varargin)

    global Debug % TheGrids
    
    global Model
    
    if Debug,fprintf('AdcL++ Function = %s\n',ThisFunctionName);end

    if nargin==1
        if Debug,fprintf('AdcL++ %s called as a function\n',ThisFunctionName);end
        FigHandle=varargin{1};     
    else
        if Debug,fprintf('AdcL++ %s called as a callback\n',ThisFunctionName);end
        hObj=varargin{1};
        event=varargin{2};
        FigHandle=gcbf;
    end

    Handles=get(FigHandle,'UserData');
    
    P=getRsmParameters(Handles);

    Lon_South_Offset = Model.CrossingLines.LatSouth.lon(1);
    Lat_South_Offset = Model.CrossingLines.LatSouth.lat(1);
    Lon_North_Offset = Model.CrossingLines.LatNorth.lon(1);
    Lat_North_Offset = Model.CrossingLines.LatNorth.lat(1);

%    P1=Handles.ParameterControlsParameter(1).Value; 
    r=km2deg(P(1));

    %P5=Handles.ParameterControlsParameter(5).Value;
    %P6=Handles.ParameterControlsParameter(6).Value;
  
    delete(findobj(Handles.MainAxes,'Tag','LSLine'))
    delete(findobj(Handles.MainAxes,'Tag','LNLine'))
    delete(findobj(Handles.MainAxes,'Tag','LSMarker'))
    delete(findobj(Handles.MainAxes,'Tag','LNMarker'))
    delete(findobj(Handles.MainAxes,'Tag','LSLNPath'))
    delete(findobj(Handles.MainAxes,'Tag','RMW_Circle'))

    % these are the latitude lines that define the model
    h=line([Lon_South_Offset Lon_South_Offset+10],[Lat_South_Offset Lat_South_Offset],[1 1],'Color','b','LineWidth',2,'Tag','LSLine','ButtonDownFcn',@MoveStorm);
    h=line([Lon_North_Offset Lon_North_Offset+10],[Lat_North_Offset Lat_North_Offset],[1 1],'Color','r','LineWidth',2,'Tag','LNLine','ButtonDownFcn',@MoveStorm);
    
    h=line(P(5),Lat_North_Offset,1,'Color','r','Marker','*','MarkerSize',20,'Tag','LNMarker'); 
    moveit2(h);
    
    h=line(P(6),Lat_South_Offset,1,'Color','b','Marker','*','MarkerSize',20,'Tag','LSMarker'); 
    moveit2(h);

    
    
    h=line([P(5)  P(6)],...
           [Lat_South_Offset    Lat_North_Offset  ],...
           'Color','y','LineWidth',2,'Tag','L1L2Path','ButtonDownFcn','disp(''LSLNPath'')');
    h.ZData=10*ones(size(h.XData));

    
    
    h=circles(P(5),Lat_South_Offset,r,'Tag','RMW_Circle','Color','y','LineWidth',2,'ButtonDownFcn','disp(''RMW_Circle'')');
    h.ZData=10*ones(size(h.XData));
    
end
