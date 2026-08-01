function [peak_indices, absolute_threshold] = PDSCH_DetectFramePeaks(...
    offsets, scores, Fs_val)
%PDSCH_DETECTFRAMEPEAKS Detect NR frames from aligned-slot DMRS x CP peaks.

validateattributes(offsets, {'numeric'}, ...
    {'real', 'finite', 'vector', 'nonempty'});
validateattributes(scores, {'numeric'}, ...
    {'real', 'finite', 'vector', 'nonempty', 'nonnegative'});
validateattributes(Fs_val, {'numeric'}, ...
    {'real', 'finite', 'scalar', 'positive'});
if numel(offsets) ~= numel(scores)
    error('PDSCH_DetectFramePeaks:SizeMismatch', ...
        'offsets and scores must contain the same number of elements.');
end
if any(diff(offsets) <= 0)
    error('PDSCH_DetectFramePeaks:OffsetsNotIncreasing', ...
        'offsets must be strictly increasing.');
end

offsets = offsets(:).';
scores = scores(:).';
relative_threshold = 0.30;
minimum_peak_distance = round(0.8 * 10e-3 * Fs_val);
absolute_threshold = relative_threshold * max(scores);
if max(scores) <= eps
    [~, peak_indices] = max(scores);
    warning('帧同步: 联合评分全为0，退化为使用全局最大候选。');
    return;
end

is_local_maximum = true(size(scores));
if numel(scores) > 1
    is_local_maximum(1) = scores(1) >= scores(2);
    is_local_maximum(end) = scores(end) >= scores(end-1);
end
if numel(scores) > 2
    is_local_maximum(2:end-1) = ...
        scores(2:end-1) >= scores(1:end-2) & ...
        scores(2:end-1) >= scores(3:end);
end

candidates = find(is_local_maximum & scores >= absolute_threshold);
if isempty(candidates)
    [~, peak_indices] = max(scores);
    warning('帧同步: 没有候选超过帧峰阈值，退化为使用全局最大峰。');
    return;
end

[~, score_order] = sort(scores(candidates), 'descend');
selected = zeros(1, numel(candidates));
num_selected = 0;
for order_index = 1:numel(score_order)
    candidate = candidates(score_order(order_index));
    if num_selected > 0 && any(abs(offsets(candidate) - ...
            offsets(selected(1:num_selected))) < minimum_peak_distance)
        continue;
    end
    num_selected = num_selected + 1;
    selected(num_selected) = candidate;
end
peak_indices = sort(selected(1:num_selected));
end
