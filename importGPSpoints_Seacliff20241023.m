close all; clear all; clc
addpath(genpath("C:\Users\Carson\Documents\Git\SIOCameraRectification"));
addpath("C:\Users\Carson\Documents\Git\cmcrameri\cmcrameri\cmaps") %Scientific color maps

%% Import iG8 data
GPSpoints=importGPSpoints("20241023_SeacliffcamCGPIG81_2024-10-23-12-09-00");

%% Clean up data import based on comments in the GPS file:
% Be careful that index numbers change once you start deleting points!
% This script uses "codes" to group out sets of GCPs directly from the iG8.
% Add the comments in the field or you can manually add set# in the second 
% column of the data.

GPSpoints(1,:)=[];
GPSpoints(8,:)=[]; %same as point 9
GPSpoints(43,:)=[];

GPSpoints{5,2}="set1"; %rename the reshoot
GPSpoints{6,2}="set2"; %rename the mislabel
GPSpoints{45,2}="set9"; %rename the reshoot

%% Plot options
NUM_IMGsets=10;

%% Plot GPS points on a Map
close all;

load("hawaiiS.txt"); %load color map

plt=geoscatter(GPSpoints.Latitude(1),GPSpoints.Longitude(1),36,hawaiiS(1), "filled");
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
scr_siz = get(0,'ScreenSize') ;
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

%% Scratch paper

imgtime=generateLeviUTC(10,5, '20241023', 'C:\Users\Carson\Documents\Git\SIOCameraRectification\data\20241023\RAW');

%%

i=1;

wgs84 = wgs84Ellipsoid; % Define ellipsoid
origin = [GPSpoints.Latitude(1),GPSpoints.Longitude(1),GPSpoints.Elevation(1)]; % Set first point as origin
% Convert lat, lon to local coordinate system
[test.xEast,test.yNorth,test.zUp] = geodetic2enu(GPSpoints.Latitude,GPSpoints.Longitude,GPSpoints.Elevation,origin(1),origin(2),origin(3),wgs84);

%% Call Python script in order to modify the capture date of the img

% % MATLAB Script to Modify Image Metadata Using Python
% inputFile = 'C:\Users\Carson\Documents\Git\SIOCameraRectification\data\20241023\Annotated\Seacliff_1729704839\Seacliff_21217396_1729704851254.tif';  % Replace with your image path
% outputFile = 'modified_image.tif'; % Output file path
% newDate = '2024:10:23 15:30:00';   % Date format: YYYY:MM:DD HH:MM:SS
% 
% % Python script to run
% pythonScript = 'update_metadata.py';
% 
% % Construct the system command
% command = sprintf('python %s "%s" "%s" "%s"', pythonScript, inputFile, outputFile, newDate);
% 
% % Execute the Python script
% [status, cmdout] = system(command);
% 
% % Check for success
% if status == 0
%     disp('Metadata updated successfully.');
%     disp(cmdout);
% else
%     disp('Error occurred while updating metadata:');
%     disp(cmdout);
% end
%% Validate that the img date has changed
function imageDate = getImageDate(imagePath)
    % Get the image format (JPEG or TIFF)
    [~,~,ext] = fileparts(imagePath);
    ext = lower(ext);
    
    % Initialize the imageDate variable
    imageDate = '';
    
    if strcmp(ext, '.jpg') || strcmp(ext, '.jpeg')
        % For JPEG, use exiftool or MATLAB's imfinfo to extract EXIF data
        try
            info = imfinfo(imagePath);
            % Check if DateTimeOriginal (36867) exists in EXIF
            if isfield(info, 'DigitalCamera')
                imageDate = info.DigitalCamera.DateTimeOriginal;
            elseif isfield(info, 'ImageDateTime')
                imageDate = info.ImageDateTime;
            else
                disp('DateTime not found in JPEG EXIF metadata.');
            end
        catch
            disp('Error reading JPEG EXIF metadata.');
        end
        
    elseif strcmp(ext, '.tif') || strcmp(ext, '.tiff')
        % For TIFF, use Tiff class to extract metadata
        try
            tiffInfo = Tiff(imagePath, 'r');
            metadata = tiffInfo.getTag(306);  % Tag 306 is DateTime for TIFF
            if ~isempty(metadata)
                imageDate = metadata;
            else
                disp('DateTime not found in TIFF metadata.');
            end
            tiffInfo.close();
        catch
            disp('Error reading TIFF metadata.');
        end
        
    else
        disp('Unsupported image format. Please use JPG or TIFF.');
    end
    
    % Display the result
    if ~isempty(imageDate)
        disp(['The image capture date is: ', imageDate]);
    else
        disp('No valid capture date found.');
    end
end

imagePath = 'modified_image.tif';  % Specify your image path
getImageDate(imagePath);

%% Call python script to rename and move file images to create 
% callPythonImageCopier('C:\Users\Carson\Documents\Git\SIOCameraRectification\data\20241023\Annotated',...
%     'C:\Users\Carson\Documents\Git\SIOCameraRectification\data\20241023\RAW', 5, '20241023UTCimgSets')

%%
x='20241023';
generateLeviLLZ(GPSpoints, '20241023', imgtime, 'C:\Users\Carson\Documents\Git\SIOCameraRectification\data\20241023\RAW');

%% Call Matlab img copier/saver
% 
imgcopiersaver('C:\Users\Carson\Documents\Git\SIOCameraRectification\data\20241023\Annotated',...
    'C:\Users\Carson\Documents\Git\SIOCameraRectification\data\20241023\RAW', 5, '20241023UTCimgSets');