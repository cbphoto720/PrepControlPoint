function returnData = readSIO_CamDatabase(Path_to_SIO_CamDatabase, options)
%% Import the SIO_CamDatabase file as a table OR data from a specific camera or subset of cameras!
%       Optional input arguments: CamSN=1234, CamNickname="Human_Readable",
%       DateofGCP=[Datetime OR yyyyMMdd], MultiCamMode=true/flase
% Output:
% ----------------
%   If you choose not to specify any options:
%       - ReturnData (Cell Vector)  :   The entire SIO Camera Database files, complete with 
%                                       camera Coordinates, intrinsics, poses, and the local origins
%   
%
%   Default output when input options are specified:
%       - ReturnData (struct)       :   Camera coordinates, intrinsics, pose, and the local origin
%           -> ReturnData,ReturnData.Intrinsics, ReturnData.Pose, ReturnData.LocalOrigin
%   Output with "MultiCamMode=true" argument:
%       - ReturnData (table)        :   Camera coordinates, intrinsics, pose, and the local origin
%
% Input Arguments:
% ----------------
%       - Path_to_SIO_CamDatabase (string)  :   Full path to the SIO Camera Database file.
%
%   If you want to specify a DateofGCP, CamSN, or CamNickname by
%   using the one or all of following optional input args:
%       - CamSN (numeric)           : Camera serial number
%       - CamNickname (string)      : Camera nickname
%       - DateofGCP (datetime/string)    : Date in 'YYYYMMDD' format or datetime of the last GCP survey for this site
%       - MultiCamMode (logical)       :   Change export mode from Struct to table
%      
%   **  If you aren't specific enough, you will be asked to provide more
%       keywords because there are multiple entries matching your information.
%
%   **  It is highly likely you will need to include the DateofGCP in order to
%       nail down a specific database entry.  If you don't know the DateofGCP,
%       either look in the Database, or specify what you do know and the
%       error function will give you multiple results you can pick from.
%
%   **  Use MultiCamMode to return all rows that fit your criteria.  (useful
%       for all cams on 1 survey date, or all dates a specific CamSN was surveyed)
%
%
% Examples: 
% ----------------
%       - FullDatabaseTable (table) = readSIOCamDatabase(Path_to_SIO_CamDatabase)
%
%       - SeacliffCamA (struct) = readSIOCamDatabase(Path_to_SIO_CamDatabase,DateofGCP=20250122,CamSN=21217396)
%           -> SeacliffCamA,SeacliffCamA.Intrinsics, SeacliffCamA.Pose, SeacliffCamA.LocalOrigin
%
%       - SecliffCamA (table) = readSIOCamDatabase(Path_to_SIO_CamDatabase,DateofGCP=20250122,CamSN=21217396,MultiCamMode=true)
%           -> A table view of a specific camera
%
%       - SecliffCamA (table) = readSIOCamDatabase(Path_to_SIO_CamDatabase,DateofGCP=20250122,MultiCamMode=true)
%           -> A table of all cameras that were surveyed on the given date
%
% Written by Carson Black 20240214
arguments
    Path_to_SIO_CamDatabase (1,1) string {mustBeValidFile}
    options.CamSN (1,1) {mustBeNumeric} = getDefaultOptions().CamSN;
    options.CamNickname (1,1) {mustBeText} = getDefaultOptions().CamNickname;
    options.DateofGCP (1,1) {mustBeValidDate} = getDefaultOptions().DateofGCP;
    options.MultiCamMode (1,1) {mustBeNumericOrLogical} = getDefaultOptions().MultiCamMode;
end

% Standardize dates to datetime
if isnumeric(options.DateofGCP)
    options.DateofGCP=datetime(options.DateofGCP,"ConvertFrom","yyyyMMdd");
elseif isstring(options.DateofGCP) || ischar(options.DateofGCP)
    options.DateofGCP=datetime(options.DateofGCP,"Format","yyyyMMdd");
end

%% Yaml Import data

% Load YAML file
yamlData = yaml.loadFile(Path_to_SIO_CamDatabase); % Returns a cell array of structs

% Define the required field order
requiredFields = ["CamSN", "CamNickname", "DateofGCP", "Northings", "Eastings", "Height", ...
    "UTMzone", "skew", "PrincipalPoint_U", "PrincipalPoint_V", "FocalLength_X", "FocalLength_Y", ...
    "RadialDistortion_1", "RadialDistortion_2", "RadialDistortion_3", ...
    "TangentialDistortion_1", "TangentialDistortion_2", "ImageSize_U", "ImageSize_V", ...
    "pitch", "roll", "azimuth", "originUTMnorthing", "originUTMeasting", "theta"];

% Initialize an empty array for the table data with proper data types
numEntries = numel(yamlData);
dataCell = cell(numEntries, numel(requiredFields));

% Iterate through each camera entry
for i = 1:numEntries
    cam = yamlData{i}; % Extract the camera struct
    
    % Populate fields
    dataCell{i, 1} = str2double(cam.CamSN);  % Convert to numeric
    dataCell{i, 2} = string(cam.CamNickname); % Keep as string
    
    % Handle DateofGCP as datetime, using try-catch for invalid entries
    try
        dataCell{i, 3} = datetime(cam.DateofGCP, 'Format', 'yyyyMMdd');
    catch
        dataCell{i, 3} = NaT;  % Set to NaT if conversion fails
    end
    
    % Position Data
    dataCell{i, 4} = str2double(cam.Position.Northings);
    dataCell{i, 5} = str2double(cam.Position.Eastings);
    dataCell{i, 6} = str2double(cam.Position.Height);
    dataCell{i, 7} = str2double(cam.Position.UTMzone);
    
    % Intrinsics
    dataCell{i, 8} = str2double(cam.Intrinsics.Skew);
    dataCell{i, 9} = str2double(cam.Intrinsics.PrincipalPoint_U);
    dataCell{i, 10} = str2double(cam.Intrinsics.PrincipalPoint_V);
    dataCell{i, 11} = str2double(cam.Intrinsics.FocalLength_X);
    dataCell{i, 12} = str2double(cam.Intrinsics.FocalLength_Y);
    dataCell{i, 13} = str2double(cam.Intrinsics.RadialDistortion_1);
    dataCell{i, 14} = str2double(cam.Intrinsics.RadialDistortion_2);
    dataCell{i, 15} = str2double(cam.Intrinsics.RadialDistortion_3);
    dataCell{i, 16} = str2double(cam.Intrinsics.TangentialDistortion_1);
    dataCell{i, 17} = str2double(cam.Intrinsics.TangentialDistortion_2);
    dataCell{i, 18} = str2double(cam.Intrinsics.ImageSize_U);
    dataCell{i, 19} = str2double(cam.Intrinsics.ImageSize_V);
    
    % Orientation
    dataCell{i, 20} = str2double(cam.Position.pitch);
    dataCell{i, 21} = str2double(cam.Position.roll);
    dataCell{i, 22} = str2double(cam.Position.azimuth);
    
    % Local Coordinate System
    dataCell{i, 23} = str2double(cam.LocalCoordinateSystem.originUTMnorthing);
    dataCell{i, 24} = str2double(cam.LocalCoordinateSystem.originUTMeasting);
    dataCell{i, 25} = str2double(cam.LocalCoordinateSystem.theta);
end

% Convert cell array to table
DBtable = cell2table(dataCell, 'VariableNames', requiredFields);


%% Determine what the user wants as output

% Get default options
defaults = getDefaultOptions();

% Store logical differences in an array
diffFlags = [ ...
    options.CamSN ~= defaults.CamSN, ...
    options.CamNickname ~= defaults.CamNickname, ...
    options.DateofGCP ~= defaults.DateofGCP ...
];
isMultiCamModeDifferent = options.MultiCamMode ~= defaults.MultiCamMode;

% Determine which case applies
if ~any(diffFlags) && ~isMultiCamModeDifferent % Program Default
    returnData=DBtable;
elseif ~any(diffFlags) && isMultiCamModeDifferent % User really likes tables
    returnData=DBtable;    
else % User has tried to specify a Camera, Let's find it!
    % Extract field names where the user provided a value
    fieldNames = fieldnames(options);
    idx = find(strcmp(fieldNames, 'MultiCamMode'));
    fieldNames(idx)=[]; % Delete MultiCamMode for the database search
    selectedFields = fieldNames(diffFlags);

    % Construct filtering conditions dynamically
    filterMask = true(height(DBtable),1); % Start with all rows included
    for i = 1:numel(selectedFields)
        fieldName = selectedFields{i}; % Extract string from cell
        filterMask = filterMask & (DBtable.(fieldName) == options.(fieldName));
    end

    % Apply filter to the table
    Potentialvals = DBtable(filterMask, :);
    
    if(height(Potentialvals)>1) && options.MultiCamMode==true % if the user wants a table, give them a table of all searches
        returnData=Potentialvals;
    elseif (height(Potentialvals)>1) && options.MultiCamMode==false % if not in MultiCamMode, error out to 1 camera
        errormssg="";
        for i = 1:height(Potentialvals)
            % Display in a more readable format
            errormssg=errormssg+sprintf('\nCamSN: %d, CamNickname: %s, DateofGCP: %s', ...
                Potentialvals.CamSN(i), ...
                Potentialvals.CamNickname{i}, ...
                string(Potentialvals.DateofGCP(i)) ...
            );
        end

        errormssg=errormssg+sprintf(['\nListed multiple camera entries that wer found. ^^^\nSpecify more ' ...
            'arguments to pick 1 camera, or turn on "MultiCamMode=true" as an input argument to recieve a table']);
        error(errormssg);

    elseif (height(Potentialvals)==1) && options.MultiCamMode==false
        returnData=Potentialvals; %WIP: Struct is WIP
    end
    
    % If no matches were found, notify the user
    if isempty(Potentialvals)
        warning('No matching cameras found in the database.');
    end
end


end


%ᐠ⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝ᐟᐠ⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝ᐟᐠ⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝ᐟᐠ⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝^⸜ˎ_ˏ⸝ᐟᐠ⸜ˎ_ˏ⸝ᐟᐠ
% Internal Functions

function defaults = getDefaultOptions()
    defaults = struct( ...
        'CamSN', 0, ...
        'CamNickname', "", ...
        'DateofGCP', datetime(0,1,1), ... %datime for NaT (like NaN but Not a datetime)
        'MultiCamMode', false ...
    );
end

function mustBeValidFile(filePath)
    if ~isfile(filePath)
        error("The input must be a valid file.");
    end
end

% Custom validation function to check if input is a valid date.
function mustBeValidDate(dateInput) 
    if ischar(dateInput) || isstring (dateInput) %try to convert to double
        dateInput=str2double(dateInput);
    end

    if isa(dateInput, "datetime")
        % If it's a datetime, it's valid.
        return;
    elseif isnumeric(dateInput) && isscalar(dateInput)
        try datetime(dateInput,"ConvertFrom",'yyyymmdd');
            return
        catch
            error('Could not convert numeric input to datetime.  Please use YYYYMMDD format');
        end
    else % if nothing else
        error("mustBeValidDate:InvalidInput", "Input must be a datetime or a numeric date in YYYYMMDD format.");
    end
end
