function imgtime = generateLeviUTC(NUM_IMGsets,PointsInSet, date, path)
%generateLeviUTC: Create image set UTC file for us in PickControlPoint
%software

%{ 
Inputs:
    - NUM_IMGsets =   [#] How many different images are you using
    - MaxNUMPointsinSet = [#] What is the maximum # of points per img  
    - date    =   [yyyyMMdd](string) date of img capture
 Outputs: 
    - imgtime = [datetime vector] The artifical "times" when the images were taken.  Used
                to pass to generateLeviLLZ.m to sync the right GPS points to the img.

Created by Carson Black on 20241212.
ccblack@ucsd.edu
%}
%% Input Parsing
try
    capturedate=datetime(date,'InputFormat','yyyyMMdd');
catch
    error('Problem reading date.  Please use a char array or string [yyyymmdd]');
    % capturedate =datetime('20240101','InputFormat','yyyyMMdd');
end

p= inputParser;
validScalarPosNum = @(x) isnumeric(x) && isscalar(x) && (x > 0);
validPosNx1Matrix = @(x) isnumeric(x) && ismatrix(x) && size(x, 2) == 1 && all(x > 0);
validDate = @(x) datetime(capturedate,'Format','yyyyMMdd')==x;

addRequired(p, 'NUM_IMGsets',validScalarPosNum);
addRequired(p, 'PointsInSet',@(x) validScalarPosNum(x) || validPosNx1Matrix(x));
addRequired(p, 'date',validDate);
addRequired(p, 'path',@(x) isfolder(x));

parse(p,NUM_IMGsets,PointsInSet, date, path);
%% Generate data
if validPosNx1Matrix(PointsInSet)
    framenumber=[0:1:(sum(PointsInSet))-1]';
    
    starttime=datetime(date,'InputFormat','yyyyMMdd', 'Format', 'HH:mm:ss.SSS');
    arbitrary_interval=seconds(2);
    imgtime=starttime + (0:length(framenumber)-1)' * arbitrary_interval;
    
    varnames={'Framenumber','Time'};
    datatable=table(framenumber,imgtime,VariableNames=varnames);
else
    framenumber=[0:1:(NUM_IMGsets*PointsInSet)-1]';
    
    starttime=datetime(date,'InputFormat','yyyyMMdd', 'Format', 'HH:mm:ss.SSS');
    arbitrary_interval=seconds(2);
    imgtime=starttime + (0:length(framenumber)-1)' * arbitrary_interval;
    
    varnames={'Framenumber','Time'};
    datatable=table(framenumber,imgtime,VariableNames=varnames);
end

%% Create the text file
filename=strcat(date,'UTCimgSets.utc');

% Check if the file already exists
overwriteFile = true; % Default to overwriting or creating new file.
if exist(fullfile(path,filename),'file')
    promptMessage = sprintf('This file already exists:\n%s\nDo you want to overwrite it?', filename);
    titleBarCaption = 'Overwrite?';
    buttonText = questdlg(promptMessage, titleBarCaption, 'Yes', 'No', 'Yes');
    if strcmpi(buttonText, 'No')
        % User does not want to overwrite. 
        % Set flag to not do the write.
        overwriteFile = false;
        error('user chose not to overwrite the existing file');
    end
end
if overwriteFile
    fid=fopen(fullfile(path,filename),'w');

    fprintf(fid,'# of Frames: %d',size(datatable,1));
    for i=1:size(datatable,1)
        fprintf(fid, '\n%d) ',datatable{i,1});
        % fprintf(fid, '%.0s ',datatable{i,2});
        fprintf(fid, '%s:000',string(datetime(datatable{i,2},"Format",'MM/dd/yyyy HH:mm:ss:SSS')));
    end
    fclose(fid);
    
    fprintf('Success! File has been created here: %s\n',fullfile(path,filename))
end

end