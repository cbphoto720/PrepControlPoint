close all; clear all; clc
addpath(genpath("C:\Users\Carson\Documents\Git\SIOCameraRectification"));
addpath("C:\Users\Carson\Documents\Git\cmcrameri\cmcrameri\cmaps") %Scientific color maps

%% Options

NUM_IMGsets=10;


%% Import iG8 data
f=msgbox("Please select the GPS survey file");
uiwait(f);

[file,location] = uigetfile('*.txt',"Select the GPS survey");
if isequal(file,0)
   disp('User selected Cancel');
else
   disp(['User selected ', fullfile(location,file)]);
   GPSpoints=importGPSpoints(fullfile(location,file));
end

%% Plot GPS points on a Map
load("hawaiiS.txt"); %load color map

plt=geoscatter(GPSpoints.Latitude(1),GPSpoints.Longitude(1),36,hawaiiS(1), "filled"); %plot the first point
geobasemap satellite
hold on
for i=1:NUM_IMGsets+1
    setname="set"+i;
    mask=strcmp(GPSpoints{:,2},setname);
    plt=geoscatter(GPSpoints.Latitude(mask,:),GPSpoints.Longitude(mask,:),36,hawaiiS(i,:),"filled");
end    
hold off

% Single out 1 point
% pointofintrest=13;
% geoscatter(GPSpoints.Latitude(pointofintrest),GPSpoints.Longitude(pointofintrest),250,[0,0,0],"filled","p")

% Set figure size
set(0,'units','pixels');
scr_siz = get(0,'ScreenSize');
set(gcf,'Position',[floor([10 50 scr_siz(3)*0.8 scr_siz(4)*0.5])]);


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

%% Select GPS points visible in cam
% GPSmask=false(size(GPSpoints,1),1);

f=msgbox("Draw a polygon around the points visible to the cam");
uiwait(f);
roi=drawpolygon();

if size(roi.Position)==[0,0]
    disp("failed to detect region of interest.  Try again.")
else
    GPSmask=inROI(roi,GPSpoints.Latitude,GPSpoints.Longitude);
end

%% mask of the GPS survey
        % save the survey file to a new folder (for future GPS reference
            % [don't need to draw ROI every time])
        % creat the UTC file in the new folder
        % create the LLZ file in the new folder
% Select the image folder containing files
        % confirm camera extension
        % copy img files to new folder with the corresponding # of points
            % per img