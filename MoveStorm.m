function MoveStorm(~,~)

    FigHandle=gcbf;
    Handles=get(FigHandle,'UserData');

    latitudeInterceptionParallel1.lon = [-82, -70];
    latitudeInterceptionParallel1.lat = [33.50, 33.50];
    latitudeInterceptionParallel4.lon = [-82, -70];
    latitudeInterceptionParallel4.lat = [36.00, 36.00];

    temp=get(gca,'CurrentPoint');
    newx=temp(1);

    tag=get(gco,'Tag');
    %disp(tag)
    
    switch tag
        case {'L1Line', 'L1Marker'}
           h=line(newx,latitudeInterceptionParallel1.lat(1),1,'Color','b','Marker','*','MarkerSize',20,'Tag','L1Marker','ButtonDownFcn',@MoveStorm);
           newp=newx-latitudeInterceptionParallel1.lon(1);
           i=5;
        case {'L2Line', 'L2Marker'}
           h=line(newx,latitudeInterceptionParallel4.lat(1),1,'Color','b','Marker','*','MarkerSize',20,'Tag','L2Marker','ButtonDownFcn',@MoveStorm);
           newp=newx-latitudeInterceptionParallel4.lon(1);
           i=6;
      
            
        otherwise
            disp('Selected object not part of moveable storm.')
    end
    
    set(Handles.ParameterControlsParameter(i),'String',sprintf('%6.2f',newp));
    
    SetUIStatusMessage('Re-evaluating model... \n')

    EvaluateModel;
  
    set(FigHandle,'Pointer','arrow');
    set(FigHandle,'WindowButtonUpFcn','');
    set(FigHandle,'WindowButtonMotionFcn','');
    
end
