close all; clear all; clc
%% Import iG8 data
GPSpoints=importGPSpoints("20240819_FletcherCamGCPs");

%% Plot GPS points on a Map
close all;
red=[255,0,0]/255;
orange=[255, 208, 0]/255;
pink=[252, 3, 231]/255;
blue=[3, 235, 252]/255;
purple=[187, 0, 255]/255;

geoscatter(GPSpoints.Latitude(1:7),GPSpoints.Longitude(1:7),36,red)
hold on
geoscatter(GPSpoints.Latitude(8:16),GPSpoints.Longitude(8:16),36,orange)
geoscatter(GPSpoints.Latitude(17:23),GPSpoints.Longitude(17:23),36,pink)
geoscatter(GPSpoints.Latitude(24:28),GPSpoints.Longitude(24:28),36,blue)

% Single out 1 point
pointofintrest=13;
% geoscatter(GPSpoints.Latitude(pointofintrest),GPSpoints.Longitude(pointofintrest),250,[0,0,0],"filled","p")

% Set figure size
scr_siz = get(0,'ScreenSize') ;
set(gcf,'Position',[floor([10 50 scr_siz(3)*0.25 scr_siz(4)*0.75])]);


% Add labels
a=GPSpoints.Name;
b=num2str(a); c=cellstr(b);
% Randomize the label direction by creating a unit vector.
vec=-1+(1+1)*rand(length(GPSpoints.Name),2);
dir=vec./(((vec(:,1).^2)+(vec(:,2).^2)).^(1/2));
scale=0.000002; % offset text from point
% dir(:)=0; % turn ON randomization by commenting out this line
offsetx=-0.0000004+dir(:,1)*scale; % offset text on the point
offsety=-0.00000008+dir(:,2)*scale; % offset text on the point
text(GPSpoints.Latitude+offsety,GPSpoints.Longitude+offsetx,c)