function SNR_Energy
    % 在GUI初始化部分添加
    roiHandles.axes1 = [];
    roiHandles.axes2 = [];
    roiHandles.axes3 = [];
    roiInfo.axes1 = [];
    roiInfo.axes2 = [];
    roiInfo.axes3 = [];
    imgData.axes1 = [];
    imgData.axes2 = [];
    imgData.axes3 = [];
    % 创建主窗口
    fig = uifigure('Name', 'DICOM图像查看器（带ROI功能）', 'Position', [100 100 1400 900]);
    
    % ROI尺寸输入框（所有图像共用一个尺寸）
    uilabel(fig, 'Text', 'ROI尺寸（像素）:', 'Position', [550 750 100 22]);
    roiSizeEdit = uieditfield(fig, 'numeric', 'Position', [660 750 60 22], ...
        'Value', 30, 'Limits', [5 200]);  % 限制尺寸范围5-200像素
    uilabel(fig, 'Text', '（宽×高，正方形）', 'Position', [730 750 120 22]);
    
    % 创建图像显示区域（先创建axes，避免回调函数变量未定义）
    axes1 = uiaxes(fig, 'Position', [30 350 400 300], 'ButtonDownFcn', @(~,~)dummyCallback);
    title(axes1, '图像 1');
    axis(axes1, 'off');
    
    axes2 = uiaxes(fig, 'Position', [460 350 400 300], 'ButtonDownFcn', @(~,~)dummyCallback);
    title(axes2, '图像 2');
    axis(axes2, 'off');
    
    axes3 = uiaxes(fig, 'Position', [890 350 400 300], 'ButtonDownFcn', @(~,~)dummyCallback);
    title(axes3, '图像 3');
    axis(axes3, 'off');
    
    % 存储每个图像的ROI对象和信息
    roiHandles = struct('axes1', [], 'axes2', [], 'axes3', []);
    roiInfo = struct('axes1', [], 'axes2', [], 'axes3', []);
    % 存储每个图像的数据（用于边界判断）
    imgData = struct('axes1', [], 'axes2', [], 'axes3', []);
    
    % 创建文件选择按钮和输入框
    % 第一个DICOM文件
    uilabel(fig, 'Text', 'DICOM文件 1:', 'Position', [30 800 100 22]);
    fileEdit1 = uieditfield(fig, 'text', 'Position', [140 800 300 22], 'Editable', false);
    uibutton(fig, 'push', 'Text', '浏览...', 'Position', [450 800 80 22], ...
        'ButtonPushedFcn', @(s,e) browseDICOM(fileEdit1, axes1, 'axes1'));
    
    % 第二个DICOM文件
    uilabel(fig, 'Text', 'DICOM文件 2:', 'Position', [30 760 100 22]);
    fileEdit2 = uieditfield(fig, 'text', 'Position', [140 760 300 22], 'Editable', false);
    uibutton(fig, 'push', 'Text', '浏览...', 'Position', [450 760 80 22], ...
        'ButtonPushedFcn', @(s,e) browseDICOM(fileEdit2, axes2, 'axes2'));
    
    % 第三个DICOM文件
    uilabel(fig, 'Text', 'DICOM文件 3:', 'Position', [30 720 100 22]);
    fileEdit3 = uieditfield(fig, 'text', 'Position', [140 720 300 22], 'Editable', false);
    uibutton(fig, 'push', 'Text', '浏览...', 'Position', [450 720 80 22], ...
        'ButtonPushedFcn', @(s,e) browseDICOM(fileEdit3, axes3, 'axes3'));
    
    % 底部说明
    uilabel(fig, 'Text', '操作说明：1. 选择DICOM文件 2. 在图像上点击绘制ROI（每个图像最多2个） 3. 可修改ROI尺寸后重新绘制', ...
        'Position', [30 320 800 22], 'FontSize', 10);
    
    % 空回调函数（避免初始状态下点击报错）
    function dummyCallback
    end
    
    % 定义DICOM文件浏览和显示函数
    function browseDICOM(fileEdit, axesHandle, axesName)
        [fileName, filePath] = uigetfile('*.dcm', '选择DICOM文件');
        if isequal(fileName, 0)
            return;
        end
        
        fullPath = fullfile(filePath, fileName);
        fileEdit.Value = fullPath;
        
        try
            % 读取DICOM图像并存储数据
            dicomImage = dicomread(fullPath);
            imgData.(axesName) = dicomImage;  % 保存图像数据用于ROI边界计算
            
            % 显示图像（强制设置图像交互属性）
            imHandle = imshow(dicomImage, [], 'Parent', axesHandle);
            set(imHandle, 'HitTest', 'off');  % 让点击穿透图像到axes
            title(axesHandle, ['图像: ' fileName]);
            axis(axesHandle, 'off');
            
            % 清除旧ROI
            % delete(roiHandles.(axesName));
            % roiHandles.(axesName) = [];
            % roiInfo.(axesName) = [];
            
            % 绑定点击回调函数（关键：确保axes能响应点击）
            axesHandle.ButtonDownFcn = @(s,e) drawROI(s, e, axesHandle, axesName);
        catch err
            uialert(fig, ['读取DICOM文件时出错: ' err.message], '错误');
        end
    end
        % 设置回调
    axesHandle1.ButtonDownFcn = @(s,e) drawROI(s, e, axesHandle1, 'axes1');
    axesHandle2.ButtonDownFcn = @(s,e) drawROI(s, e, axesHandle2, 'axes2');
    % 定义ROI绘制函数（修正坐标获取和ROI创建逻辑）
    % 定义ROI绘制函数（修正重复参数名问题）
        function drawROI(srcAxes, ~, axesHandle, axesName)
        % 获取ROI尺寸
        roiSize = round(roiSizeEdit.Value);
        if isempty(roiSize) || roiSize < 5
            uialert(fig, '请输入有效的ROI尺寸（至少5像素）', '输入错误');
            return;
        end
        
        % 获取点击坐标
        if isa(srcAxes, 'matlab.graphics.primitive.Image')
            parentAxes = srcAxes.Parent;
            clickPos = parentAxes.CurrentPoint;
        else
            clickPos = srcAxes.CurrentPoint;
        end
        
        x = round(clickPos(1,1));
        y = round(clickPos(1,2));
        
        % 检查图像数据
        dicomImage = imgData.(axesName);
        if isempty(dicomImage)
            uialert(fig, '请先加载图像', '错误');
            return;
        end
        
        [imgHeight, imgWidth] = size(dicomImage);
        
        % 计算ROI边界
        halfSize = floor(roiSize / 2);
        x1 = max(1, x - halfSize);
        x2 = min(imgWidth, x + halfSize);
        y1 = max(1, y - halfSize);
        y2 = min(imgHeight, y + halfSize);
        
        % 限制ROI数量
        if length(roiHandles.(axesName)) >= 2
            delete(roiHandles.(axesName)(1));
            roiHandles.(axesName) = roiHandles.(axesName)(2:end);
            roiInfo.(axesName) = roiInfo.(axesName)(2:end);
        end
        
        % 绘制ROI
        roi = rectangle('Parent', axesHandle, ...
            'Position', [x1, y1, x2-x1, y2-y1], ...
            'EdgeColor', 'r', ...
            'LineWidth', 2, ...
            'FaceAlpha', 0, ...
            'HitTest', 'off');
        
        roiHandles.(axesName) = [roiHandles.(axesName); roi];
        roiInfo.(axesName) = [roiInfo.(axesName); struct('x1',x1,'y1',y1,'x2',x2,'y2',y2)];
        
        % 添加标注
        roiIdx = length(roiInfo.(axesName));
        text(x2+5, y1, sprintf('ROI%d: (%d,%d)-(%d,%d)', ...
            roiIdx, x1, y1, x2, y2), ...
            'Parent', axesHandle, ...
            'Color', 'r', ...
            'BackgroundColor', 'w', ...
            'FontSize', 8, ...
            'HitTest', 'off');
    end

end