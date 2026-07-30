function [syncoffset, NumFrames] = PDSCH_FrameSync(sig_rx_all, Fs_val, ...
    samples_per_slot, samples_per_frame, NumFrames_cfg, ...
    DL_Slot_Mask, SystemParam, ...
    TM, CFI, CPType, NumOfAddDMRS, DMRS_port, DMRSLength, DMRS_Type, ...
    DMRS_ScramblingID0, DMRS_ScramblingID1, DMRS_nSCID, dmrs_TypeA_Position, Nr)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PDSCH_FrameSync  — 多天线CP定时与DMRS频域相关帧同步
%
% 通过功率检测定位有效信号区域, CP搜索对齐OFDM边界, DMRS识别时隙/帧头
%
% Input:
%   sig_rx_all        : VSA时域信号 [Nr x N]
%   Fs_val            : 采样率 (Hz)
%   samples_per_slot  : 每时隙样本数
%   samples_per_frame : 每帧样本数
%   NumFrames_cfg     : 配置文件中指定的帧数 (用于上限)
%   DL_Slot_Mask      : DL时隙掩码 [1 x N_slots_frame]
%   SystemParam       : 系统参数结构体 (需含 FFT_size, Nd, LengthOfGI_vec,
%                       Nc_used_CRS, Nc_used_DMRS, Nc_used_CSIRS, Nc_used, Nc)
%   TM, CFI, CPType, NumOfAddDMRS, DMRS_port, DMRSLength, DMRS_Type,
%   DMRS_ScramblingID0, DMRS_ScramblingID1, DMRS_nSCID, dmrs_TypeA_Position, Nr
%                       : PDSCH / DMRS 配置参数
%
% Output:
%   syncoffset  : 帧头(时隙0)距VSA文件开头的样本偏移
%   NumFrames   : 基于同步后有效长度重新计算的可用帧数
%
% 中间变量 (通过 fprintf 输出, 不在返回值中):
%   first_dl_slot, slot_start_offset, corr_quality
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 从 SystemParam 提取局部变量
FFT_size = SystemParam.FFT_size;
Nd       = SystemParam.Nd;
cp_vec   = SystemParam.LengthOfGI_vec;
num_rx_antennas = size(sig_rx_all, 1);
if Nr ~= num_rx_antennas
    warning('帧同步: 配置 Nr=%d 与输入信号天线数=%d 不一致, 以输入信号为准。', ...
        Nr, num_rx_antennas);
    Nr = num_rx_antennas;
end

fprintf('===== 帧同步 (功率检测 + DMRS频域相关) =====\n');

%% Step 1: 确定第一个PDSCH时隙
first_dl_slot = find(DL_Slot_Mask, 1, 'first');
if isempty(first_dl_slot)
    error('DL_Slot_Mask 中没有标记任何PDSCH时隙! 请检查配置。');
end
n_s_f_sync = first_dl_slot - 1;
fprintf('第一个PDSCH时隙: slot #%d (n_s_f=%d)\n', first_dl_slot, n_s_f_sync);

%% Step 2: 生成DMRS参考信号
PilotParam_sync = PDSCH_PilotParamInit(TM, CFI, ...
    SystemParam.Nc_used_CRS, SystemParam.Nc_used_DMRS, SystemParam.Nc_used_CSIRS, ...
    SystemParam.Nc_used, FFT_size, SystemParam.Nc, 0, CPType, NumOfAddDMRS, ...
    Nd, Nd-CFI, DMRS_port, DMRSLength, DMRS_Type, ...
    DMRS_ScramblingID0, DMRS_ScramblingID1, DMRS_nSCID, ...
    dmrs_TypeA_Position, n_s_f_sync);

DMRS_COL_sync = PilotParam_sync.DMRS_COLUMN_INDEX;
DMRS_pos_sync = PilotParam_sync.DMRS_position;
DMRS_sig_sync = PilotParam_sync.DMRS_Signal;
fprintf('DMRS符号位置: [%s]\n', num2str(DMRS_COL_sync(1,:)));

%% Step 3: 功率检测 — 定位有效信号区域
fprintf('--- 功率检测 (定位信号区域) ---\n');
win_len  = samples_per_slot;
win_step = round(samples_per_slot / 4);
num_samples = size(sig_rx_all, 2);
if num_samples < win_len
    error('输入信号长度=%d, 不足一个完整时隙=%d样点。', num_samples, win_len);
end
num_windows = floor((num_samples - win_len) / win_step) + 1;
window_offsets = (0:num_windows-1) * win_step;
pwr = zeros(1, num_windows);
for i = 1:num_windows
    s0 = window_offsets(i) + 1;
    segment = sig_rx_all(:, s0 : s0 + win_len - 1);
    pwr(i) = mean(abs(segment(:)).^2);
end
pwr_sorted  = sort(pwr);
noise_floor = mean(pwr_sorted(1:max(1, round(num_windows*0.25))));
threshold   = noise_floor * 4;   % 6dB above noise floor
above     = pwr > threshold;
above_idx = find(above);
if isempty(above_idx)
    warning('功率检测: 未找到有效信号区域, 使用全文件搜索。');
    search_start = 0;
    signal_end   = num_samples;
else
    % 后续搜索变量全部使用零基样点偏移；signal_end 是右开边界。
    search_start = max(0, window_offsets(above_idx(1)) - win_step);
    signal_end = min(num_samples, ...
        window_offsets(above_idx(end)) + win_len + win_step);
end
fprintf('信号区域: [%.2f, %.2f] ms  (噪声底=%.2e, 阈值=%.2e, %d/%d窗口检测到信号)\n', ...
    search_start/Fs_val*1e3, signal_end/Fs_val*1e3, ...
    noise_floor, threshold, length(above_idx), num_windows);

% 功率分布图
figure(98); clf;
t_ms = window_offsets / Fs_val * 1e3;
plot(t_ms, 10*log10(pwr), 'b.-'); hold on;
yline(10*log10(threshold),   'r--', 'Threshold');
yline(10*log10(noise_floor), 'g--', 'Noise floor');
xlabel('Time (ms)'); ylabel('Power (dB)');
title('Signal Power Detection');
grid on; drawnow;

%% Step 4: 粗搜索 (CP周期搜索, 确定时隙边界相位)
% DMRS频域相关对几十个样点的FFT窗偏移就很敏感，不能用于未对齐的粗网格。
% CP度量不依赖数据和端口内容。步长不超过最短CP的一半，兼容较小FFT。
coarse_step = max(1, min(128, floor(min(cp_vec) / 2)));
last_search_offset = signal_end - samples_per_slot;
coarse_offsets = search_start : coarse_step : last_search_offset;
if isempty(coarse_offsets)
    error('信号区域不足以容纳一个完整时隙! sig_end-sig_start=%d < samples_per_slot=%d', ...
        signal_end-search_start, samples_per_slot);
end
[coarse_cp_metric, cp_metric_cache] = ...
    cp_timing_metric(sig_rx_all, coarse_offsets, FFT_size, cp_vec);

fprintf('粗CP搜索: 范围[%d,%d] 步长=%d (%d个候选)...', ...
    coarse_offsets(1), coarse_offsets(end), coarse_step, length(coarse_offsets));
[~, peak_idx] = max(coarse_cp_metric);
coarse_peak = coarse_offsets(peak_idx);
fprintf('完成, 峰值 offset=%d (%.2fms) CP=%.4f\n', ...
    coarse_peak, coarse_peak/Fs_val*1e3, coarse_cp_metric(peak_idx));

%% Step 5: 精化多个CP相位假设，并在对齐边界上搜索DMRS
% CP在一个时隙内的每个OFDM符号边界都会产生峰。按模时隙距离做非极大值
% 抑制，保留足够多的不同相位，再由DMRS识别真正的时隙首符号。
[~, cp_order] = sort(coarse_cp_metric, 'descend');
max_phase_hypotheses = min(length(cp_order), 2 * Nd);
coarse_phase_offsets = zeros(1, max_phase_hypotheses);
num_phase_hypotheses = 0;
phase_guard = 2 * coarse_step;
for order_idx = 1:length(cp_order)
    candidate_offset = coarse_offsets(cp_order(order_idx));
    candidate_phase = mod(candidate_offset, samples_per_slot);
    if num_phase_hypotheses > 0
        selected_phases = mod(coarse_phase_offsets(1:num_phase_hypotheses), samples_per_slot);
        phase_distance = abs(selected_phases - candidate_phase);
        phase_distance = min(phase_distance, samples_per_slot - phase_distance);
        if any(phase_distance <= phase_guard)
            continue;
        end
    end
    num_phase_hypotheses = num_phase_hypotheses + 1;
    coarse_phase_offsets(num_phase_hypotheses) = candidate_offset;
    if num_phase_hypotheses == max_phase_hypotheses
        break;
    end
end
coarse_phase_offsets = coarse_phase_offsets(1:num_phase_hypotheses);

refine_offsets = [];
refine_groups = cell(1, num_phase_hypotheses);
for phase_idx = 1:num_phase_hypotheses
    refine_start = max(search_start, coarse_phase_offsets(phase_idx) - coarse_step);
    refine_end = min(last_search_offset, coarse_phase_offsets(phase_idx) + coarse_step);
    refine_groups{phase_idx} = length(refine_offsets) + (1:(refine_end-refine_start+1));
    refine_offsets = [refine_offsets, refine_start:refine_end]; %#ok<AGROW>
end
refine_cp_metric = cp_timing_metric(sig_rx_all, refine_offsets, FFT_size, cp_vec, cp_metric_cache);
refined_phases = zeros(1, num_phase_hypotheses);
for phase_idx = 1:num_phase_hypotheses
    group = refine_groups{phase_idx};
    [~, local_peak_idx] = max(refine_cp_metric(group));
    refined_phases(phase_idx) = mod(refine_offsets(group(local_peak_idx)), samples_per_slot);
end
refined_phases = unique(refined_phases);

mid_range = [];
for phase_idx = 1:length(refined_phases)
    slot_phase = refined_phases(phase_idx);
    first_slot_candidate = slot_phase + ...
        ceil((search_start - slot_phase) / samples_per_slot) * samples_per_slot;
    mid_range = [mid_range, first_slot_candidate:samples_per_slot:last_search_offset]; %#ok<AGROW>
end
mid_range = unique(mid_range);
mid_corr = zeros(size(mid_range));
mid_cp_metric = cp_timing_metric(sig_rx_all, mid_range, FFT_size, cp_vec, cp_metric_cache);

fprintf('对齐时隙搜索: %d个CP相位, %d个DMRS候选...', ...
    length(refined_phases), length(mid_range));
tic;
for idx = 1:length(mid_range)
    offset = mid_range(idx);
    seg = sig_rx_all(:, offset + 1 : offset + samples_per_slot);
    FFT_Out_test = OFDM_DeModulater(seg, FFT_size, cp_vec, samples_per_slot, Nr, Nd, ones(1, Nd));
    mid_corr(idx) = dmrs_correlation(FFT_Out_test, DMRS_COL_sync, DMRS_pos_sync, DMRS_sig_sync, Nr, DMRS_port);
end
fprintf('完成 (%.1fs)\n', toc);

mid_corr_normalized = mid_corr / max(max(mid_corr), eps);
mid_sync_score = mid_corr_normalized .* mid_cp_metric;
[~, mid_peak_idx] = max(mid_sync_score);
mid_peak = mid_range(mid_peak_idx);
fprintf('对齐DMRS峰值: offset=%d (%.3fms) corr=%.4f CP=%.4f score=%.4f\n', ...
    mid_peak, mid_peak/Fs_val*1e3, mid_corr(mid_peak_idx), ...
    mid_cp_metric(mid_peak_idx), mid_sync_score(mid_peak_idx));

%% Step 6: 精细搜索 (DMRS相关 + CP符号边界度量)
fine_half = coarse_step;
fine_start = max(search_start, mid_peak - fine_half);
fine_end   = min(last_search_offset, mid_peak + fine_half);
fine_range = fine_start : fine_end;
fine_corr  = zeros(size(fine_range));
fine_cp_metric = cp_timing_metric(sig_rx_all, fine_range, FFT_size, cp_vec, cp_metric_cache);

fprintf('精搜索: 范围[%d,%d] 步长=1 (%d个候选)...', fine_start, fine_end, length(fine_range));
tic;
for idx = 1:length(fine_range)
    offset = fine_range(idx);
    seg = sig_rx_all(:, offset + 1 : offset + samples_per_slot);
    FFT_Out_test = OFDM_DeModulater(seg, FFT_size, cp_vec, samples_per_slot, Nr, Nd, ones(1, Nd));
    fine_corr(idx) = dmrs_correlation(FFT_Out_test, DMRS_COL_sync, DMRS_pos_sync, DMRS_sig_sync, Nr, DMRS_port);
end
fprintf('完成 (%.1fs)\n', toc);

% DMRS相关在窄带资源分配时可能存在局部假峰；CP相关用于约束真实OFDM符号边界。
% 两项均归一化后相乘，只有同时满足DMRS匹配与CP对齐的候选才会胜出。
fine_corr_normalized = fine_corr / max(max(fine_corr), eps);
fine_sync_score = fine_corr_normalized .* fine_cp_metric;
[~, fine_peak_idx] = max(fine_sync_score);
slot_start_offset = fine_range(fine_peak_idx);
peak_corr_value   = fine_corr(fine_peak_idx);
peak_cp_metric    = fine_cp_metric(fine_peak_idx);

%% Step 7: 质量评估
valid_score = fine_sync_score(fine_sync_score > 0);
if isempty(valid_score)
    corr_quality = 1.0;
    warning('帧同步: 所有相关值均为0, 同步可能失败!');
else
    corr_quality = fine_sync_score(fine_peak_idx) / mean(valid_score);
end
if corr_quality < 3.0
    warning('帧同步: 相关质量偏低 (%.1fx < 3.0x), 同步结果可能不可靠.', corr_quality);
end

%% Step 8: 计算帧头位置
syncoffset = slot_start_offset - (first_dl_slot - 1) * samples_per_slot;
if syncoffset < 0
    syncoffset = syncoffset + samples_per_frame;
end

%% Step 9: 计算可用帧数
usable_len     = num_samples - syncoffset;
NumFrames_sync = max(0, floor(usable_len / samples_per_frame));
NumFrames      = min(NumFrames_cfg, NumFrames_sync);

%% Step 10: 输出
fprintf('========================================\n');
fprintf('帧同步结果:\n');
fprintf('  syncoffset       = %d 样点 (%.2f ms, 帧头距VSA开头)\n', ...
    syncoffset, syncoffset / Fs_val * 1e3);
fprintf('  第一个PDSCH时隙   = slot#%d, 起始偏移 %d 样点 (%.2f ms)\n', ...
    first_dl_slot, slot_start_offset, slot_start_offset / Fs_val * 1e3);
fprintf('  相关峰值          = %.2f (质量因子=%.1fx)\n', peak_corr_value, corr_quality);
fprintf('  CP边界度量        = %.4f (联合评分=%.4f)\n', ...
    peak_cp_metric, fine_sync_score(fine_peak_idx));
fprintf('  三级搜索           = 粗CP(%d) → 对齐DMRS(%d) → 精搜(%d) 候选\n', ...
    length(coarse_cp_metric), length(mid_corr), length(fine_corr));
fprintf('  可用帧数          = %d (VSA总长=%d样点=%.1fms, 信号区域=[%.1f,%.1f]ms)\n', ...
    NumFrames, num_samples, num_samples/Fs_val*1e3, ...
    search_start/Fs_val*1e3, signal_end/Fs_val*1e3);
fprintf('========================================\n');

%% Step 11: 绘制三级相关曲线
figure(99); clf;
subplot(3,1,1);
plot(coarse_offsets/Fs_val*1e3, coarse_cp_metric, 'b.-');
hold on; plot(coarse_peak/Fs_val*1e3, coarse_cp_metric(peak_idx), 'ro', 'MarkerSize', 10);
xlabel('Offset (ms)'); ylabel('CP metric');
title(sprintf('Coarse CP (step=%d, %d candidates)', coarse_step, length(coarse_offsets)));
grid on;

subplot(3,1,2);
plot(mid_range/Fs_val*1e3, mid_sync_score, 'b.-');
hold on; plot(mid_peak/Fs_val*1e3, mid_sync_score(mid_peak_idx), 'ro', 'MarkerSize', 10);
xlabel('Offset (ms)'); ylabel('Joint score');
title(sprintf('Aligned-slot DMRS x CP (%d candidates)', length(mid_range)));
grid on;

subplot(3,1,3);
plot(fine_range/Fs_val*1e3, fine_sync_score, 'b.-');
hold on; plot(slot_start_offset/Fs_val*1e3, fine_sync_score(fine_peak_idx), 'ro', 'MarkerSize', 10);
xlabel('Offset (ms)'); ylabel('Joint score');
title(sprintf('Fine DMRS (peak=%.3fms, CP=%.3f)', ...
    slot_start_offset/Fs_val*1e3, peak_cp_metric));
grid on;
drawnow;

end

%% ========================================================================
%% 子函数: 频域DMRS相关 (支持多层/多天线)
%% ========================================================================
function corr_val = dmrs_correlation(FFT_Out, DMRS_COL, DMRS_pos, DMRS_sig, Nr, DMRS_port)
% 在OFDM解调后的频域网格中提取所有端口DMRS。
% 各接收天线/端口先做匹配滤波，再以相关功率进行非相干合并；最后按
% 接收与参考能量归一化，避免某根高增益天线或错位窗口的能量主导定时。
%   FFT_Out    : Nr x FFT_size x Nd
%   DMRS_COL   : DMRS_port x N_sym, DMRS所在OFDM符号索引
%   DMRS_pos   : DMRS_port x N_sc x N_sym, DMRS子载波位置
%   DMRS_sig   : DMRS_port x N_sc x N_sym, DMRS参考信号
%   Nr         : 接收天线数
%   DMRS_port  : DMRS端口数
corr_power = 0;
normalization = 0;
for nra = 1:Nr
    for pt = 1:DMRS_port
        for np = 1:size(DMRS_COL, 2)
            col = DMRS_COL(pt, np);
            if isnan(col), continue; end
            pos   = DMRS_pos(pt, :, np);
            valid = ~isnan(pos);
            rx_dmrs = squeeze(FFT_Out(nra, pos(valid), col));
            tx_dmrs = squeeze(DMRS_sig(pt, valid, np));
            matched = sum(conj(tx_dmrs(:)) .* rx_dmrs(:));
            corr_power = corr_power + abs(matched)^2;
            normalization = normalization + ...
                sum(abs(tx_dmrs(:)).^2) * sum(abs(rx_dmrs(:)).^2);
        end
    end
end
corr_val = corr_power / max(normalization, eps);
end
