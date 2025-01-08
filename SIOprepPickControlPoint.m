close all; clear all; clc
addpath(genpath("C:\Users\Carson\Documents\Git\SIOCameraRectification"));
addpath("C:\Users\Carson\Documents\Git\cmcrameri\cmcrameri\cmaps") %Scientific color maps

%% Options
maxPointsInSet=5; % The max number of ground control targets in a frame (usually 5)
date="20241023"; %date of survey
cameraSerialNumber=21217396; %The camera "Serial Number" is the 8 digit code included in the filename of the image e.g. 21217396


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
NUM_IMGsets=size(unique(GPSpoints(:,2)),1);

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
set(gcf,'Position',[floor([10 150 scr_siz(3)*0.8 scr_siz(4)*0.5])]);


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

%% Create new survey file base off points in ROI
% Prompt user for Camera number
prompt = {'Enter the Camera number for this site:'};
dlgtitle = 'Camera Number';
dims = [1 50];
definput = {'1'};
camnumber = inputdlg(prompt,dlgtitle,dims,definput);

% Create new file extension
smallfile=file;
smallfile=smallfile(1:end-4);
smallfile=smallfile+"_Camera"+camnumber{1}+".txt";

writetable(GPSpoints(GPSmask,:),fullfile(location,smallfile),"Delimiter"," ");
sprintf('Saved new GPS survey file of points visible to cam%d here: %s\n',camnumber,fullfile(location,smallfile))

%% Generate the files

% Generate number of frames from each survey set
num_of_IMGsets=unique(GPSpoints.Code(:));
IMGsetIDX=zeros(length(num_of_IMGsets),1);
for i=1:length(num_of_IMGsets)
    IMGsetIDX(i)=sum(GPSpoints.Code(:)==num_of_IMGsets(i));
end


imgtime=generateLeviUTC(size(num_of_IMGsets,1), IMGsetIDX, date, 'C:\Users\Carson\Documents\Git\SIOCameraRectification\data\20241023\NEW');
generateLeviLLZ(GPSpoints, date, imgtime, 'C:\Users\Carson\Documents\Git\SIOCameraRectification\data\20241023\NEW');

imgcopiersaver('C:\Users\Carson\Documents\Git\SIOCameraRectification\data\20241023\Annotated',...
    'C:\Users\Carson\Documents\Git\SIOCameraRectification\data\20241023\NEW', 5, '20241023UTCimgSets',cameraSerialNumber);


%% mask of the GPS survey
% Select the image folder containing files
        % confirm camera extension
        % copy img files to new folder with the corresponding # of points
            % per img.


% HAVE THE IMAGECOPIERSAVER ASK THE USER HOW MANY GCPs are visible for each
% image set