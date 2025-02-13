%{   
  _____                 _____            _             _ _____      _       _    __      _____  
 |  __ \               / ____|          | |           | |  __ \    (_)     | |   \ \    / /__ \ 
 | |__) | __ ___ _ __ | |     ___  _ __ | |_ _ __ ___ | | |__) |__  _ _ __ | |_   \ \  / /   ) |
 |  ___/ '__/ _ \ '_ \| |    / _ \| '_ \| __| '__/ _ \| |  ___/ _ \| | '_ \| __|   \ \/ /   / / 
 | |   | | |  __/ |_) | |___| (_) | | | | |_| | | (_) | | |  | (_) | | | | | |_     \  /   / /_ 
 |_|   |_|  \___| .__/ \_____\___/|_| |_|\__|_|  \___/|_|_|   \___/|_|_| |_|\__|     \/   |____|
                | |                                                                             
                |_|                                                                             

This program was created to streamline the process of rectifying camera
station images with control targets from an iG8 survey.  This program is
designed to work with PickControlPointV3, which is the interface for doing 
the rectifying.  Here, we will prepare a set of images to import into the 
PickControlPoint software, as well as generate the necessary files to link 
the coordinates with the items on screen.  

ᐠ⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝ᐟᐠ⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝ᐟᐠ⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝ᐟᐠ⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝ᐟᐠ⸜ˎ_ˏ⸝^⸜

Inputs{
- iG8_file.txt                      =   iG8 file with Code describing the which img set the point was a part of.  
                                        Code should be made in the field during collections (as a point description 
                                        from the iG8) but it can also be made after the fact.  It is common to make 
                                        mistakes or forget, so many GPS files have a _CORRECTED or _set-corrected 
                                        tag to indicate manual editing
        --> usually exported as "[YYYYMMDD]_[Location/Description].txt"
        --> Header= "Name Code Northings Eastings Elevation Longitude Latitude H Antenna_offset Solution Satellites PDOP Horizontal_error Vertical_error Time HRMS VRMS"

- UsableIMGS folder (contains .tif) =   An image set is ~30 seconds of images from the  camera station.  
                                        This is done to avoid beachgoers obscuring the targets.  Someone needs to 
                                        manually go into each image set and pick 1 frame where all GCPs are visible.
                                        For each image set, there needs to be **1 file** that this software uses to
                                        generate the required copies.  All usable images are named with the camera
                                        serial number, so 1 folder can contain images from multiple cameras, but no
                                        duplicate sets.
}

Outputs{
    **All outputs will fall into a defined folder

- [YYYYMMDD]Survey.llz              =    A data file of GPS points and local
                                    coordinates based off of the CAMERA's GPS position
- [YYYYMMDD]UTCimgSets.utc          =    Fake timing information generated to spoof PickControlPoint
                                    into assigning the correct order of image sets for rectification
- [YYYYMMDD]UTCimgSets_[IMG #].tif  =    Images will be copied into this naming structure for use in the 
                                    PickControlPoint.  There will be duplicate images depending on 
                                    the number of ground control targets in view
- CamExtrinsicEst.txt               =   A very rough guess at the local Pitch, Roll, Azimuth of the camera.  
                                    (The GPS position of the camera is the local survey Origin)
}

Credit to Levi Gorrell for writing PickControlPoint
Credit to Crameri, F. (2018). Scientific colour maps (hawaiiS.txt)

Created by Carson Black on 20240212.
ccblack@ucsd.edu
%}

%% Ask nicely before deleting
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
        addpath(genpath(fileparts(mfilename('fullpath'))))
        disp(fileparts(mfilename('fullpath')));
    case 'Cancel'
        close(fig);
        error('User selected cancel.  Please save you variables before getting started.')
end

%% Options
DefaultOpsFile="PCP_DefaultOptions.mat"; % Rename this file for multiple defaults!

if ~exist(DefaultOpsFile,'file')
    [UserPrefs,cancelled]=PrepOptionsGUI();
else
    [UserPrefs,cancelled]=PrepOptionsGUI(DefaultOpsFile);
end

if(cancelled==1)
    error('User selected cancel.')
elseif(UserPrefs.SetOptAsDefault) %handle storing new defaults file
    savepath = fullfile(fileparts(mfilename('fullpath')),DefaultOpsFile);
    DefAns=UserPrefs;
    save(savepath,"DefAns","-mat");
    clear DefAns savepath
end
clear cancelled DefaultOpsFile

% Pick Camera from database
[searchKeyoption,rowIDX]=PickCamFromDatabase(UserPrefs.CameraDB);

camStruct=importCameraData(UserPrefs.CameraDB, searchKeyoption); %WIP use rowIDX to verify and date confusion about the selected camera!

%% Select GPS file
GPSpoints=importGPSpoints(UserPrefs.GPSSurveyFile);

% Plot the GPS on a map
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
clear i
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
clear vec dir scale offsetx offsety a b c % clean up

[~,surveyName,~]=fileparts(UserPrefs.GPSSurveyFile);
figurename=strcat(surveyName,"_PLOT.png")
saveas(plt,fullfile(UserPrefs.OutputFolder,UserPrefs.OutputFolderName,figurename));
clear surveyName figurename


%%
%{
    ______                 __  _                 
   / ____/_  ______  _____/ /_(_)___  ____  _____
  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
 / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  ) 
/_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/  
                                                 
%}

function [searchKeyoption,rowIDX]=PickCamFromDatabase(path_to_SIO_CamDatabase)
    opts = detectImportOptions(path_to_SIO_CamDatabase, "Delimiter", "\t");

    opts.SelectedVariableNames = ["CamSN","CamNickname","Date"];
    opts.MissingRule="omitrow";
    CameraOptionsTable=readtable(path_to_SIO_CamDatabase,opts);

    CameraOptionsTable.Checkbox=false(height(CameraOptionsTable),1)

    Title = 'Pick camera profile from database';
    Options.Resize = 'on';
    Options.Interpreter = 'tex';
    Options.CancelButton = 'on';
    Options.ApplyButton = 'off';
    Options.ButtonNames = {'Continue','Cancel'};
    
    Prompt = {};
    Formats = {};

    Prompt(1,:) = {['Select only 1 camera station from the checkbox!'], [], []};
    Formats(1,1).type = 'text';
    Formats(1,1).size = [-1 0];

    Prompt(end+1,:) = {'Item Table','Table',[]};
    Formats(2,1).type = 'table';
    % Formats(1,1).format = {'char', {'left','right'}, 'numeric' 'logical'}; % table (= table in main dialog) / window (= table in separate dialog)
    Formats(2,1).items = {'CamSN' 'CamNickname' 'Date'};
    Formats(2,1).size = [-1 -1];
    DefAns.Table = table2cell(CameraOptionsTable);

    [answers, cancelled] = inputsdlg(Prompt, Title, Formats, DefAns, Options);

    if ~cancelled
        lastCol = cell2mat(answers.Table(:, end)); % Convert last column to logical/array
        numTrue = sum(lastCol); % Count the number of true values
        
        if numTrue ~= 1
            error('Please select only 1 camera!');
        else
            rowIDX = find(lastCol, 1); % Find the first row where true appears
            searchKeyoption=answers.Table{rowIDX, 1}; % Extract the first column value
        end
    else
        error('User selected cancel!');
    end
end