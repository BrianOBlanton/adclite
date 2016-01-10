function p=AdcircLiteOptions
% AdcircLiteOptions - Parameters that can be used to influence the behavior
% of AdcircLite.  These are passed in as options to AdcircLite. 

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
p.UseInMemoryModel=false;
p.DisableContouring=false;
p.LocalTimeOffset=0;
p.UseStrTree=false;
p.UseGoogleMaps=true;
p.UseShapeFiles=true;
p.KeepScalarsAndVectorsInSync=true;

p.Units={'Meters','Metric','Feet','English'};
p.DepthContours='0 10 50 100 500 1000 3000';  % depths must be enclosed in single quotes

% color options
p.ColorIncrement=.25;    % in whatever units
p.NumberOfColors=32;
p.ColorMax=NaN;
p.ColorMin=NaN;
p.ColorMap='parula';
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

%p.BoundingBox=[      -85 -70        27       42];
p.BoundingBox=[   -79.156      -74.362       32.624       37.418];

