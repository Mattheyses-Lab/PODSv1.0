%Create Objects from black and white mask, return object structs
function [cc,object_data,RGB_label] = ObjectCreation(bw)
    cc = bwconncomp(bw, 4);
    cc.NumObjects
    labeled = labelmatrix(cc);
    RGB_label = label2rgb(labeled, @spring, 'c', 'shuffle');
    %FIGURE 3: Object recognition
    %figure
    %imshow(RGB_label)
    %title('Object recognition');
    object_data = regionprops(cc, 'basic');
    areas = [object_data.Area];
    nbins = 20;
    %FIGURE 4: Area Hist of objects
    %figure, hist(areas, nbins)
    %title('Histogram of Desmosome-Object Areas');
end