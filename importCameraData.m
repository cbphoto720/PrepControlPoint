function camStruct = importCameraData(Path_to_SIO_CamDatabase, searchKey)
%{
Inputs:
    - Path_to_SIO_CamDatabase  =    [path] The fullfile location of:
                                    "SIO_CamDatabase.txt"
    - searchKey                =    ["string"] OR [#] "Camera_Nickname" or camera serial
                                    number you are interested in
 Outputs: 
    - camStruct                =    [struct] struct variable of camera
                                    information.  camStruct.Intrinsics follows the same 
                                    format at the CalTech camera intrinsics toolbox

%}
%% Input parsing for filename
    %WIP input parsing disabled
    % p = inputParser;
    % 
    % checkTableFields = @(tbl) istable(tbl) && all(ismember({'Cam_SN', 'Latitude', 'Elevation'}, tbl.Properties.VariableNames)); %WIP checl valid file path and that the table is valid (see GeneratreLeviLLZ)
    % 
    % addRequired(p, 'filename', checkTableFields && exist(x, 'file') == 2); % Check for valid file path
    % addRequired(p, 'searchKey', @(x) ischar(x) || isnumeric(x)); % Check for either string or numeric search key
    % parse(p, Path_to_SIO_CamDatabase, searchKey);
    
    % % Now, we can safely use p.Results.filename and p.Results.searchKey
    % Path_to_SIO_CamDatabase = p.Results.Path_to_SIO_CamDatabase;
    % searchKey = p.Results.searchKey;

%%

    % Read the tab-delimited file into a table, preserving original headers
    opts = detectImportOptions(Path_to_SIO_CamDatabase, 'Delimiter', '\t', 'VariableNamingRule', 'preserve');
    dataTable = readtable(Path_to_SIO_CamDatabase, opts);

    % Ensure required columns exist
    requiredCols = {'CamSN', 'CamNickname'};
    for col = requiredCols
        if ~ismember(col{1}, opts.VariableNames)
            error('The file must contain columns "CamSN" and "CamNickname".');
        end
    end

    % Find the row(s) matching the search key
    if isnumeric(searchKey) % Searching by Cam_SN
        matchIdx = dataTable.("CamSN") == searchKey;
    else % Searching by Cam Nickname
        matchIdx = strcmp(dataTable.("CamNickname"), searchKey);
    end

    % Error handling for multiple or missing entries
    if sum(matchIdx) == 0
        error('No match found for "%s". Ensure correct Camera Nickname or Serial Number.', string(searchKey));
    elseif sum(matchIdx) > 1
        error('Multiple entries found for "%s". Ensure unique entries.', string(searchKey));
    end

    % Extract the row corresponding to the search key
    rowIdx = find(matchIdx, 1);
    camData = dataTable(rowIdx, :);

    % Initialize struct
    camStruct = struct();

    % Assign main parameters (up to Elevation)
    camStruct.Cam_SN = camData.("CamSN");
    camStruct.Nickname = string(camData.("CamNickname"));
    camStruct.Date = datetime(string(camData.("Date")), 'InputFormat', 'yyyyMMdd');
    camStruct.Lat = camData.("Lat");
    camStruct.Lon = camData.("Lon");
    camStruct.Elevation = camData.("Elevation");

    %% Intrinsics
    % Create Intrinsics sub-structure
    camStruct.Intrinsics = struct();

    % Extract intrinsic fields (columns after Elevation)
    intrinsicFields = opts.VariableNames(7:end);
    tempIntrinsics = struct();
    
    % Handle numbered variables as arrays
    arrayVars = struct();

    for j = 1:numel(intrinsicFields)
        fieldName = intrinsicFields{j};
        fieldValue = camData.(fieldName);

        % Check if the field name ends with a number (e.g., cc1, cc2)
        match = regexp(fieldName, '^(.*?)(\d+)$', 'tokens');
        if ~isempty(match)
            baseName = match{1}{1}; % Extract base name
            index = str2double(match{1}{2}); % Extract index
            
            % Store in an array structure
            if ~isfield(arrayVars, baseName)
                arrayVars.(baseName) = [];
            end
            arrayVars.(baseName)(index) = fieldValue;
        else
            % Store non-array values directly
            tempIntrinsics.(fieldName) = fieldValue;
        end
    end

    % Merge arrays into the Intrinsics struct
    arrayNames = fieldnames(arrayVars);
    for k = 1:numel(arrayNames)
        tempIntrinsics.(arrayNames{k}) = arrayVars.(arrayNames{k});
    end

    % Assign Intrinsics to the main struct
    camStruct.Intrinsics = tempIntrinsics;

    disp(['Camera data for "' string(searchKey) '" successfully imported!']);
end
