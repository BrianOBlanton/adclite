function DrawModel(varargin)

    global Debug % TheGrids
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

    P1=get(Handles.ParameterControlsParameter(1),'String');
    P1=str2double(P1);
    r=km2deg(P1);

    P5=get(Handles.ParameterControlsParameter(5),'String');
    P6=get(Handles.ParameterControlsParameter(6),'String');
    P5=str2double(P5);
    P6=str2double(P6);

    latitudeInterceptionParallel1.lon = [-82, -70];
    latitudeInterceptionParallel1.lat = [33.50, 33.50];
    latitudeInterceptionParallel4.lon = [-82, -70];
    latitudeInterceptionParallel4.lat = [36.00, 36.00];
    
    delete(findobj(Handles.MainAxes,'Tag','L1Marker'))
    delete(findobj(Handles.MainAxes,'Tag','L2Marker'))
    delete(findobj(Handles.MainAxes,'Tag','L1L2Path'))
    delete(findobj(Handles.MainAxes,'Tag','RMW_Circle'))

    

    h=line(latitudeInterceptionParallel1.lon,latitudeInterceptionParallel1.lat,[1 1],'Color','b','LineWidth',2,'Tag','L1Line','ButtonDownFcn',@MoveStorm);
    h=line(latitudeInterceptionParallel4.lon,latitudeInterceptionParallel4.lat,[1 1],'Color','r','LineWidth',2,'Tag','L2Line','ButtonDownFcn',@MoveStorm);
    
    h=line(latitudeInterceptionParallel1.lon(1)+P5,latitudeInterceptionParallel1.lat(1),1,'Color','b','Marker','*','MarkerSize',20,'Tag','L1Marker'); 
    moveit2(h);
    
    h=line(latitudeInterceptionParallel4.lon(1)+P6,latitudeInterceptionParallel4.lat(1),1,'Color','r','Marker','*','MarkerSize',20,'Tag','L2Marker'); 
    moveit2(h);
    h=line([latitudeInterceptionParallel1.lon(1)+P5 latitudeInterceptionParallel4.lon(1)+P6],...
           [latitudeInterceptionParallel1.lat(1)    latitudeInterceptionParallel4.lat(1)   ],...
           'Color','y','LineWidth',2,'Tag','L1L2Path','ButtonDownFcn','disp(''L1L2Path'')');
    h.ZData=ones(size(h.XData));

    h=circles(latitudeInterceptionParallel1.lon(1)+P5,latitudeInterceptionParallel1.lat(1),r,'Tag','RMW_Circle','Color','y','LineWidth',2,'ButtonDownFcn','disp(''RMW_Circle'')');
    h.ZData=ones(size(h.XData));

    
end