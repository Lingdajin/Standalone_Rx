%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PDSCH_Receiver_Standalone.m  — 独立接收机
%
% 读取VSA采集的.mat文件, 按帧/时隙解调PDSCH, 输出性能统计
%
% 用法:  1.编辑 PDSCH_Receiver_Standalone_Config.m   2.运行本脚本
% 架构:  外层帧循环 → 内层时隙循环 → DL_Slot_Mask判断 → PDSCH_Receiver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear classes; clear; clc;
project_root = fileparts(mfilename('fullpath'));
addpath(project_root);
Sim_Add_Path_Minimal; rng(5); warning off;

%% ==================== 加载配置 ====================
fprintf('===== PDSCH 独立接收机 =====\n');
cfg_dir = project_root;
run(fullfile(cfg_dir, 'PDSCH_Receiver_Standalone_Config'));

if ~isnumeric(C_cut) || ~isscalar(C_cut) || ~isfinite(C_cut) || ...
        C_cut < 0 || C_cut ~= floor(C_cut)
    error('C_cut必须是非负整数；设置为0代表译码全部CB。');
end

if ~isfile(VSA_File)
    error(['找不到VSA输入文件: %s\n' ...
        '请把采集文件放入 input 目录、修改配置文件，或设置环境变量 PDSCH_VSA_FILE。'], ...
        VSA_File);
end

fprintf('VSA: %s  BW=%dM RB=%d miu=%d DMRSport=%d MCS=%d\n', ...
    VSA_File, round(BW/1e6), NumOfRB, miu, DMRS_port, MCS);

%% ==================== 加载VSA信号与元数据 ====================
fprintf('加载VSA信号数据...\n');
[sig_rx_all, Fs_val, centerFreq, Nr_file] = load_standalone_vsa(VSA_File);
if Nr ~= Nr_file
    fprintf('接收天线数: 配置 Nr=%d → 文件 Y 列数 Nr=%d\n', Nr, Nr_file);
end
Nr = Nr_file;
% FreqOffset_Hz 从VSA文件自动读取 (覆盖配置文件中的值)
CarrierFrequency_Hz = centerFreq;
FreqOffset_Hz = 0;   % 载波频偏补偿
fprintf('VSA centerFreq=%.3fGHz  FreqOffset=%.1fHz\n', centerFreq/1e9, FreqOffset_Hz);
fprintf('Fs=%.2fMHz 天线=%d 长=%d样点(%.2fms)\n', ...
    Fs_val/1e6, Nr, size(sig_rx_all, 2), size(sig_rx_all, 2)/Fs_val*1e3);

%% ==================== 初始化全局 ====================
run(fullfile(cfg_dir, 'PDSCH_Init_Standalone'));

%% ==================== 采样率检测与重采样 ====================
% 接收机设计采样率: FFT_size * SCS = FFT_size * 15e3 * 2^miu
% VSA 实际采样率可能与此不一致, 需要重采样到期望采样率
global SystemParam
Fs_expected = SystemParam.SampleFreq;   % FFT_size * 15e3 * 2^miu
if abs(Fs_val - Fs_expected) / Fs_expected > 1e-6
    fprintf('? VSA采样率(%.4f MHz)与接收机期望采样率(%.4f MHz)不一致，执行重采样...\n', ...
        Fs_val/1e6, Fs_expected/1e6);

    % 使用有理逼近计算重采样因子 P/Q ≈ Fs_expected / Fs_val
    tol = min(1e-6, abs(Fs_expected - Fs_val) / Fs_val / 10);
    [P, Q] = rat(Fs_expected / Fs_val, tol);
    fprintf('  有理逼近因子: %d / %d (ratio=%.9f)\n', P, Q, P/Q);

    sig_len_old = size(sig_rx_all, 2);
    sig_len_new = round(sig_len_old * Fs_expected / Fs_val);
    sig_rx_resampled = zeros(Nr, sig_len_new);
    for ant = 1:Nr
        sig_rx_resampled(ant, :) = resample(sig_rx_all(ant, :), P, Q);
    end
    sig_rx_all = sig_rx_resampled;
    Fs_val     = Fs_expected;
    clear sig_rx_resampled;

    fprintf('  重采样完成: %d → %d 样点 (新采样率 %.4f MHz)\n', ...
        sig_len_old, sig_len_new, Fs_val/1e6);
else
    fprintf('? VSA采样率(%.4f MHz)与接收机期望采样率一致，无需重采样。\n', Fs_val/1e6);
end

%% ==================== 时隙参数 ====================
cp_vec = SystemParam.LengthOfGI_vec;
FFT_size = SystemParam.FFT_size; Nd = SystemParam.Nd;
samples_per_slot  = FFT_size * Nd + sum(cp_vec);
samples_per_frame = samples_per_slot * N_slots_frame;
fprintf('时隙=%d样点 帧=%d时隙\n', samples_per_slot, N_slots_frame);

%% ==================== 帧同步 (DMRS频域相关) ====================
[frame_start_offsets, NumFrames] = PDSCH_FrameSync(sig_rx_all, Fs_val, ...
    samples_per_slot, samples_per_frame, NumFrames, ...
    DL_Slot_Mask, SystemParam, ...
    TM, CFI, CPType, NumOfAddDMRS, DMRS_port, DMRSLength, DMRS_Type, ...
    DMRS_ScramblingID0, DMRS_ScramblingID1, DMRS_nSCID, dmrs_TypeA_Position, Nr);

%% ==================== 频偏估计与补偿 (DMRS) ====================
[sig_rx_all, freq_offset_hz] = PDSCH_FreqOffsetComp(sig_rx_all, Fs_val, ...
    frame_start_offsets, samples_per_slot, samples_per_frame, ...
    DL_Slot_Mask, SystemParam, ...
    TM, CFI, CPType, NumOfAddDMRS, DMRS_port, DMRSLength, DMRS_Type, ...
    DMRS_ScramblingID0, DMRS_ScramblingID1, DMRS_nSCID, dmrs_TypeA_Position, Nr);

% % 更新 SystemParam 中的频偏值 (供后续OFDM解调相位补偿使用)
% SystemParam.FreqOffset_Hz = freq_offset_hz;
% % 重新计算相位补偿向量 (基于实际估计的频偏)
% if abs(freq_offset_hz) > 0
%     cum_before = [0, cumsum(FFT_size + cp_vec(1:end-1))];
%     useful_start = cum_before + cp_vec;
%     Fs_sys = FFT_size * 15e3 * 2^miu;
%     SystemParam.PhaseComp_vec = exp(1j * 2 * pi * freq_offset_hz * useful_start / Fs_sys);
% else
%     SystemParam.PhaseComp_vec = ones(1, Nd);
% end

%% ==================== 统计初始化 ====================
global SNRLoopStatistic AI_SNRLoopStatistic HARQParam MatrixForCE
SNRLoopStatistic     = SNRLoop_Init_Standalone(Ns_max);
AI_SNRLoopStatistic  = SNRLoopStatistic;
sigma_est = sqrt(10^(-SNR_dB_est/10));
SNR_line  = 10^(SNR_dB_est/10);
MatrixForCE = MatrixForCE_Gen(1);

HARQParam.TransIndex = 1; HARQParam.ACK = 0;
HARQParam.MaxTranx = 1; HARQParam.rv_idx_seq = 0;
HARQParam.ACK_adjust = 0; HARQParam.Adjust_dB = 0;

DecodedResults = struct('frame_index', {}, 'frame_start_offset', {}, ...
    'slot_index', {}, ...
    'total_cb_count', {}, 'decoded_cb_count', {}, 'decoded_cb_mask', {}, ...
    'tb_crc_ok', {}, 'cb_crc_ok', {}, 'decoded_bits', {}, ...
    'decoded_cb_bits', {});
partial_decode_used = false;

%% ==================== 帧/时隙循环 ====================
snr_N = 1;  % 仅一个SNR点
for frame_idx = 1:NumFrames
    f0 = frame_start_offsets(frame_idx) + 1;
    for slot_idx = 1:N_slots_frame
        if ~DL_Slot_Mask(slot_idx), continue; end
        n_s_f = slot_idx - 1; SystemParam.n_s_f = n_s_f;
        SystemParam.PhaseComp_vec = nr_symbol_phase_compensation( ...
            SystemParam.CarrierFrequency_Hz, SystemParam.SampleFreq, ...
            FFT_size, cp_vec, n_s_f);

        % 提取时隙
        s0 = f0 + (slot_idx-1) * samples_per_slot;
        Data_Rx = sig_rx_all(:, s0 : s0 + samples_per_slot - 1);

        % 每时隙重新生成DMRS
        global PilotParam DataPilotIndexParam LDPCCodingRateMatchingParam
        PilotParam = PDSCH_PilotParamInit(TM, CFI, ...
            SystemParam.Nc_used_CRS, SystemParam.Nc_used_DMRS, SystemParam.Nc_used_CSIRS, SystemParam.Nc_used, ...
            FFT_size, SystemParam.Nc, 0, CPType, NumOfAddDMRS, ...
            Nd, Nd-CFI, DMRS_port, DMRSLength, DMRS_Type, ...
            DMRS_ScramblingID0, DMRS_ScramblingID1, DMRS_nSCID, ...
            dmrs_TypeA_Position, n_s_f);
        PilotParam.CSIRS_COLUMN_INDEX = []; PilotParam.CSIRS_position = [];

        DataPilotIndexParam = PDSCH_DataPilotIndexParamInit(...
            CFI, FFT_size, Nd, SystemParam.Nc_Index, ...
            0, DMRS_port, 0, ...
            PilotParam.CRS_position, PilotParam.DMRS_position, ...
            PilotParam.CSIRS_position, PilotParam.CRS_COLUMN_INDEX, ...
            PilotParam.DMRS_COLUMN_INDEX, PilotParam.CSIRS_COLUMN_INDEX);

        
        DMRS_Idx = DataPilotIndexParam.DMRS_Index;
        [src_len, mod_mode, Rc] = TBS_calculation_f30(...
            MCS_TABLE_PDSCH, NumOfRB, DMRS_port, MCS, ...
            numel(DMRS_Idx)/NumOfRB, Nd-CFI, 0);
        G = length(DataPilotIndexParam.Data_Index_DataRegion) * mod_mode .* DMRS_port;
        LDPCCodingRateMatchingParam.src_len = src_len;
        LDPCCodingRateMatchingParam.modulation_mode = mod_mode;
        LDPCCodingRateMatchingParam.G = G;
        LDPCCodingRateMatchingParam.Rc = src_len / G;

        % 计算码块分割参数 (C_save等, 解码必需)
        dummy_bits = zeros(1, src_len(1));
        [C_val, CBS_val, F_val, ~] = LDPC_TBseg(dummy_bits, src_len(1), Rc);
        if C_cut > C_val
            error('配置的C_cut=%d超过当前TB的总CB数%d。', C_cut, C_val);
        end
        if C_cut == 0
            decoded_cb_count = C_val;
        else
            decoded_cb_count = C_cut;
        end
        LDPCCodingRateMatchingParam.C_cut = C_cut;
        LDPCCodingRateMatchingParam.partial_cb_decode = decoded_cb_count < C_val;
        partial_decode_used = partial_decode_used || ...
            LDPCCodingRateMatchingParam.partial_cb_decode;
        E_vec = Erdetermination(DMRS_port, mod_mode(1), G(1), C_val);
        LDPCCodingRateMatchingParam.C_save = C_val;
        LDPCCodingRateMatchingParam.F_save = F_val;
        LDPCCodingRateMatchingParam.len_CB_save = CBS_val * ones(1, C_val);
        LDPCCodingRateMatchingParam.len_Er_save = E_vec;

        % 计算LDPC译码参数 (SimParam, rm_pos等)
        N_val = round(src_len(1) / Rc);
        if mod(N_val, mod_mode(1)) > 0
            N_val = N_val + mod_mode(1) - mod(N_val, mod_mode(1));
        end
        Nc = N_val / C_val;
        [Hd_base, z, SimParam_val] = genHd_base(CBS_val, Nc, Rc);
        SimParam_val.Hd_base = Hd_base;
        SimParam_val.liftZ = z;
        LDPCCodingRateMatchingParam.SimParam_1 = SimParam_val;

        % 用LDPC_ratematch获取正确rm_pos (自动跳过滤波NULL比特)
        CBcoded_len = SimParam_val.momcodeLength - 2*z;
        rm_pos_all = [];
        for r = 1:C_val
            Er = E_vec(r);
            [~, rm_pos_tmp] = LDPC_ratematch(CBS_val, zeros(1, CBcoded_len), ...
                SimParam_val.BGtype, z, 1, Er, 0, SimParam_val.l_padding);
            rm_pos_all = [rm_pos_all, rm_pos_tmp];
        end
        LDPCCodingRateMatchingParam.rm_pos_1 = rm_pos_all;
        LDPCCodingRateMatchingParam.to_decode_softvalue_1 = zeros(C_val, CBcoded_len);

        % % 诊断: 打印DMRS配置及LDPC参数
        % if frame_idx == 1 && slot_idx == 1
        %     fprintf('[诊断] n_s_f=%d, ScramblingID0=%d, nSCID=%d, DMRS_port=%d\n', ...
        %         n_s_f, DMRS_ScramblingID0, DMRS_nSCID, DMRS_port);
        %     fprintf('[诊断] DMRS_COLUMN_INDEX(1,:) = [%s]\n', num2str(PilotParam.DMRS_COLUMN_INDEX(1,:)));
        %     fprintf('[诊断] src_len=%d mod=%d Rc=%.4f G=%d C=%d CBS=%d z=%d\n', ...
        %         src_len(1), 2^mod_mode(1), Rc, G(1), C_val, CBS_val, z);
        %     fprintf('[诊断] Data_Index=%d  DataRegion=%d  DMRS_Index=%d\n', ...
        %         length(DataPilotIndexParam.Data_Index), ...
        %         length(DataPilotIndexParam.Data_Index_DataRegion), ...
        %         length(DataPilotIndexParam.DMRS_Index));
        % end

        % 调用现有接收机
        [~, ~, SNRLoopStatistic, AI_SNRLoopStatistic] = ...
            PDSCH_Receiver(Data_Rx, MatrixForCE, [], 0, eye(DMRS_port), ...
            SNR_line, SNRLoopStatistic, AI_SNRLoopStatistic, sigma_est, ...
            slot_idx, SNR_dB_est, snr_N, 0);

        result_index = numel(DecodedResults) + 1;
        DecodedResults(result_index).frame_index = frame_idx;
        DecodedResults(result_index).frame_start_offset = ...
            frame_start_offsets(frame_idx);
        DecodedResults(result_index).slot_index = slot_idx;
        DecodedResults(result_index).total_cb_count = C_val;
        DecodedResults(result_index).decoded_cb_count = decoded_cb_count;
        DecodedResults(result_index).decoded_cb_mask = ...
            [true(1, decoded_cb_count), false(1, C_val-decoded_cb_count)];
        if isempty(LDPCCodingRateMatchingParam.last_tb_crc_ok)
            DecodedResults(result_index).tb_crc_ok = NaN;
        else
            DecodedResults(result_index).tb_crc_ok = ...
                LDPCCodingRateMatchingParam.last_tb_crc_ok;
        end
        DecodedResults(result_index).cb_crc_ok = ...
            LDPCCodingRateMatchingParam.last_cb_crc_ok;
        DecodedResults(result_index).decoded_bits = ...
            LDPCCodingRateMatchingParam.des_bits_all;
        DecodedResults(result_index).decoded_cb_bits = ...
            LDPCCodingRateMatchingParam.last_decoded_cb_bits;

        % ==== 均衡后星座图可视化 ====
        if PlotConstellation
            global Debug_Data_after_Equ Debug_SNR_after_Equ
            deq = Debug_Data_after_Equ;
            if ~isempty(deq)
                Nplot = min(2000, numel(deq));
                syms = deq(1:Nplot);
                
                figure(100); clf;
                plot(real(syms(:)), imag(syms(:)), 'b.', 'MarkerSize', 4);
                grid on; axis equal; hold on;
                xlabel('In-Phase'); ylabel('Quadrature');
                
                % 根据调制阶数绘制理想星座参考点
                Qm = 2^mod_mode(1);  % 调制阶数: 4=QPSK,16=16QAM,64=64QAM,256=256QAM
                switch Qm
                    case 4  % QPSK
                        ref = [1+1j, 1-1j, -1+1j, -1-1j] / sqrt(2);
                    case 16  % 16QAM
                        D = 1/sqrt(10);
                        ref_vals = [-3, -1, 1, 3] * D;
                        [X, Y] = meshgrid(ref_vals, ref_vals);
                        ref = X(:) + 1j*Y(:);
                    case 64  % 64QAM
                        D = 1/sqrt(42);
                        ref_vals = [-7, -5, -3, -1, 1, 3, 5, 7] * D;
                        [X, Y] = meshgrid(ref_vals, ref_vals);
                        ref = X(:) + 1j*Y(:);
                    case 256  % 256QAM
                        D = 1/sqrt(170);
                        ref_vals = [-15,-13,-11,-9,-7,-5,-3,-1,1,3,5,7,9,11,13,15] * D;
                        [X, Y] = meshgrid(ref_vals, ref_vals);
                        ref = X(:) + 1j*Y(:);
                    otherwise
                        ref = [];
                end
                if ~isempty(ref)
                    plot(real(ref), imag(ref), 'rx', 'MarkerSize', 8, 'LineWidth', 1.5);
                    legend('Rx Symbols', 'Ideal Ref', 'Location', 'best');
                end
                
                % 标题信息
                snr_mean = mean(Debug_SNR_after_Equ(:), 'omitnan');
                title(sprintf(['Constellation (Post-EQ) — Frame %d Slot %d | ' ...
                    'MCS=%d %dQAM | Syms=%d/%d | SNR_{EQ}=%.1fdB'], ...
                    frame_idx, slot_idx, MCS, Qm, Nplot, numel(deq), snr_mean));
                hold off; drawnow;
            end
        end

        % if mod(slot_idx, 5) == 1
        %     bler = sum(SNRLoopStatistic.BLER_e_f) / max(sum(SNRLoopStatistic.BLER_t_f), 1);
        %     fprintf('F%d S%d n_s_f=%d BLER_t=%.0f BLER_e=%.0f BLER=%.3f\n', ...
        %         frame_idx, slot_idx, n_s_f, sum(SNRLoopStatistic.BLER_t_f), ...
        %         sum(SNRLoopStatistic.BLER_e_f), bler);
        % end
    end
end

%% ==================== 输出 ====================
DMRS_EVM = SNRLoopStatistic.DMRS_EVM_sum / ...
    max(SNRLoopStatistic.DMRS_EVM_count, 1);
fprintf('\n===== 统计结果 =====\n');
if partial_decode_used
    BER = NaN;
    BLER = NaN;
    BLER_t = NaN;
    BLER_e = NaN;
    EVM = NaN;
    Metrics = struct('available', false, ...
        'reason', '仅译码部分CB，BER/BLER/EVM不可用。', ...
        'BER', BER, 'BLER', BLER, 'EVM', EVM, 'DMRS_EVM', DMRS_EVM);
    fprintf('BER:不可用  BLER:不可用  EVM:不可用 (仅译码部分CB)\n');
else
    BLER_t = sum(SNRLoopStatistic.BLER_t_f);
    BLER_e = sum(SNRLoopStatistic.BLER_e_f);
    BER = sum(SNRLoopStatistic.BER_arr_Num) / ...
        max(sum(SNRLoopStatistic.BLER_t_f .* src_len), 1);
    BLER = BLER_e / max(BLER_t, 1);
    EVM = SNRLoopStatistic.EVM_sum / max(SNRLoopStatistic.EVM_count, 1);
    Metrics = struct('available', true, 'reason', '', ...
        'BER', BER, 'BLER', BLER, 'EVM', EVM, 'DMRS_EVM', DMRS_EVM);
    fprintf('PDSCH时隙:%d 误块:%d  BER:%.4e  BLER:%.4f\n', ...
        BLER_t, BLER_e, BER, BLER);
    fprintf('EVM_avg:%.2f%%\n', EVM * 100);
end
fprintf('DMRS_EVM:%.2f%%\n', DMRS_EVM * 100);
result_dir = fileparts(ResultSaveFile);
if ~isfolder(result_dir), mkdir(result_dir); end
save(ResultSaveFile, 'DecodedResults', 'Metrics', 'BER', 'BLER', ...
    'BLER_t', 'BLER_e', 'EVM', 'DMRS_EVM', 'C_cut', ...
    'SNR_dB_est', 'MCS', 'NumOfRB', 'DMRS_port', ...
    'frame_start_offsets', 'NumFrames');
fprintf('结果保存: %s\n', ResultSaveFile);
