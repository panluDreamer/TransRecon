function alphamatte = EMXCompAlphaMatte(ref_folder, obj_folder)
%% compAlphaMatte compute alpha matte
if isempty(ref_folder) || isempty(obj_folder)
    return;
end

% difference threshold
epsilon = 0.35 * sqrt(3) * 255;

refImgs = dir([ref_folder, '/*.png']);
objImgs = dir([obj_folder, '/*.png']);
if length(refImgs) ~= length(objImgs)
    return;
end

imgCnt = length(refImgs);

initialized = false;
for i = 1 : imgCnt
    if i <= imgCnt/2
        fgFilename = sprintf('%s/col_gray_%02d.png', obj_folder, i);
    else
        fgFilename = sprintf('%s/row_gray_%02d.png', obj_folder, i - imgCnt/2);
    end
    bgFilename = sprintf('%s/alpha_%02d.png', ref_folder, i);
    
    fgImg = imread(fgFilename);
    bgImg = imread(bgFilename);
    if size(fgImg, 3) == 3
        fgImg = img2gray(fgImg);
    end
    if size(bgImg, 3) == 3
        bgImg = rgb2gray(bgImg);
    end
    
    if(~initialized)
        [m,n,k] = size(fgImg);
        C = zeros(imgCnt, m,n,k);
        B = zeros(imgCnt, m,n,k);
        initialized = true;
    end
    C(i,:,:,:) = fgImg;
    B(i,:,:,:) = bgImg;
    if(i==1)
        A = alpha_matte( squeeze(C(i,:,:,:)), squeeze(B(i,:,:,:)), epsilon);
    else
        A = A + alpha_matte(squeeze(C(i,:,:,:)), squeeze(B(i,:,:,:)), epsilon);
    end
end

A = sign(A);
disp('alpha matte computed');

S1 = strel(ones(5,5));
A = imopen(A, S1);

S2 = strel(ones(5,5));
A = imclose(A, S2);
A = imerode(A, S2);
alphamatte = A;
% figure(1);
% imshow(A);
% imwrite(A,'alphamatte.png');
%% background matte
% bgmatte = zeros(size(A, 1), size(A, 2));
% for i = 1 : imgCnt
%     bgImg = rgb2gray(squeeze(B(i, :, :, :)));
%     bgmatte = bgmatte + (bgImg == 0);
% end
% bgmatte = repmat(bgmatte, 1, 1, 3);
% figure(2);
% imshow(bgmatte);
% imwrite(bgmatte, 'bgmatte.png');
end
%% compute alpha matte
function  alpha = alpha_matte(fg, bg, epsilon)
[m, n, ~] = size(fg);       % fg and bg should be of same size
alpha = zeros(m, n, 3);

A = im2double(fg);
B = im2double(bg);
Delta = A - B;

mask = sqrt(sum((Delta .* Delta), 3)) > epsilon;
mask = repmat(mask, 1, 1, 3);

alpha(mask) = 1;
end