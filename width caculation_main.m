
clear;clc;
outDir = '';
inDir = 'F:\map';

includeSubdirectories = true;

% Fields to place in result
workSpaceFields = {
    'output'
    };

% Fields to write out to files. Each entry contains the field name and the
% corresponding file format.
fileFieldsAndFormat = {

};


% All extensions that can be read by IMREAD
imreadFormats       = imformats;
supportedExtensions = [imreadFormats.ext];
% Add dicom extensions
supportedExtensions{end+1} = 'dcm';
supportedExtensions{end+1} = 'ima';
supportedExtensions = strcat('.',supportedExtensions);
% Allow the 'no extension' specification of DICOM
supportedExtensions{end+1} = '';


% Create a image data store that can read all these files
imds = datastore(inDir,...
    'IncludeSubfolders', includeSubdirectories,...
    'Type','image',...
    'FileExtensions',supportedExtensions);
imds.ReadFcn = @readSupportedImage;


% Initialize output (as struct array)
result(numel(imds.Files)) = struct();
% Initialize fields with []
for ind =1:numel(workSpaceFields)
    [result.(workSpaceFields{ind})] = deal([]);
end


% Process each image using imfcn_width
error=[];
parfor imgInd = 1:numel(imds.Files)
    inImageFile  = imds.Files{imgInd};
    
    [~,R] = readgeoraster(inImageFile);
    % tif picture size
    if isempty(R)
        [~,R] = readgeoraster(imds.Files{imgInd-1});
        error=[error,imgInd];
    end
    pic_latlim = R.LatitudeLimits;
    pic_lonlim = R.LongitudeLimits;
    pic_size=R.RasterSize;
    pic_real_length=distance(pic_latlim(1),pic_lonlim(1),pic_latlim(1),pic_lonlim(2),almanac('earth','wgs84'));
    pic_real_width=distance(pic_latlim(1),pic_lonlim(1),pic_latlim(2),pic_lonlim(1),almanac('earth','wgs84'));
    pic_length_resolve=pic_real_length/pic_size(2);
    pic_width_resolve=pic_real_width/pic_size(1);
    pic_resolve=(pic_width_resolve+pic_length_resolve)/2;

%     % Output has the same sub-directory structure as input
    outImageFileWithExtension = strrep(inImageFile, inDir, outDir);
    % Remove the file extension to create the template output file name
    [path, filename,~] = fileparts(outImageFileWithExtension);
    outImageFile = fullfile(path,filename);

    try
        % Read
        im = imds.readimage(imgInd);

        % Process
        oneResult = struct();oneResult.output = imfcn_width(im);
        oneResult.output=oneResult.output*pic_resolve;
        % Accumulate
        for ind = 1:numel(workSpaceFields)
            % Only copy fields specified to be returned in the output
            fieldName = workSpaceFields{ind};
            result(imgInd).(fieldName) = oneResult.(fieldName);
        r_width{imgInd}=oneResult.(fieldName);
        end

        % Include the input image file name
        r_file{imgInd} = imds.Files{imgInd};

        % Write chosen fields to image files only if output directory is
        % specified
        if(~isempty(outDir))
            % Create (sub)directory if needed
            outSubDir = fileparts(outImageFile);
            createDirectory(outSubDir);

            for ind = 1:numel(fileFieldsAndFormat)
                fieldName  = fileFieldsAndFormat{ind}{1};
                fileFormat = fileFieldsAndFormat{ind}{2};
                imageData  = oneResult.(fieldName);
                % Add the field name and required file format for this
                % field to the template output file name
                outImageFileWithExtension = [outImageFile,'_',fieldName, '.', fileFormat];

                try
                    imwrite(imageData, outImageFileWithExtension);
                catch IMWRITEFAIL
                    disp(['WRITE FAILED:', inImageFile]);
                    warning(IMWRITEFAIL.identifier, '%s', IMWRITEFAIL.message);
                end
            end
        end

        disp(['PASSED:', inImageFile]);

    catch READANDPROCESSEXCEPTION
        disp(['FAILED:', inImageFile]);
        warning(READANDPROCESSEXCEPTION.identifier, '%s', READANDPROCESSEXCEPTION.message);
    end

end

result = struct2table(result,'AsArray',true);

width=cell2table(r_width','VariableNames',{'width'});
file=cell2table(r_file','VariableNames',{'file'});
width_data=[width,file];
width_data.('width')=width_data.('width')/10;
file_name=width_data.('file');
index=zeros(length(file_name),1);
Filename=cell(length(file_name),1);
for i=1:length(file_name)
    namesplit=strsplit(file_name{i},'\');
    namesplit_new=strsplit(namesplit{3},'_');
    index(i)=str2num(namesplit_new{1})+1;
    Filename{i}=namesplit{3};
end
width_data.('index')=index;
width_data.('file')=Filename;
new_width_data=sortrows(width_data,3);
delta_data=setdiff(1:885873,index)';
save('F:\delta_data.txt','delta_data','-ascii');
new_width_data.Properties.VariableNames={'Width/km','Filename','Index'};
writetable(new_width_data,'F:\width_data.xlsx','WriteVariableNames',true,'Sheet','Width caculation result1');
writetable(new_width_data,'F:\width_data.xlsx','WriteVariableNames',true,'Sheet','Width caculation result2');


function img = readSupportedImage(imgFile)
% Image read function with DICOM support
if(isdicom(imgFile))
    img = dicomread(imgFile);
else
    img = imread(imgFile);
end
end

function createDirectory(dirname)
% Make output (sub) directory if needed
if exist(dirname, 'dir')
    return;
end
[success, message] = mkdir(dirname);
if ~success
    disp(['FAILED TO CREATE:', dirname]);
    disp(message);
end
end



