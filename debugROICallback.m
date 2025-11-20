function debugROICallback()
    % 创建测试图形
    fig = figure('Name', 'Dicom_指标计算_SNR&Energy', 'NumberTitle', 'off');
    
    % 创建坐标轴
    ax1 = subplot(1,3,1);
    ax2 = subplot(1,3,2);
    ax3 = subplot(1,3,3);

    % 创建测试图像
    path1 = 'E:\干扰伪影\fst2-1\fst2-1\0010004.dcm';
    path2 = 'E:\干扰伪影\fst2-1\fst2-1\0010004.dcm';
    path3 = 'E:\干扰伪影\fst2-1\fst2-1\0010004.dcm';
    dicomImage1 = dicomread(path1);
    dicomImage2 = dicomread(path2);
    dicomImage3 = dicomread(path3);
  
    testImg1 = dicomImage1; 
    testImg2 = dicomImage2;
    testImg3 = dicomImage3;
    
    % 显示图像
    himg1 = imshow(testImg1,[], 'Parent', ax1);
    himg2 = imshow(testImg2,[], 'Parent', ax2);
    himg3 = imshow(testImg3,[], 'Parent', ax3);
    
    title(ax1, '坐标轴1');
    title(ax2, '坐标轴2');
    title(ax3, '坐标轴3');
    
    % 初始化必要的变量
    initDebugEnvironment(ax1, ax2, ax3, dicomImage1, dicomImage2, dicomImage3);
    
    % 设置回调
    set(ax1, 'ButtonDownFcn', {@debugDrawROI, ax1, 'axes1'});
    % set(ax2, 'ButtonDownFcn', {@debugDrawROI, ax2, 'axes2'});
    % set(ax3, 'ButtonDownFcn', {@debugDrawROI, ax3, 'axes3'});
    set(himg1, 'ButtonDownFcn', {@debugDrawROI, ax1, 'axes1'});
    % set(himg2, 'ButtonDownFcn', {@debugDrawROI, ax2, 'axes2'});
    % set(himg3, 'ButtonDownFcn', {@debugDrawROI, ax3, 'axes2'});
    
    disp('调试环境已设置完成，请点击图像测试回调函数');
end

function initDebugEnvironment(ax1, ax2, ax3, img1, img2, img3)
    % 模拟您的全局变量
    global roiSizeEdit fig imgData roiHandles roiInfo imgHeight1 imgWidth1 ...
        imgHeight2 imgWidth2 imgHeight3 imgWidth3
    fig = gcf;
    
    % 创建模拟的ROI尺寸编辑框
    roiSizeEdit = uicontrol('Style', 'edit', ...
        'Position', [50 20 100 30], ...
        'String', '30', ...
        'Value', 30);
    
    % 初始化数据结构
    imgData.axes1 = magic(200);
    imgData.axes2 = magic(200);
    imgData.axes3 = magic(200);
    
    roiHandles.axes1 = [];
    roiHandles.axes2 = [];
    roiHandles.axes3 = [];
    
    roiInfo.axes1 = [];
    roiInfo.axes2 = [];
    roiInfo.axes3 = [];

    [imgHeight1, imgWidth1] = size(img1);
    [imgHeight2, imgWidth2] = size(img2);
    [imgHeight3, imgWidth3] = size(img3);

end

function debugDrawROI(srcAxes, ~, axesHandle, axesName)
    global imgHeight1 imgWidth1 roiHandles roiInfo
    fprintf('\n=== 回调函数被调用 ===\n');
    fprintf('来源对象类型: %s\n', class(srcAxes));
    fprintf('目标坐标轴: %s\n', axesName);
    
    % 修正：正确处理图像对象
    if isa(srcAxes, 'matlab.graphics.primitive.Image')
        parentAxes = srcAxes.Parent;
        clickPos = parentAxes.CurrentPoint;
        fprintf('从父坐标轴获取点击位置\n');
    else
        clickPos = srcAxes.CurrentPoint;
        fprintf('直接从坐标轴获取点击位置\n');
    end
    
    x = round(clickPos(1,1));
    y = round(clickPos(1,2));
    fprintf('点击位置: (%d, %d)\n', x, y);
    
    % 计算ROI边界
    roiSize = 20;
    halfSize = floor(roiSize / 2);
    x1 = max(1, x - halfSize);
    x2 = min(imgWidth1, x + halfSize);
    y1 = max(1, y - halfSize);
    y2 = min(imgHeight1, y + halfSize);
    
    
    % 绘制ROI
    roi = rectangle('Parent', axesHandle, ...
        'Position', [x1, y1, x2-x1, y2-y1], ...
        'EdgeColor', 'r', ...
        'LineWidth', 2, ...
        'HitTest', 'off');
    roiHandles.(axesName) = [roiHandles.(axesName); roi];
    roiInfo.(axesName) = [roiInfo.(axesName); struct('x1',x1,'y1',y1,'x2',x2,'y2',y2)];
    % 添加标注
    roiIdx = length(roiInfo.(axesName));
    text(x2+5, y1, sprintf('ROI%d: (%d,%d)-(%d,%d)', ...
        roiIdx, x1, y1, x2, y2), ...
        'Parent', axesHandle, ...
        'Color', 'r', ...
        'BackgroundColor', 'none', ...
        'FontSize', 8, ...
        'HitTest', 'off');
end