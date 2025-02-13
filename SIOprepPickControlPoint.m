% Tehcnically PrepControlPointV1
% now this is scratch paper for trying out pieces of the code

%% Ask before deleting
fig = uifigure;
msg = "About to wipe all variables! Are you sure you want to continue?";
title = "Start Program";
selection=uiconfirm(fig,msg,title, ...
    "Options",{'Ready to start','Cancel'}, ...
    "DefaultOption",1);
switch selection
    case 'Ready to start'
        % Close all figures, wipe all variables, start the program
        close(fig);
        close all; clear all; clc
    case 'Cancel'
        close(fig);
        error('User selected cancel.  Please save you variables before getting started.')
end
mfilename('fullpath')
%%
addpath(genpath("C:\Users\Carson\Documents\Git\SIOCameraRectification"));
addpath("C:\Users\Carson\Documents\Git\cmcrameri\cmcrameri\cmaps") %Scientific color maps

camSNdatabase=[21217396,22296748,22296760];

%% Options
maxPointsInSet=5; % The max number of ground control targets in a single frame (usually 5)
date="20250122"; %date of survey

cameraSerialNumber=21217396; %The camera "Serial Number" is the 8 digit code included in the filename of the image e.g. 21217396
% Seacliff Camera coordinates: ** VERY APPROXIMATE:    
GPSCamCoords=[36.9699953088, -121.9075239352, 31.333];


outputfolderpath="C:\Users\Carson\Documents\Git\SIOCameraRectification\data\20250122\CamB";
if ~isfolder(outputfolderpath)
    mkdir(outputfolderpath);
elseif isfolder(outputfolderpath)
    f=msgbox("Output folder already exists, make sure you don't overwrite another camera!",outputfolderpath);
    warning("Output folder already exists, make sure you don't overwrite another camera!\n%s",outputfolderpath);
end


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
prompt = {'Enter the Camera Letter for this site:'};
dlgtitle = 'Camera Name';
dims = [1 50];
definput = {'A'};
camnumber = inputdlg(prompt,dlgtitle,dims,definput);

% Create new file extension
smallfile=file;
smallfile=smallfile(1:end-4);
smallfile=smallfile+"_Camera"+camnumber{1}+".txt";

writetable(GPSpoints(GPSmask,:),fullfile(location,smallfile),"Delimiter"," ");
clear GPSpoints, GPSmask;
fprintf('Saved new GPS survey file of points visible to cam%s.  \nPlease re-load the file here to continue: %s\n',camnumber{1},fullfile(location,smallfile))

%% Generate the files

% Generate number of frames from each survey set
num_of_IMGsets=unique(GPSpoints.Code(:));
IMGsetIDX=zeros(length(num_of_IMGsets),1);
for i=1:length(num_of_IMGsets)
    IMGsetIDX(i)=sum(GPSpoints.Code(:)==num_of_IMGsets(i));
end


% Generate .utc
imgtime=generateLeviUTC(size(num_of_IMGsets,1), IMGsetIDX, date, outputfolderpath);

% Genereate .llz
firstpointOrigin=generateLeviLLZ(GPSpoints, date, imgtime, outputfolderpath);

% Copy images to the proper
imgcopiersaver('\\sio-smb.ucsd.edu\CPG-Projects-Ceph\SeacliffCam\20250123_GCP\usable-imgs',...
    outputfolderpath, IMGsetIDX,cameraSerialNumber);

%% Generate Camera Params (levi software)

 LocalCamCoordinates = GenerateCamExtrinsicEstimate(firstpointOrigin,GPSCamCoords, outputfolderpath);

%% read in the CamDatabase

opts = detectImportOptions("SIO_CamDatabase.txt", "Delimiter", "\t");

opts.SelectedVariableNames = ["CamSN","CamNickname","Date"];
opts.MissingRule="omitrow";
readtable("SIO_CamDatabase.txt",opts)