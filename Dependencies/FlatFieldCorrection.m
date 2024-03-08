function data = FlatFieldCorrection(data)
    n_cal = size(data(1).all_cal,3);
    cal_average = sum(data(1).all_cal,4)./n_cal;
    data(1).cal_norm = cal_average/max(max(max(cal_average)));
    for i=1:length(data)
        for j=1:4
            data(i).pol_ffc(:,:,j) = data(i).pol_rawdata(:,:,j)./data(1).cal_norm(:,:,j);
        end
    end
    
end