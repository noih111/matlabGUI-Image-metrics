function debugROICallback()
    % 创建测试图形
    fig = figure('Name', 'Dicom_指标计算_SNR&Energy', 'NumberTitle', 'off', 'Position', [100 100 1400 700]);
    
    % 创建坐标轴 - 初始时隐藏
    ax1 = subplot(1,3,1);
    ax2 = subplot(1,3,2);
    ax3 = subplot(1,3,3);
    
    % 初始时隐藏所有坐标轴
    set([ax1, ax2, ax3], 'Visible', 'off');
    
    % 创建文件选择按钮和输入框
    % 第一个DICOM文件
    uicontrol('Style', 'text', 'Position', [30 650 150 20], 'String', 'DICOM文件 高分辨参考图:');
    fileEdit1 = uicontrol('Style', 'edit', 'Position', [170 650 300 20], 'String', '', 'Enable', 'off');
    uicontrol('Style', 'pushbutton', 'Position', [480 650 80 20], 'String', '浏览...', ...
        'Callback', @(s,e) browseDICOM(fileEdit1, ax1, 'axes1'));
    
    % 第二个DICOM文件
    uicontrol('Style', 'text', 'Position', [30 620 150 20], 'String', 'DICOM文件 插值:');
    fileEdit2 = uicontrol('Style', 'edit', 'Position', [170 620 300 20], 'String', '', 'Enable', 'off');
    uicontrol('Style', 'pushbutton', 'Position', [480 620 80 20], 'String', '浏览...', ...
        'Callback', @(s,e) browseDICOM(fileEdit2, ax2, 'axes2'));
    
    % 第三个DICOM文件
    uicontrol('Style', 'text', 'Position', [30 590 150 20], 'String', 'DICOM文件 SmartClarity:');
    fileEdit3 = uicontrol('Style', 'edit', 'Position', [170 590 300 20], 'String', '', 'Enable', 'off');
    uicontrol('Style', 'pushbutton', 'Position', [480 590 80 20], 'String', '浏览...', ...
        'Callback', @(s,e) browseDICOM(fileEdit3, ax3, 'axes3'));
    % 
    % % ROI尺寸输入
    % uicontrol('Style', 'text', 'Position', [30 550 100 20], 'String', 'ROI尺寸:');
    % roiSizeEdit = uicontrol('Style', 'edit', 'Position', [140 550 80 20], 'String', '20');
    
    % 添加计算按钮
    uicontrol('Style', 'pushbutton', 'Position', [30 500 100 30], 'String', '计算指标', ...
        'Callback', @calculateROIData, 'FontSize', 10);
    
    % 结果显示区域
    resultText = uicontrol('Style', 'text', 'Position', [30 50 600 180], ...
        'String', '指标数据将显示在这里', ...
        'FontSize', 10, 'HorizontalAlignment', 'left', 'BackgroundColor', [0.95 0.95 0.95]);
    
    % 初始化数据结构
    imgData.axes1 = [];
    imgData.axes2 = [];
    imgData.axes3 = [];
    
    % roiHandles.axes1 = [];
    % roiHandles.axes2 = [];
    % roiHandles.axes3 = [];
    % 
    % roiInfo.axes1 = [];
    % roiInfo.axes2 = [];
    % roiInfo.axes3 = [];
    
    % 存储变量到figure的应用数据
    setappdata(fig, 'imgData', imgData);
    % setappdata(fig, 'roiHandles', roiHandles);
    % setappdata(fig, 'roiInfo', roiInfo);
    % setappdata(fig, 'roiSizeEdit', roiSizeEdit);
    setappdata(fig, 'resultText', resultText);
    
    % 添加提示文本并保存句柄
    promptText = uicontrol('Style', 'text', 'Position', [200 400 300 30], ...
        'String', '请使用上方按钮选择DICOM文件', ...
        'FontSize', 14, 'ForegroundColor', [0.5 0.5 0.5]);
    setappdata(fig, 'promptText', promptText);
    
    disp('请使用浏览按钮选择DICOM文件，然后点击图像绘制ROI');
    
    % 文件浏览函数
    function browseDICOM(fileEdit, axesHandle, axesName)
        [fileName, filePath] = uigetfile('*.dcm', '选择DICOM文件');
        if isequal(fileName, 0)
            return; % 用户取消选择
        end
        
        fullPath = fullfile(filePath, fileName);
        set(fileEdit, 'String', fullPath);
        
        try
            % 读取DICOM图像
            dicomImage = dicomread(fullPath);
            
            % 更新图像数据
            imgData = getappdata(fig, 'imgData');
            imgData.(axesName) = dicomImage;
            setappdata(fig, 'imgData', imgData);
            
            % % 清除之前的ROI和标签
            % clearROIs(axesHandle, axesName);
            
            % 显示坐标轴并设置属性
            set(axesHandle, 'Visible', 'on');
            
            % 显示图像
            himg = imshow(dicomImage, [], 'Parent', axesHandle);
            
            % 设置回调
            set(axesHandle, 'ButtonDownFcn', {@debugDrawROI, axesHandle, axesName});
            set(himg, 'ButtonDownFcn', {@debugDrawROI, axesHandle, axesName});
            
            % 更新标题
            title(axesHandle, sprintf('图像: %s', fileName));
            
            % 移除提示文本（如果存在）
            promptText = getappdata(fig, 'promptText');
            if ishandle(promptText)
                delete(promptText);
                setappdata(fig, 'promptText', []);
            end
            
            fprintf('已加载图像到 %s，尺寸: %dx%d\n', axesName, size(dicomImage, 1), size(dicomImage, 2));
            
        catch ME
            errordlg(['读取DICOM文件时出错: ' ME.message], '错误');
        end
    end
    
    % % 清除ROI函数
    % function clearROIs(axesHandle, axesName)
    %     % 从应用数据获取变量
    %     roiHandles = getappdata(fig, 'roiHandles');
    %     roiInfo = getappdata(fig, 'roiInfo');
    % 
    %     % 删除所有ROI矩形
    %     if ~isempty(roiHandles.(axesName))
    %         for i = 1:length(roiHandles.(axesName))
    %             if isvalid(roiHandles.(axesName)(i))
    %                 delete(roiHandles.(axesName)(i));
    %             end
    %         end
    %         roiHandles.(axesName) = [];
    %     end
    % 
    %     % 删除所有ROI文本标签
    %     if ~isempty(roiInfo.(axesName))
    %         for i = 1:length(roiInfo.(axesName))
    %             if isfield(roiInfo.(axesName)(i), 'textHandle') && isvalid(roiInfo.(axesName)(i).textHandle)
    %                 delete(roiInfo.(axesName)(i).textHandle);
    %             end
    %         end
    %         roiInfo.(axesName) = [];
    %     end
    % 
    %     % 更新应用数据
    %     setappdata(fig, 'roiHandles', roiHandles);
    %     setappdata(fig, 'roiInfo', roiInfo);
    % end
    % 
    % % ROI绘制函数
    % function debugDrawROI(srcAxes, ~, axesHandle, axesName)
    %     fprintf('\n=== 回调函数被调用 ===\n');
    %     fprintf('来源对象类型: %s\n', class(srcAxes));
    %     fprintf('目标坐标轴: %s\n', axesName);
    % 
    %     % 从应用数据获取变量
    %     imgData = getappdata(fig, 'imgData');
    %     roiHandles = getappdata(fig, 'roiHandles');
    %     roiInfo = getappdata(fig, 'roiInfo');
    %     roiSizeEdit = getappdata(fig, 'roiSizeEdit');
    % 
    %     % 检查是否有图像数据
    %     if isempty(imgData.(axesName))
    %         errordlg('请先加载图像', '错误');
    %         return;
    %     end
    % 
    %     % 获取点击坐标
    %     if isa(srcAxes, 'matlab.graphics.primitive.Image')
    %         parentAxes = srcAxes.Parent;
    %         clickPos = parentAxes.CurrentPoint;
    %         fprintf('从父坐标轴获取点击位置\n');
    %     else
    %         clickPos = srcAxes.CurrentPoint;
    %         fprintf('直接从坐标轴获取点击位置\n');
    %     end
    % 
    %     x = round(clickPos(1,1));
    %     y = round(clickPos(1,2));
    %     fprintf('点击位置: (%d, %d)\n', x, y);
    % 
    %     % 获取ROI尺寸
    %     roiSize = str2double(get(roiSizeEdit, 'String'));
    %     if isnan(roiSize) || roiSize < 5
    %         errordlg('请输入有效的ROI尺寸（至少5像素）', '输入错误');
    %         return;
    %     end
    %     roiSize = round(roiSize);
    % 
    %     % 获取图像尺寸
    %     imgSize = size(imgData.(axesName));
    %     imgHeight = imgSize(1);
    %     imgWidth = imgSize(2);
    % 
    %     % 计算ROI边界
    %     halfSize = floor(roiSize / 2);
    %     x1 = max(1, x - halfSize);
    %     x2 = min(imgWidth, x + halfSize);
    %     y1 = max(1, y - halfSize);
    %     y2 = min(imgHeight, y + halfSize);
    % 
    %     % 限制ROI数量（最多保留2个）
    %     if length(roiHandles.(axesName)) >= 2
    %         % 删除第一个ROI的矩形和文本
    %         if isvalid(roiHandles.(axesName)(1))
    %             delete(roiHandles.(axesName)(1));
    %         end
    %         if isfield(roiInfo.(axesName)(1), 'textHandle') && isvalid(roiInfo.(axesName)(1).textHandle)
    %             delete(roiInfo.(axesName)(1).textHandle);
    %         end
    % 
    %         % 从数组中移除
    %         roiHandles.(axesName) = roiHandles.(axesName)(2:end);
    %         roiInfo.(axesName) = roiInfo.(axesName)(2:end);
    %     end
    % 
    %     % 绘制ROI
    %     roi = rectangle('Parent', axesHandle, ...
    %         'Position', [x1, y1, x2-x1, y2-y1], ...
    %         'EdgeColor', 'r', ...
    %         'LineWidth', 0.5, ...
    %         'HitTest', 'off');
    % 
    %     % 添加标注
    %     roiIdx = length(roiInfo.(axesName)) + 1;
    %     textHandle = text(x2+5, y1, sprintf('ROI%d: (%d,%d)-(%d,%d)', ...
    %         roiIdx, x1, y1, x2, y2), ...
    %         'Parent', axesHandle, ...
    %         'Color', 'r', ...
    %         'BackgroundColor', 'none', ...
    %         'FontSize', 8, ...
    %         'HitTest', 'off');
    % 
    %     % 更新ROI信息
    %     roiHandles.(axesName) = [roiHandles.(axesName); roi];
    %     roiInfo.(axesName) = [roiInfo.(axesName); struct('x1',x1,'y1',y1,'x2',x2,'y2',y2, 'textHandle', textHandle)];
    % 
    %     % 更新应用数据
    %     setappdata(fig, 'roiHandles', roiHandles);
    %     setappdata(fig, 'roiInfo', roiInfo);
    % 
    %     fprintf('已绘制ROI%d，位置: (%d,%d)-(%d,%d)\n', roiIdx, x1, y1, x2, y2);
    % end
    % 
    function cp=PSNR(im_ori,im_rec)
        mse = mean(mean(abs(im_ori - im_rec).^2));
        peakval = max(im_ori(:));
        cp = 10*log10(peakval.^2/mse);
    end
    % 计算ROI数据函数
    function calculateROIData(~, ~)
        % 从应用数据获取变量
        imgData = getappdata(fig, 'imgData');
        % roiInfo = getappdata(fig, 'roiInfo');
        resultText = getappdata(fig, 'resultText');
        
        % 初始化结果字符串
        resultStr = '指标数据结果:\n\n';
        
        % 遍历所有坐标轴
        axesNames = {'axes1', 'axes2', 'axes3'};
        % SNR
        for i = 1:length(axesNames)
            axName = axesNames{i};
            image{i} = double(imgData.(axName));
        end
        high_rever = image{1};
        high_Cubic = image{2};
        high_SmartClarity = image{3};

        psnr_Cubic = PSNR(high_rever, high_Cubic);
        psnr_SmartClarity = PSNR(high_rever, high_SmartClarity);

        ssim_Cubic = ssim(high_Cubic, high_rever);
        ssim_SmartClarity = ssim(high_SmartClarity, high_rever);

        psnr_Cubic_str = num2str(psnr_Cubic, '%.2f');
        psnr_SmartClarity_str = num2str(psnr_SmartClarity, '%.2f');
        ssim_Cubic_str = num2str(ssim_Cubic, '%.2f');
        ssim_SmartClarity_str = num2str(ssim_SmartClarity, '%.2f');

        resultStr = [resultStr, 'Cubic的PSNR为：', psnr_Cubic_str,'   SmartClarity的PSNR为：', psnr_SmartClarity_str,'    （越大越好）',...
                                '\nCubic的SSIM为：', ssim_Cubic_str,'   SmartClarity的SSIM为：', ssim_SmartClarity_str,'    （越大越好）'];


        
        
        % 更新结果显示
        if length(resultStr) > 20 % 确保有实际内容
            set(resultText, 'String', sprintf(resultStr));
        else
            set(resultText, 'String', '没有找到ROI数据，请先绘制ROI');
        end
        
        % 更新应用数据
        setappdata(fig, 'imgData', imgData);
        
        % 在命令窗口也显示结果
        fprintf('\n=== ROI数据计算结果 ===\n');
        fprintf(resultStr);
        
        % 提示用户数据已准备好
        % msgbox('ROI数据已计算完成，可在界面和命令窗口查看结果', '计算完成');
    end
    end
