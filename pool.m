path = 'E:\wandong\chaofen\org1\0010008.dcm';
img = double(dicomread(path));
low_revolution = myAveragePool(img,[2 2]);
% 首先归一化到0-1范围
normalizedImg = mat2gray(low_revolution);
% 然后缩放到0-65535范围
dicomImage = uint16(normalizedImg * 65535);

dicomwrite(dicomImage, 'org1_0010008.dcm');



function output = myAveragePool(input, poolSize)
    % 使用卷积实现平均池化
    % input: 输入矩阵
    % poolSize: 池化窗口大小 [height, width]
    
    % 创建平均滤波器
    kernel = ones(poolSize) / prod(poolSize);
    
    % 使用'valid'模式进行卷积（无填充）
    output = conv2(input, kernel, 'valid');
    
    % 下采样到正确的尺寸
    output = output(1:poolSize(1):end, 1:poolSize(2):end);
end