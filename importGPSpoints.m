function GPSpoints = importGPSpoints(filename)
%importGPSpoints Import data from the iG8 text file as a matlab table
%{   
Currently, this code will break if you have a description for some
points but not others.  You can edit the text file to either delete all
descriptions or make up placeholder descriptions for those missing.

  Example:
  GPSpoints = importfile("\\reefbreak.ucsd.edu\group\SD24\GCP_20240819\20240819_FletcherCamGCPs.txt");

  - [GPSpoints.Latitude, GPSpoints.Longitude] %full [Lat, Lon] list
  - GPSpoints(1,:) % one row entry (all information about 1st GPS point)
    

Created by Carson Black on 20240821.
ccblack@ucsd.edu

%}
%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 17); % We are only interested in the first 17 variables because the rest are repeats.

% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = " ";

% Specify column names and types
opts.VariableNames = ["Name", "Code", "Northings", "Eastings", "Elevation", "Longitude", "Latitude", "H", "Antenna_offset", "Solution", "Satellites", "PDOP", "Horizontal_error", "Vertical_error", "Time", "HRMS", "VRMS", "Var18", "Var19", "Var20", "Var21", "Var22", "Var23", "Var24", "Var25", "Var26", "Var27", "Var28", "Var29"];
opts.SelectedVariableNames = ["Name", "Code", "Northings", "Eastings", "Elevation", "Longitude", "Latitude", "H", "Antenna_offset", "Solution", "Satellites", "PDOP", "Horizontal_error", "Vertical_error", "Time", "HRMS", "VRMS"];
opts.VariableTypes = ["double", "string", "string", "string", "double", "string", "string", "double", "double", "categorical", "double", "double", "double", "double", "datetime", "double", "double", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
opts.ConsecutiveDelimitersRule = "join";
opts.LeadingDelimitersRule = "ignore";

% Specify variable properties
opts = setvaropts(opts, ["Var18", "Var19", "Var20", "Var21", "Var22", "Var23", "Var24", "Var25", "Var26", "Var27", "Var28", "Var29"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Code", "Solution", "Var18", "Var19", "Var20", "Var21", "Var22", "Var23", "Var24", "Var25", "Var26", "Var27", "Var28", "Var29"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "Time", "InputFormat", "yyyy-MM-dd HH:mm:ss", "DatetimeFormat", "preserveinput");
% opts = setvaropts(opts, ["Northings", "Eastings", "Longitude", "Latitude", "HRMS", "VRMS"], "TrimNonNumeric", false);
% opts = setvaropts(opts, ["Northings", "Eastings", "Longitude", "Latitude", "HRMS", "VRMS"], "ThousandsSeparator", ",");

% Import the data
GPSpoints = readtable(filename, opts);

tableshape=size(GPSpoints);

% Assign + or - Longitude
for i=1:tableshape(1)
    if(GPSpoints.Longitude{i}(end)=='W')
        GPSpoints.Longitude{i}=append('-',GPSpoints.Longitude{i});
        GPSpoints.Longitude{i}(end)=[];
    elseif(GPSpoints.Longitude{i}(end)=='E')
        GPSpoints.Longitude{i}(end)=[];
    else
        disp('Longitude import error.  Unknown coordinate reference (define W or E by appending)')
    end
end

% Assign + or - Latitude
for i=1:tableshape(1)
    if(GPSpoints.Latitude{i}(end)=='S')
        GPSpoints.Latitude{i}=append('-',GPSpoints.Latitude{i});
        GPSpoints.Latitude{i}(end)=[];
    elseif(GPSpoints.Latitude{i}(end)=='N')
        GPSpoints.Latitude{i}(end)=[];
    else
        disp('Latitude import error.  Unknown coordinate reference (define N or S by appending)')
    end
end

% Assign + or - Northings
for i=1:tableshape(1)
    if(GPSpoints.Northings{i}(end)=='S')
        GPSpoints.Northings{i}=append('-',GPSpoints.Northings{i});
        GPSpoints.Northings{i}(end)=[];
    elseif(GPSpoints.Northings{i}(end)=='N')
        GPSpoints.Northings{i}(end)=[];
    else
        disp('Northings import error.  Unknown coordinate reference (define N or S by appending)')
    end
end

% Assign + or - Eastings
for i=1:tableshape(1)
    if(GPSpoints.Eastings{i}(end)=='W')
        GPSpoints.Eastings{i}=append('-',GPSpoints.Eastings{i});
        GPSpoints.Eastings{i}(end)=[];
    elseif(GPSpoints.Eastings{i}(end)=='E')
        GPSpoints.Eastings{i}(end)=[];
    else
        disp('Eastings import error.  Unknown coordinate reference (define E or W by appending)')
    end
end


GPSpoints=convertvars(GPSpoints,{'Longitude','Latitude','Northings','Eastings'},'double');