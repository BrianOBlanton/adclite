function HUR=LoadHurs(d,ff)
% LoadHurs load ARA hur files
% HUR=LoadHurs(Directory,FileExtension)

if nargin==0
   d='./';
   files=dir('*.hur');

elseif exist(d,'dir')

   files=dir([d '/*.' ff]);
   
else

   hur=load(d);
   [pth,nm,ext]=fileparts(d);
   HUR.name=nm;
   HUR.t=datenum(hur(:,1),hur(:,2),hur(:,3),hur(:,4),0,0);
   HUR.lon=-hur(:,6);
   HUR.lat=hur(:,5);
   HUR.centpres=hur(:,7);
   HUR.rmw=hur(:,8);
   HUR.hollandb=hur(:,9);
   HUR.ambpres=hur(:,10);      
   HUR.tlen=HUR.t(end)-HUR.t(1);

   [x,y]=convll2m(HUR.lon,HUR.lat,HUR.lon(1),HUR.lat(1));
   dt=(HUR.t(3)-HUR.t(1))*86400;
   dx=x(3:end)-x(1:end-2);
   dy=y(3:end)-y(1:end-2);
   dxdt=dx/dt;
   dydt=dy/dt;
   dxdt1=(x(2)-x(1))/(dt/2);
   dxdtEnd=(x(end)-x(end-1))/(dt/2);
   dydt1=(y(2)-y(1))/(dt/2);
   dydtEnd=(y(end)-y(end-1))/(dt/2);
   
   HUR.uspd=[dxdt1; dxdt; dxdtEnd];
   HUR.vspd=[dydt1; dydt; dydtEnd];
   
end


if exist('files','var')
   for i=1:length(files)
      hur=load([d '/' files(i).name]);
      HUR(i).name=files(i).name;
      HUR(i).t=datenum(hur(:,1),hur(:,2),hur(:,3),hur(:,4),0,0);
      HUR(i).lon=-hur(:,6);
      HUR(i).lat=hur(:,5);
      HUR(i).centpres=hur(:,7);
      HUR(i).rmw=hur(:,8);
      HUR(i).hollandb=hur(:,9);
      HUR(i).ambpres=hur(:,10);      
      HUR(i).tlen=HUR(i).t(end)-HUR(i).t(1);
   end
end
