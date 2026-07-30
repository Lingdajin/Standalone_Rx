function [sigRxAll, fsVal, centerFreq, nr] = load_standalone_vsa(vsaFile)
% LOAD_STANDALONE_VSA 加载VSA文件并转换为接收机输入格式。
% 文件 Y 的行是采样点、列是接收天线；返回值为 [Nr x 采样点]。

vsa = load(vsaFile);
if ~isfield(vsa, 'Y') || isempty(vsa.Y)
    error('VSA文件未包含非空信号变量 Y: %s', vsaFile);
end
if ~isfield(vsa, 'XDelta') || ~isscalar(vsa.XDelta) || ...
        ~isnumeric(vsa.XDelta) || ~isfinite(vsa.XDelta) || vsa.XDelta <= 0
    error('VSA文件未包含有效 XDelta，无法确定采样率: %s', vsaFile);
end

signal = double(vsa.Y);
if isvector(signal)
    signal = signal(:);
elseif ~ismatrix(signal)
    error('VSA信号 Y 必须是 [采样点 x 天线] 的二维矩阵。');
end

nr = size(signal, 2);
if isfield(vsa, 'NumAntennas') && isscalar(vsa.NumAntennas) && ...
        isnumeric(vsa.NumAntennas) && vsa.NumAntennas ~= nr
    warning('VSA文件 NumAntennas=%d 与 Y 的列数=%d 不一致；以 Y 的列数为准。', ...
        vsa.NumAntennas, nr);
end

sigRxAll = signal.';
fsVal = 1 / vsa.XDelta;
if isfield(vsa, 'InputCenter') && isscalar(vsa.InputCenter) && ...
        isnumeric(vsa.InputCenter) && isfinite(vsa.InputCenter)
    centerFreq = vsa.InputCenter;
else
    centerFreq = 0;
end
end