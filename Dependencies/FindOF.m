function [OF_image,masked_OF_image, OF_avg,OF_list] = FindOF(images,bw)
    %% Normalize pixel-by-pixel
    norm = zeros(size(images));
    maximum = images(:,:,1);
    min = images(:,:,1);
    n_img = 4;
    for i = 2:n_img
        next = images(:,:,i);
        max_update = next > maximum;
        min_update = next < min;
        maximum(max_update) = next(max_update);
        min(min_update) = next(min_update);
    end
    
    % This should always true for all pixels
    r1 = images(:,:,1) > 0;
    
    for i=1:n_img
        current = images(:,:,i);
        normcurrent = zeros(size(norm(:,:,i)));
        normcurrent(r1) = current(r1)./maximum(r1);
        norm(:,:,i) = normcurrent;
    end
    
    
    %% Find order factor
    
    a = norm(:,:,1) - norm(:,:,3);
    b = norm(:,:,2) - norm(:,:,4);
   
    
    OF_image = zeros(size(norm(:,:,1)));
    OF_image(r1) = sqrt(a(r1).^2+b(r1).^2);
    
    %apply mask to order factor image
    temp = zeros(size(OF_image));  
    temp(bw) = OF_image(bw);
    masked_OF_image = temp;
    OF_avg = sum(sum(masked_OF_image))/nnz(masked_OF_image);
    OF_list = masked_OF_image(bw);
    
    
end
