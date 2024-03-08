function [avg_signal, signal_list, avg_background, background_list, SB_list] = Intensity(ImAvg,bw)
    % Signal values are inside the mask
    signal = zeros(size(ImAvg));
    signal(bw) = ImAvg(bw);
    signal_list = signal(bw);
    avg_signal = sum(sum(signal))/nnz(signal);
    
    % Background values are outside the mask
    background = zeros(size(ImAvg));
    background(~bw) = ImAvg(~bw);
    background_list = background(~bw);
    avg_background = sum(sum(background))/nnz(background);
    
    % S/B list
    SB_list = signal_list./avg_background;
    
end