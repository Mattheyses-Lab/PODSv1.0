function [ImAvg, bw,background,level,autothresh] = masking(images,varargin)
    ip = inputParser;
    ip.addParameter('timecourse',false)
    ip.addParameter('GFP',false)
    ip.addParameter('debug',false)
    ip.parse(varargin{:});
    params = ip.Results; 
    
    ImAvg = mean(images,3);
    I = ImAvg./max(max(ImAvg));
    
    % for a cytosolic fluorophore control we can just binarize directly 
    if params.GFP 
        [level,~] = graythresh(I);
        bw = imbinarize(I,level);
        background = 0;
    else
    % For desmosomes or other small punctate structures, we can use a
    % Morphological masking approach
        figure
        imshow(I);
        title('Average Intensity')
        background = imopen(I,strel('disk',3));
        I2 = I - background;
        I3 = medfilt2(I2);
        [level,~] = graythresh(I3); 
        bw = imbinarize(I3,level);
        bw = bwareaopen(bw, 2);
    end
    figure
    imshow(bw)
    autothresh = 0;
    answer = questdlg('Accept this mask?');
    % Optional thresholding tool to correct an improperly masked image
    if strcmp(answer,'No')
        autothresh = 1;
        [level, bw] = thresh_tool(I3,gray);
        close all
        figure,imshow(bw);
    end
    title('Black and white binary');
        if params.debug
            B = who;
            for i = 1:length(B)
                assignin('base', B{i}, eval(B{i}));
            end
        end
end