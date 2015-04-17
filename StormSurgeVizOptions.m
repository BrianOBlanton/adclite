function p=StormSurgeVizOptions
% StormSurgeVizOptions - Parameters that can be used to influence the behavior
% of StormSurgeViz.  These are passed in as options to StormSurgeViz, or can be set 
% in the user's MyStormSurgeViz_Init.m.  A template MyStormSurgeViz_Init.m file is
% in the StormSurgeViz directory. 

p=struct;

% catalog parameters
p.Storm=[];
p.Advisory=[];
p.Grid=[];
p.Machine=[];
p.Instance='';
p.Url='';

% feature options
p.Verbose=true;
p.Debug=true;
p.DisableContouring=false;
p.LocalTimeOffset=0;
p.UseStrTree=false;
p.UseGoogleMaps=true;
p.UseShapeFiles=true;
p.KeepScalarsAndVectorsInSync=true;

p.Units={'Meters','Metric','Feet','English'};
p.DepthContours='10 50 100 500 1000 3000';  % depths must be enclosed in single quotes

% color options
p.ColorIncrement=.25;    % in whatever units
p.NumberOfColors=32;
p.ColorMax=NaN;
p.ColorMin=NaN;
p.ColorMap='noaa_cmap';
p.ColorBarLocation={'EastOutside','SouthOutside','NorthOutside','WestOutside','North','South','East','West'};


% GUI options
%ScreenTake=100; % percent of screen width to take up
p.AppWidthPercent=90;
p.FontOffset=2;
p.CanOutputShapeFiles=true;
p.DefaultShapeBinWidth=.5;  
p.GoogleMapsApiKey='';
p.SendDiagnosticsToCommandWindow=true;
p.ForkAxes=false;
p.UITest=false;
p.AppName='ADCL';

p.BoundingBox=[      -78.684      -74.867       33.317        37.08];
