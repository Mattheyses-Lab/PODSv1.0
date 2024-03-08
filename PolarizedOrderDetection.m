% Tara Urner
% data = PolarizedOrderDetection(varargin) was designed to calculate
% pixel-by-pixel "order factor" values within Desmosomes. The steps of the
% program are flat field correction and normalization, photobleaching
% correction, masking, and order detection

%Inputs (optional)
% 'timecourse' - if input data is a timecourse of polarization stacks.
% 'twocolor' - for nd2 files only, pulls out the second channel of first
%              image in polarzation stack based on channel name
% 'GFP' - masking parameters for cytosolic GFP
% 'nd2' - if input files are in nd2 format from Nikon Elments
% 'tifs' - if input files are in tif format
% 'unmasked' - if the user wishes to save unmasked OF images as well as
% masked
% 'pbcorrection' - if a photobleaching correction should be applied to the
% data
% 'pbconstant' - the photobleaching constant to use. Can be generated from
% FindPBConstant.m
% 'debug' - write function variables to workspace for debugging purposes



function data = PolarizedOrderDetection(varargin) 

    ip = inputParser;
    ip.CaseSensitive = false;
    ip.addParameter('timecourse', false, @islogical);
    ip.addParameter('twocolor',false, @islogical);
    ip.addParameter('GFP', false, @islogical);
    ip.addParameter('nd2', true, @islogical);
    ip.addParameter('tifs', false, @islogical);
    ip.addParameter('unmasked', false, @islogical);
    ip.addParameter('pbcorrection',false,@islogical);
    addParameter(ip,'pbconstant',0);
    ip.addParameter('debug',false,@islogical);
    ip.parse(varargin{:});
    params = ip.Results;
     
    %% Open files
    
    data = GetFiles('tifs',params.tifs,'nd2', params.nd2,'twocolor',params.twocolor,...
        'timecourse',params.timecourse,'debug',params.debug);

    %% Flat field correction
    
    data = FlatFieldCorrection(data);
    
    %% Optional photobleaching correction
    
    if params.pbcorrection
        data = PhotobleachingCorrection(data,'timecourse',params.timecourse,'pbconstant',params.pbconstant);
    end
    
    for i=1:length(data)
    %% Mask images
    
        [data(i).pol_ImAvg, data(i).bw,...
            data(i).Background,...
            data(i).level,...
            data(i).autothresh] = masking(data(i).pol_ffc,'timecourse',params.timecourse,...
                'GFP', params.GFP, 'debug', params.debug);
            
        if params.pbcorrection
            [data(i).pol_ImAvg_pbcorrected, data(i).bw_pbcorrected,...
                data(i).Background_pbcorrected,...
                data(i).level_pbcorrected,...
                data(i).autothresh_pbcorrected] = masking(data(i).pol_ffc_pbcorrected,'timecourse',params.timecourse,...
                    'GFP', params.GFP, 'debug', params.debug);            
        end
    %% Object creation
    
        imshow(data(i).bw)
        [data(i).cc,...
            data(i).des_data,...
            data(i).RGB_label] = ObjectCreation(data(i).bw);
        
        if params.pbcorrection
                [data(i).cc_pbcorrected,...
            data(i).des_data_pbcorrected,...
            data(i).RGB_label_pbcorrected] = ObjectCreation(data(i).bw_pbcorrected); 
        end

    %% Order factor

        [data(i).OF_image,...
            data(i).masked_OF_image,...
            data(i).OF_avg,...
            data(i).OF_list] = FindOF(data(i).pol_ffc,data(i).bw);
       
        
        % Order factor of photobleaching corrected data
        if params.pbcorrection
            [data(i).OF_image_pbcorrected,...
                data(i).masked_OF_image_pbcorrected,...
                data(i).OF_avg_pbcorrected,...
                data(i).OF_list_pbcorrected] = FindOF(data(i).pol_ffc_pbcorrected,data(i).bw_pbcorrected);
        end


    %% Signal to background information 

           [data(i).avg_signal,...
               data(i).signal_list,...
               data(i).avg_background,...
               data(i).background_list,...
               data(i).SB_list] = Intensity(data(i).pol_ImAvg,data(i).bw);
           
           % Signal to background information from photobleaching corrected
           % images
           if params.pbcorrection
               [data(i).avg_signal_pbcorrected,...
                   data(i).signal_list_pbcorrected,...
                   data(i).avg_background_pbcorrected,...
                   data(i).background_list_pbcorrected,...
                   data(i).SB_list_pbcorrected] = Intensity(data(i).pol_ImAvg_pbcorrected, data(i).bw_pbcorrected);               
           end          

       %% Show order factor image 
       
            Hfig = figure(1);
            imshow(data(i).masked_OF_image,[0,1]), colorbar;
            set(Hfig, 'Position', [0, 0, 1000, 1000])
            [mycolormap,mycolormap_noblack] = MakeRGB;
            colormap(gca,mycolormap);
            %title(data(i).pol_shortname);
       %% User decides if they want to save the dataset
            if i==1
                answer = questdlg('Would you like to save this dataset?');
                if strcmp(answer,'Yes')
                    folder_name = uigetdir(pwd);      
                    if ismac
                        loc = [folder_name '/' data(i).pol_shortname];
                    elseif ispc
                        loc = [folder_name '\' data(i).pol_shortname];
                    end
                end 
            end
      %% Save order factor images


            if strcmp(answer,'Yes')
                cd(folder_name)
                % SAVE ORDER FACTOR IMAGES
                name1 = [loc,'-OF_masked'];
                saveas(gcf,[name1 '.png']);
                imwrite(data(i).masked_OF_image, [name1 '.tif'], 'Compression','none')
                
                % unmasked OF image
                if params.unmasked
                    name2 = [loc, '-OF_unmasked'];
                    Hfig2 = figure('visible', 'off');
                    imshow(data(i).OF_image),colorbar
                    set(Hfig2, 'Position', [0, 0, 1000, 1000])
                    colormap(gca,mycolormap_noblack);
                    saveas(gcf,[name2 '.png']);
                    imwrite(data(i).OF_image, [name2 '.tif'], 'Compression', 'none');
                end
                
                % if a correction for photobleaching was applied
                if params.pbcorrection
                    name3 = [loc 'OF_masked_pbcorrected'];
                    Hfig3 = figure('visible','off');
                    imshow(data(i).masked_OF_image_pbcorrected), colorbar
                    set(Hfig3, 'Position', [0, 0, 1000, 1000])
                    colormap(gca,mycolormap)
                    saveas(gcf,[name3 '.png']);
                    imwrite(data(i).masked_OF_image_pbcorrected, [name3 '.tif'], 'Compression', 'none');
                    if params.unmasked
                        name4 = [loc, '-OF_unmasked_pbcorrected'];
                        Hfig4 = figure('visible', 'off');
                        imshow(data(i).OF_image_pbcorrected),colorbar
                        set(Hfig4, 'Position', [0, 0, 1000, 1000])
                        colormap(gca,mycolormap_noblack);
                        saveas(gcf,[name4 '.png']);
                        imwrite(data(i).OF_image_pbcorrected, [name4 '.tif'], 'Compression', 'none');    
                    end    
                end
                
                status = 'saving order factor image...'
                close all
            end 

      %% Save intensity images
            if strcmp(answer,'Yes')
                Hfig = figure('Visible','off'); %
                imshow(data(i).pol_ImAvg, [min(min(data(i).pol_ImAvg)),max(max(data(i).pol_ImAvg))]);
                set(Hfig, 'Position', [0, 0, 1000, 1000])
                name5 = strcat(loc,'-Iavg');
                saveas(gcf,[name5 '.png']);            
                imwrite(uint16(data(i).pol_ImAvg), [name5 '.tif'], 'Compression','none')
                
                % if a photobleaching correction was applied
                if params.pbcorrection
                    Hfig = figure('Visible','off'); %
                    imshow(data(i).pol_ImAvg_pbcorrected, [min(min(data(i).pol_ImAvg)),max(max(data(i).pol_ImAvg))]);
                    set(Hfig, 'Position', [0, 0, 1000, 1000])
                    name6 = strcat(loc,'-Iavg_pbcorrected');
                    saveas(gcf,[name6 '.png']);            
                    imwrite(uint16(data(i).pol_ImAvg), [name6 '.tif'], 'Compression','none')                    
                end
                status = 'saving average intensity image...'
            end 
    end
    
    %% Save data structure   
    if strcmp(answer,'Yes')
        numfiles = length(data);
        if numfiles > 1
            location = [loc '-and-' num2str(numfiles) '-other-files.mat'];
        else
            location = [loc '.mat'];
        end
        save(location, 'data');
        status = 'saving raw data structure...'
    end

    status = 'Done. Closing images and clearing workspace...'
    close all
end

