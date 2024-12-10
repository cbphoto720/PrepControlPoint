function local = generateLeviLLZ(GPSpoints, LeviUTCfile)
%generateLeviLLZ: Create survey data for the GPS points.  Generate a local
%reference coordinate system & arrange Lon/Lat and time in the required
%format for PickControlPointV5 software.
%   NUM_IMGsets =   [#] How many different images are you using
%   MaxNUMPointsinSet = [#] What is the maximum # of points per img  
%   date    =   [yyyyMMdd](string) date of img capture

%% Input Parsing
try
    capturedate=datetime(date,'InputFormat','yyyyMMdd');
catch
    error('Problem reading date.  Please use a char array or string [yyyymmdd]');
    capturedate =datetime('20240101','InputFormat','yyyyMMdd');
end

p= inputParser;
checkTableFields = @(tbl) istable(tbl) && all(ismember({'Longitude', 'Latitude', 'Elevation'}, tbl.Properties.VariableNames));

addRequired(p, 'GPSpoints',checkTableFields);

parse(p,NUM_IMGsets,PointsInSet, date, path);
%% Generate Data
wgs84 = wgs84Ellipsoid; % Define ellipsoid
origin = [GPSpoints.Latitude(1),GPSpoints.Longitude(1),GPSpoints.Elevation(1)]; % Set first point as origin
% Convert lat, lon to local coordinate system
[local.xEast,local.yNorth,local.zUp] = geodetic2enu(GPSpoints.Latitude,GPSpoints.Longitude,GPSpoints.Elevation,origin(1),origin(2),origin(3),wgs84);

end