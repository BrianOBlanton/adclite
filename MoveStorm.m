%%  MoveStorm
%%% MoveStorm
%%% MoveStorm
function MoveStorm(~,~)
 
    global Model
    
    FigHandle=gcbf;
    Handles=get(FigHandle,'UserData');
  
    %Lon_South_Offset = Model.CrossingLines.LatitudeInterceptionParallel1.lon(1);
    Lat_South_Offset = Model.CrossingLines.LatitudeInterceptionParallel1.lat(1);
    %Lon_North_Offset = Model.CrossingLines.LatitudeInterceptionParallel4.lon(1);
    Lat_North_Offset = Model.CrossingLines.LatitudeInterceptionParallel4.lat(1);
    
    temp=get(gca,'CurrentPoint');
    newx=temp(1);

    tag=get(gco,'Tag');
    %disp(tag)
    
    switch tag
        case {'L1Line', 'L1Marker'}
           h=line(newx,Lat_South_Offset,1,'Color','b','Marker','*','MarkerSize',20,'Tag','L1Marker','ButtonDownFcn',@MoveStorm);
           %newp=newx-latitudeInterceptionParallel1.lon(1);
           i=5;
        case {'L2Line', 'L2Marker'}
           h=line(newx,Lat_North_Offset,1,'Color','r','Marker','*','MarkerSize',20,'Tag','L2Marker','ButtonDownFcn',@MoveStorm);
           %newp=newx-latitudeInterceptionParallel4.lon(1);
           i=6;          
        otherwise
            disp('Selected object not part of moveable storm.')
    end
    
    set(Handles.ParameterControlsParameter(i),'DoubleValue',newx);
    %set(Handles.ParameterControlsParameterSliderTest(i),'String',num2str(newx));

    SetUIStatusMessage('Re-evaluating model... \n')

    EvaluateModel;
  
    set(FigHandle,'Pointer','arrow');
    set(FigHandle,'WindowButtonUpFcn','');
    set(FigHandle,'WindowButtonMotionFcn','');
    
end
