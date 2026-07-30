function [metric, cache] = cp_timing_metric(signal, offset, fftSize, cpVec, cache)
% CP_TIMING_METRIC 计算一个或多个零基偏移处的多天线 CP 相关度量。
% 可选 cache 返回/复用整段信号的相关与能量前缀和，供多级搜索避免重复计算。

if nargin < 5
    cache = [];
end

offsetShape = size(offset);
offsets = offset(:).';
metric = zeros(size(offsets));
if isempty(offsets)
    metric = reshape(metric, offsetShape);
    return;
end

numSamples = size(signal, 2);
slotLength = numel(cpVec) * fftSize + sum(cpVec);
valid = isfinite(offsets) & offsets == floor(offsets) & ...
    offsets >= 0 & offsets + slotLength <= numSamples;
if ~any(valid) || numSamples <= fftSize
    metric = reshape(metric, offsetShape);
    return;
end

if isempty(cache)
    lagLength = numSamples - fftSize;
    lagCorrelation = zeros(1, lagLength);
    leadingEnergy = zeros(1, lagLength);
    trailingEnergy = zeros(1, lagLength);
    for antennaIndex = 1:size(signal, 1)
        leading = signal(antennaIndex, 1:lagLength);
        trailing = signal(antennaIndex, fftSize + 1:numSamples);
        lagCorrelation = lagCorrelation + leading .* conj(trailing);
        leadingEnergy = leadingEnergy + abs(leading).^2;
        trailingEnergy = trailingEnergy + abs(trailing).^2;
    end
    cache.numSamples = numSamples;
    cache.fftSize = fftSize;
    cache.correlationPrefix = [0, cumsum(lagCorrelation)];
    cache.leadingPrefix = [0, cumsum(leadingEnergy)];
    cache.trailingPrefix = [0, cumsum(trailingEnergy)];
elseif cache.numSamples ~= numSamples || cache.fftSize ~= fftSize
    error('cp_timing_metric:InvalidCache', ...
        'CP度量缓存与当前信号长度或FFT大小不匹配。');
end

correlationPrefix = cache.correlationPrefix;
leadingPrefix = cache.leadingPrefix;
trailingPrefix = cache.trailingPrefix;

validOffsets = offsets(valid);
correlationSum = zeros(size(validOffsets));
energyCp = zeros(size(validOffsets));
energyTail = zeros(size(validOffsets));
symbolStart = validOffsets;
for symbolIndex = 1:numel(cpVec)
    cpLength = cpVec(symbolIndex);
    rangeStart = symbolStart + 1;
    rangeEnd = rangeStart + cpLength - 1;
    correlationSum = correlationSum + ...
        correlationPrefix(rangeEnd + 1) - correlationPrefix(rangeStart);
    energyCp = energyCp + ...
        leadingPrefix(rangeEnd + 1) - leadingPrefix(rangeStart);
    energyTail = energyTail + ...
        trailingPrefix(rangeEnd + 1) - trailingPrefix(rangeStart);
    symbolStart = symbolStart + cpLength + fftSize;
end

metric(valid) = abs(correlationSum) ./ sqrt(energyCp .* energyTail + eps);
metric = reshape(metric, offsetShape);
end
