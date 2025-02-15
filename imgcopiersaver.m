function imgcopiersaver(inputFolder, outputFolder, numCopies, camSN)
    % **DISCONTINUED** PROCESS_TIF_IMAGES Processes TIFF images by copying and renaming them.
    %
    % Args:
    %   inputFolder (string): Path to the folder containing subfolders with .tif images.
    %   outputFolder (string): Path to the folder where processed images will be saved.
    %   numCopies (double): Number of copies to create for each image.
    %   camSN: The camera "Serial Number" is the 8 digit code included in the filename of the image e.g. _21217396_
    %% Input Parsing
    camSNdatabase=[21217396,22296748,22296760];

    p= inputParser;
    validScalarPosNum = @(x) isnumeric(x) && isscalar(x) && (x > 0);
    validPosNx1Matrix = @(x) isnumeric(x) && ismatrix(x) && size(x, 2) == 1 && size(x,1) > 1 && all(x > 0);
    validCamSN = @(x) any(x==camSNdatabase);
   
    addRequired(p, 'inputFolder',@(x) isfolder(x));
    addRequired(p, 'outputFolder',@(x) isfolder(x));
    addRequired(p, 'numCopies',@(x) validScalarPosNum(x) || validPosNx1Matrix(x));
    addRequired(p, 'camSN', validCamSN);
    
    parse(p,inputFolder,outputFolder,numCopies,camSN);


    %%
    % Ensure output folder exists
    if ~isfolder(outputFolder)
        error('Could not find file output folder, check file path and make sure that a .utc file exists there')
    end

    % Get list required files
    tifFiles = dir(fullfile(inputFolder, '**', '*.tif'));
    utcFiles = dir(fullfile(outputFolder, '*.utc'));

    if isempty(tifFiles)
        error('No TIFF files found in the input folder or its subfolders.');
    end

    if isempty(utcFiles)
        error('No .utc files found in the folder: %s', outputFolder);
    elseif numel(utcFiles) > 1
        error('Multiple .utc files found in the folder: %s. There should be exactly one.', outputFolder);
    else
        baseFilename = utcFiles.name(1:end-4);  % Copy the name of the single .utc file found
    end

    % Generate a matrix that defines the number of copies we need for each
    % image.  We only want 1 frame per GPS point visible in the picture, no extras
    if validPosNx1Matrix(numCopies)
        numberofcopiesperimg=numCopies;
    elseif validScalarPosNum(numCopies)
        numberofcopiesperimg=repmat(numCopies,1,length(tifFiles));
    end
    maxframenumber=sum(numberofcopiesperimg)-1;
    % Determine the required number of digits for leading zero padding
    numDigits = max(1, ceil(log10(maxframenumber + 1))); % +1 to handle exact powers of 10

    setnumber=0; % allocate for file naming
    filescreated=0;
    numCopiesIND=1;
    % Process each .tif file
    for fileIdx = 1:length(tifFiles)
        % Read the full path of the current .tif file
        inputFile = fullfile(tifFiles(fileIdx).folder, tifFiles(fileIdx).name);

        if contains(tifFiles(fileIdx).name,"_" + camSN + "_")
            % Create copies with sequential numbering
            for copyIdx = 0:(numberofcopiesperimg(numCopiesIND) - 1)
                % Generate the new filename
                formatString = sprintf('%%s_%%0%dd.tif', numDigits);
                newFilename = sprintf(formatString, baseFilename, setnumber); %numDigits dynamically adjusts the zero padding based on max frames
                setnumber = setnumber + 1;
                outputFile = fullfile(outputFolder, newFilename);
    
                % Only create images with the 3 RGB channels
                if copyIdx==0
                    importimg=imread(inputFile);
                    newimg=importimg(:,:,1:3); % Only take the first 3 channels for RGB
                    imwrite(im2uint16(newimg), outputFile);
    
                    extracopies=outputFile; % New target for imgs to be copied from
                    % clear importimg, newimg
                else
                    % Copy the file more efficiently than opening it every time
                    copyfile(extracopies, outputFile);
                end
                filescreated=filescreated+1;
            end
            numCopiesIND=numCopiesIND+1;
        end
    end

    fprintf('Looked at %d TIFF files and found the relevant CamSN. (%d files created) \n', length(tifFiles), filescreated);
end
