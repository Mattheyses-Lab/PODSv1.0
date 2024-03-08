function pb = FindPBConstant(varargin)
% Tara Urner 11/22/17
% FindPBConstant.m can be used to find a photobleaching constant for the particular 
% experimental setup and fluorescent protein of interest. The program can take single 
% or multiple image stacks in either .tif or .nd2 format. To ensure that the constant 
% represents the photodynamics of the fluorophore of interest, a masking routine is 
% performed on the first image of the sequence. Please see README for
% details.

    ip = inputParser;
    ip.CaseSensitive = false;
    ip.addParameter('tifs', false);
    ip.addParameter('nd2', false);
    ip.parse(varargin{:})
    params = ip.Results;

%% File handling

    % We will store all of the photocorrection data in 'pb'
    pb = struct();
    
    % Processing for .tif files
    if params.tifs
        uiwait(msgbox('Please select tif image sequences'))
        [tif_files, tif_path] = uigetfile('*.tif', 'multiselect','on');
        if ischar(tif_files)
            num_files = 1;
        else
            num_files = length(tif_files);
        end
        
        %Calculate constants for each stack
        for i=1:num_files
            % put filenames together
            if ismac
                if num_files > 1
                    pb(i).fullname = [tif_path '/' tif_files{i}];
                else
                    pb(i).fullname = [tif_path '/' tif_files];
                end
            elseif ispc
                if num_files > 1
                    pb(i).fullname = [tif_path '\' tif_files{i}];
                else
                    pb(i).fullname = [tif_path '\' tif_files];
                end
            end
            file_info = imfinfo(pb(i).fullname);
            stack_size = length(file_info);
            pb(i).stack_size = stack_size;
            for j=1:stack_size
                % Read in images and convert to floating point
                image(:,:,j) = im2double(imread(pb(i).fullname,j))*65535;
            end
            pb(i).image = image;
            clear image
        end
        
    % Processing for .nd2 files
    elseif params.nd2
      uiwait(msgbox('Please select nd2 image sequences'))
        [nd2_files, nd2_path] = uigetfile('*.nd2', 'multiselect','on');
        if ischar(nd2_files)
            num_files = 1;
        else
            num_files = length(nd2_files);
        end
        
        %Calculate constants for each stack
        for i=1:num_files
            % put filenames together
            if ismac
                if num_files > 1
                    pb(i).fullname = [nd2_path '/' nd2_files{i}];
                else
                    pb(i).fullname = [nd2_path '/' nd2_files];
                end
            elseif ispc
                if num_files > 1
                    pb(i).fullname = [nd2_path '\' nd2_files{i}];
                else
                    pb(i).fullname = [nd2_path '\' nd2_files];
                end
            end      
               temp = bfopen(pb(i).fullname);
               images = temp{1,1};
               stack_size = length(images);
               pb(i).stack_size = stack_size;
               for j=1:stack_size
                   all_images(:,:,j) = double(images{j,1})*65535;
               end
               pb(i).images = all_images;
               clear all_images
        end
    % One or the other (.tif or .nd2) must be selected    
    else
        error('Please select either tifs or nd2 files as the filetype')    
    end

 %% Calculate Constants
 % Generate mask from average of all images in the stack

    for i=1:length(pb)
        pb(i).mean = mean(pb(i).images(:,:,:),3);
        pb(i).norm = pb(i).mean./max(max(pb(i).mean));
        [~,~,pb(i).bw,pb(i).background,pb(i).level,pb(i).autothresh] = masking(pb(i));
        I_first = pb(i).images(:,:,1);
        I_last = pb(i).images(:,:,stack_size);
        I_first(~pb(i).bw) = 0;
        I_last(~pb(i).bw) = 0;
        pb(i).pbconstant = log((mean(mean(I_first)))/(mean(mean(I_last))))/stack_size;
        
    end

    
 %% Writing out the data
 

end