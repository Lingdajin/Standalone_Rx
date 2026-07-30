function [sig_rx_comp, freq_offset_hz] = PDSCH_FreqOffsetComp(sig_rx_all, Fs_val, ...
    syncoffset, samples_per_slot, samples_per_frame, ...
    DL_Slot_Mask, SystemParam, ...
    TM, CFI, CPType, NumOfAddDMRS, DMRS_port, DMRSLength, DMRS_Type, ...
    DMRS_ScramblingID0, DMRS_ScramblingID1, DMRS_nSCID, dmrs_TypeA_Position, Nr) %#ok<INUSD>
% PDSCH_FREQOFFSETCOMP Estimate and compensate common CFO from cyclic prefixes.
% Long-interval DMRS phase differences are not suitable in a time-varying
% CDL channel because they contain both oscillator CFO and channel Doppler.

fftSize = SystemParam.FFT_size;
cpLengths = SystemParam.LengthOfGI_vec;
numSamples = size(sig_rx_all, 2);
numRx = size(sig_rx_all, 1);
if Nr ~= numRx
    warning('频偏估计: 配置 Nr=%d 与输入天线数=%d 不一致，以输入为准。', Nr, numRx);
end

fprintf('===== 频偏估计与补偿 (多天线CP相关) =====\n');

dlSlots = find(DL_Slot_Mask);
if isempty(dlSlots)
    warning('频偏估计: DL_Slot_Mask中没有PDSCH时隙，跳过补偿。');
    sig_rx_comp = sig_rx_all;
    freq_offset_hz = 0;
    return;
end

slotOffsets = syncoffset + (dlSlots - 1) * samples_per_slot;
validSlots = slotOffsets >= 0 & ...
    slotOffsets + samples_per_slot <= numSamples;
slotOffsets = slotOffsets(validSlots);
dlSlots = dlSlots(validSlots);
if isempty(slotOffsets)
    warning('频偏估计: 同步位置之后没有完整的PDSCH时隙，跳过补偿。');
    sig_rx_comp = sig_rx_all;
    freq_offset_hz = 0;
    return;
end

[freq_offset_hz, corr_quality, statistics] = cp_frequency_offset_estimate(...
    sig_rx_all, slotOffsets, fftSize, cpLengths, Fs_val);

slotFrequencyHz = zeros(size(slotOffsets));
slotQuality = zeros(size(slotOffsets));
for slotIndex = 1:numel(slotOffsets)
    [slotFrequencyHz(slotIndex), slotQuality(slotIndex)] = ...
        cp_frequency_offset_estimate(sig_rx_all, slotOffsets(slotIndex), ...
        fftSize, cpLengths, Fs_val);
end

fprintf('PDSCH时隙范围: slot#%d -> slot#%d (%d个时隙)\n', ...
    dlSlots(1), dlSlots(end), numel(dlSlots));
fprintf('  CP联合频偏估计   = %.2f Hz\n', freq_offset_hz);
fprintf('  单符号中位数     = %.2f Hz, 加权标准差=%.2f Hz\n', ...
    statistics.perSymbolMedianHz, statistics.weightedStdHz);
fprintf('  CP相关质量        = %.4f (%d个OFDM符号)\n', ...
    corr_quality, statistics.numSymbols);
fprintf('  最大不模糊范围    = +/-%.1f Hz\n', statistics.unambiguousRangeHz);
fprintf('  逐时隙频偏范围    = [%.2f, %.2f] Hz (中位数=%.2f Hz)\n', ...
    min(slotFrequencyHz), max(slotFrequencyHz), median(slotFrequencyHz));
fprintf('  逐时隙相关质量    = [%.4f, %.4f]\n', min(slotQuality), max(slotQuality));

if corr_quality < 0.2
    warning('频偏估计: CP相关质量过低(%.3f)，为避免错误补偿，本次按0 Hz处理。', ...
        corr_quality);
    freq_offset_hz = 0;
elseif statistics.weightedStdHz > statistics.unambiguousRangeHz / 3
    warning('频偏估计: 单符号结果离散度较大(%.1f Hz)，补偿结果可能不稳定。', ...
        statistics.weightedStdHz);
end

sig_rx_comp = sig_rx_all;
slotTime = (0:samples_per_slot-1) / Fs_val;
for slotIndex = 1:numel(slotOffsets)
    localFrequencyHz = slotFrequencyHz(slotIndex);
    if slotQuality(slotIndex) < 0.2
        localFrequencyHz = freq_offset_hz;
    end
    sampleRange = slotOffsets(slotIndex) + (1:samples_per_slot);
    sig_rx_comp(:, sampleRange) = sig_rx_all(:, sampleRange) .* ...
        exp(-1j * 2*pi*localFrequencyHz*slotTime);
end

fprintf('  已对%d个PDSCH时隙施加局部频偏补偿 (时隙边界相位重置)\n', ...
    numel(slotOffsets));
fprintf('========================================\n');
end
