% Tara Urner 12-8-2017
% data = get_files(varargin) does all of the initial file handling for the
% master PODS program.
% Nd2 files: The program can process single-channel polarization .nd2
%  image stacks of four images ( taken at 0°, 45°, 90°, 135° rotation angle
%  of the polarizer).
%   Larger image stacks are accepted, but only the first four images will be
%   processed, and it is assumed that these images were taken at 45° intervals
%   of rotation of a polarizer. The program can also accept two channel .nd2
%   images, currently only the first image in the sequence of the second
%   channel is processed - it is saved as a .mat for later processing.
% Tiff files: Tif files in the same arrangement as described above,
%   excluding two color tifs, which cannot be processed at this time. 
% Tiff and nd2 multiple files or timecourses: Timecourses are placed in the
%   corrected order based on string parsing of the identifiers ?t0, t1, t2..?
%   etc. Images without these identifiers or with non-sequential identifiers
%   will not be processed correctly as timecourses. Multiple files that
%   require the same flat field correction calibration can be processed at
%   one time.
%  

function data = GetFiles(varargin)

    ip = inputParser;
    ip.CaseSensitive = false;
    ip.addParameter('tifs', false, @islogical);
    ip.addParameter('nd2', true, @islogical);
    ip.addParameter('debug', false, @islogical);
    ip.addParameter('timecourse',false,@islogical);
    ip.addParameter('twocolor',false,@islogical);
    ip.parse(varargin{:});
    params = ip.Results;
    
    data = struct()
    
    %% User selects cal background files and polarization sequences
    if params.tifs
        uiwait(msgbox('Please select flat field correction .tif files'));
        [cal_files, calPath, ~] = uigetfile('*.tif','Select cal files','MultiSelect','on');
        if(iscell(cal_files)==0)
           if(cal_files==0)
            warning('No background normalization files selected. Proceeding anyway');
           end    
        end
        uiwait(msgbox('Please select polarization stack .tif files'));
        [Pol_files, PolPath, ~] = uigetfile('*.tif','Select Polarization sequences','MultiSelect','on');
        if(iscell(Pol_files) == 0)
            if(Pol_files==0)
                msg = 'No files selected. Exiting...';
                error(msg);
            end
        end 
    else
        uiwait(msgbox('Please select flat field correction .nd2 files'));
        [cal_files, calPath, ~] = uigetfile('*.nd2','Select cal files','MultiSelect','on');
        if(iscell(cal_files)==0)
           if(cal_files==0)
            warning('No background normalization files selected. Proceeding anyway');
           end    
        end
        uiwait(msgbox('Please select polarization stack .nd2 files'));
        [Pol_files, PolPath, ~] = uigetfile('*.nd2','Select Polarization sequences','MultiSelect','on');
        if(iscell(Pol_files) == 0)
            if(Pol_files==0)
                msg = 'No files selected. Exiting...';
                error(msg);
            end
        end 
    end
    
    if iscell(cal_files)
        [~,n_cal] = size(cal_files);
    elseif ischar(cal_files)
        n_cal = 1;
    end
    
    if iscell(Pol_files)
        [~,n_Pol] = size(Pol_files);
    elseif ischar(Pol_files)
        n_Pol = 1;
    end

%% Parse filenames for timecourses
if params.timecourse
        a = "t";
        b = string(0:n_Pol-1);
        times = strcat(a,b);
        n_timepoints = n_Pol;
         
        % First, put the filenames in order by time
        
        for i=1:n_timepoints
            a = [];
            time = 1;
            while isempty(a)        
                try
                    a = strfind(Pol_files{1,i},char(times(time)));
                catch
                    error('Selected timepoints may not be sequential');
                end
                time = time + 1;
            end
            filename = Pol_files{1,i};
            temp = strsplit(filename, '.');
            data(time-1).pol_shortname = temp{1};
            data(time-1).pol_fullname = [PolPath filename];
            data(time-1).time = times(time-1);    
            
        end  
end
%% %%%%%%%%%%% OPEN .TIF FILES %%%%%%%%%%%
    if params.tifs

    % Calibration tifs

            for i=1:n_cal
                if iscell(cal_files)
                    filename = cal_files{1,i};
                else
                    filename = cal_files;
                end
                temp = strsplit(filename,'.');
                data(1).cal_shortname{i,1} = temp{1};
                data(1).cal_fullname{i,1} = [calPath filename];
                if i == 1
                    if iscell(cal_files)
                        info = imfinfo(char(data(i).cal_fullname{i,1}));
                    else
                        info = imfinfo(char(data(i).cal_fullname));
                    end
                    h = info.Height;
                    w = info.Width;
                    fprintf(['Calibration file dimensions are ' num2str(w) ' by ' num2str(h) '\n'])
                end    
                for j=1:4
                    try
                        data(1).all_cal(:,:,j,i) = im2double(imread(char(data(1).cal_fullname{i,1}),j))*65535; %convert to 32 bit
                    catch
                        error('Correction files may not all be the same size')
                    end             
                end
            end

    %%%%%%%%% Not a timecourse %%%%%%%%%        
        if ~params.timecourse
        % Single color tifs
            for i=1:n_Pol
                if iscell(Pol_files)
                    filename = Pol_files{1,i};
                else
                    filename = Pol_files;
                end
                temp = strsplit(filename, '.');
                data(i).pol_shortname = temp{1};
                data(i).pol_fullname = [PolPath filename];         
                if params.twocolor
                    error('Two color tifs cannot be processed at this time.');
                end
                if i == 1
                    info = imfinfo(char(data(i).pol_fullname));
                    h = info.Height;
                    w = info.Width;
                    fprintf(['dimensions of ' char(data(i).pol_shortname) ' are ' num2str(w) ' by ' num2str(h) '\n'])
                end    
                for j=1:4
                    data(i).pol_rawdata(:,:,j) = im2double(imread(char(data(i).pol_fullname),j))*65535; %convert to 32 bit          
                end                
            end
        
    %%%%%%%%% Timecourse %%%%%%%%%
        % Single color tifs
        elseif params.timecourse
                for i=1:n_Pol
                    if i == 1
                        info = imfinfo(char(data(i).pol_fullname));
                        h = info.Height;
                        w = info.Width;
                        fprintf(['Dimensions of ' char(data(i).pol_shortname) ' are ' num2str(w) ' by ' num2str(h) '\n'])
                    end    
                    for j=1:4
                        data(i).pol_rawdata(:,:,j) = im2double(imread(char(data(1).pol_fullname),j))*65535; %convert to 32 bit          
                    end               
                end
        end

 
    %% %%%%%%%%%%% OPEN .ND2 FILES %%%%%%%%%%%

    elseif params.nd2

        % Calibration nd2s
        for i=1:n_cal
            if iscell(cal_files)
                filename = cal_files{1,i};
            else
                filename = cal_files;
            end
                temp = strsplit(filename,'.');
                data(1).cal_shortname{i,1} = temp{1};
                data(1).cal_fullname{i,1} = [calPath filename];
            if iscell(cal_files)
                temp = bfopen(char(data(1).cal_fullname{i,1}));
            else
                temp = bfopen(char(data(1).cal_fullname));
            end
            temp2 = temp{1,1};
            if i==1
                h = size(temp2{1,1},1);
                w = size(temp2{1,1},2);
                fprintf(['Calibration file dimensions are ' num2str(w) ' by ' num2str(h) '\n'])
            end    
            for j=1:4
                data(1).all_cal(:,:,j,i) = im2double(temp2{j,1})*65535;
            end
        end

        %%%%%%%%% Not a timecourse %%%%%%%%% 

        % Single channel nd2s + timecourses
        if ~params.twocolor
            for i=1:n_Pol
                if params.timecourse
                    temp = bfopen(char(data(i).pol_fullname));
                else 
                    if iscell(Pol_files)
                        filename = Pol_files{1,i};
                    else
                        filename = Pol_files;
                    end
                        temp = strsplit(filename,'.');
                        data(i).pol_shortname = temp{1};
                        data(i).pol_fullname = [PolPath filename];
                        temp = bfopen(char(data(1).pol_fullname));
                end 
                temp2 = temp{1,1};
                if i==1
                    h = size(temp2{1,1},1);
                    w = size(temp2{1,1},2);
                    fprintf(['Dimensions of ' char(data(i).pol_shortname) ' are ' num2str(w) ' by ' num2str(h) '\n'])
                end    
                for j=1:4
                    data(i).pol_rawdata(:,:,j) = im2double(temp2{j,1})*65535;
                end
                 
            end
        end

        % Two channel nd2s + timecourses
        if params.twocolor
                for i=1:n_Pol
                    % two channel timecourses
                    if params.timecourse
                        temp = bfopen(char(data(i).pol_fullname));
                    else    
                        if iscell(Pol_files)
                            filename = Pol_files{1,i};
                        else
                            filename = Pol_files;
                        end
                        temp = strsplit(filename,'.');
                        data(i).pol_shortname = temp{1};
                        data(i).pol_fullname = [PolPath filename];
                        temp = bfopen(char(data(i).pol_fullname));
                    end

                    omeMeta = temp{1,4};
                    n_img = size(temp{1,1},1);
                    omeXML = char(omeMeta.dumpXML());
                    datastruct = xml2struct(omeXML);

                    try
                        numchannels = size(datastruct.OME.Image.Pixels.Channel,2);
                        alternate_format = 0;
                    catch
                        numchannels = size(datastruct.OME.Image{1,1}.Pixels.Channel,2);
                        alternate_format = 1;
                    end

                    if alternate_format
                        num_series = size(datastruct.OME.Image,2);
                    end

                    if numchannels==1
                        if alternate_format
                            channels(1).name = datastruct.OME.Image{1,1}.Channel.Attributes.Name;
                            thing = strsplit(datastruct.OME.Image.Pixels.Channel.Attributes.ID,':');
                            channels(1).ID = thing(3);
                            channels(1).imcount = 1;
                        else  
                           channels(1).name = datastruct.OME.Image.Pixels.Channel.Attributes.Name;
                           thing = strsplit(datastruct.OME.Image.Pixels.Channel.Attributes.ID,':');
                           channels(1).ID = thing(3);
                           channels(1).imcount = 1;
                        end

                    else
                        for a=1:numchannels
                            if alternate_format
                                channels(a).name = datastruct.OME.Image{1,1}.Pixels.Channel{1,a}.Attributes.Name;
                                thing = strsplit(datastruct.OME.Image{1,1}.Pixels.Channel{1,a}.Attributes.ID,':');
                                channels(a).ID = thing(3);
                                channels(a).imcount = 1;  
                            else 
                               channels(a).name = datastruct.OME.Image.Pixels.Channel{1,a}.Attributes.Name;
                               thing = strsplit(datastruct.OME.Image.Pixels.Channel{1,a}.Attributes.ID,':');
                               channels(a).ID = thing(3);
                               channels(a).imcount = 1;
                            end
                        end   
                    end
                    if alternate_format
                        n_img = size(temp,1);
                        n_planes = size(datastruct.OME.Image{1,1}.Pixels.Plane,2);
                        for b=1:n_img
                            for f=1:n_planes
                                for d=1:numchannels
                                    if datastruct.OME.Image{1,b}.Pixels.Plane{1,f}.Attributes.TheC==channels(d).ID{1,1}
                                        temp2 = temp{b,1};
                                        channels(d).images(:,:,channels(d).imcount) = temp2{f,1};
                                        channels(d).imcount = channels(d).imcount+1;
                                    end
                                end
                            end
                        end                
                        data(i).pixel_size = datastruct.OME.Image{1,1}.Pixels.Attributes.PhysicalSizeX;


                    else
                        temp2 = temp{1,1};
                        for j=1:n_img
                           for d=1:numchannels
                               if datastruct.OME.Image.Pixels.Plane{1,j}.Attributes.TheC==channels(d).ID{1,1}
                                   channels(d).images(:,:,channels(d).imcount) = temp2{j,1};
                                   channels(d).imcount = channels(d).imcount+1;
                               end
                           end       
                        end
                        data(i).pixel_size = datastruct.OME.Image.Pixels.Attributes.PhysicalSizeX;
                    end



                    for b=1:numchannels
                        if strcmp(channels(b).name,'Mono') || strcmp(channels(b).name,'488-las') || strcmp(channels(b).name,'488las') || strcmp(channels(b).name,'488 las') 
                            data(i).pol_rawdata(:,:,:) = im2double(channels(b).images(:,:,2:end))*65535;
                        else
                            loc = strcat(data(i).pol_shortname,'_',channels(b).name);
                            if ischar(loc)
                                location = strcat(loc, '.mat');
                            else
                                location = strcat(loc{1,1}, '.mat');
                            end
                            rawimage = channels(b).images(:,:,1);
                            save(location, 'rawimage');
                        end
                    end
                end
        end



    else
        error('Please choose either .tif or .nd2 as the filetype') 
    end
    
   
    if params.debug
        A = who;
        for i = 1:length(A)
            assignin('base', A{i}, eval(A{i}));
        end
    end
end
