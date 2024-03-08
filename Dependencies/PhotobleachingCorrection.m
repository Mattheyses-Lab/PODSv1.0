function data = PhotobleachingCorrection(data, varargin)
    ip = inputParser;
    ip.CaseSensitive = false;
    
    ip.addParameter('timecourse', false)
    addParameter(ip,'pbconstant', 0);
    ip.parse(varargin{:});
    params = ip.Results;
    
    num_timepoints = length(data);
    if params.timecourse      
        total_images = num_timepoints * 4;
        coeffs = 1:total_images;
        coeffs = coeffs * params.pbconstant;
        count = 0;
        for i=1:num_timepoints
            for j=1:4
                if i==1 && j==1
                    data(i).pol_ffc_pbcorrected(:,:,1) = data(i).pol_ffc(:,:,1);
                    j = j + 1; 
                end    
                idx = 4*count+j;
                data(i).pol_ffc_pbcorrected(:,:,j) = data(i).pol_ffc(:,:,j)*exp(coeffs(idx));           
            end
            count = count + 1;
        end
    else
        num_images = length(data);
        coeffs = 1:4;
        coeffs = coeffs * params.pbconstant;
        for i=1:num_images
            data(i).pol_ffc_pbcorrected(:,:,1) = data(i).pol_ffc(:,:,1);
            for j=2:4
                data(i).pol_ffc_pbcorrected(:,:,j) = data(i).pol_ffc(:,:,j)*exp(coeffs(j));
            end    
        end           
    end    
end