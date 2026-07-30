function [dmrs_evm_str, dmrs_evm_rms] = DMRS_Equalizer_EVM(H_DMRS_Equ, FFT_Out_DMRS, DMRS_port, DMRS_position, DMRS_COLUMN_INDEX, DMRS_Signal, Nr, sigma)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Description:
% (1) DMRS Equalization and EVM Calculation
% (2) 对DMRS导频数据进行联合MMSE均衡并计算EVM
% (3) 端口分组 → 同一comb子载波组内多端口联合均衡 → EVM计算
%% Input Parameters:
% H_DMRS_Equ        : Nr x DMRS_port x N_dmrs_sc x N_dmrs_sym, DMRS位置的信道估计
% FFT_Out_DMRS      : Nr x DMRS_port x N_dmrs_sc x N_dmrs_sym, 接收端DMRS频域数据
% DMRS_port         : DMRS端口总数
% DMRS_position     : DMRS_port x N_dmrs_sc x N_dmrs_sym, DMRS子载波FFT索引
% DMRS_COLUMN_INDEX : DMRS_port x N_dmrs_sym, DMRS所在OFDM符号索引
% DMRS_Signal       : DMRS_port x N_dmrs_sc x N_dmrs_sym, 原始DMRS发送信号
% Nr                : 接收天线数
% sigma             : 噪声标准差
%% Output Parameters:
% dmrs_evm_str      : DMRS EVM格式化字符串 (如 '--DMRS_EVM:12.34%(18.2dB)')
% dmrs_evm_rms      : DMRS EVM RMS数值 (0~1, 无有效数据时返回NaN)
%% Modification records:
% (1) 2026.5.25: 从 PDSCH_Receiver.m 中独立为模块.
% (2) 2026.5.25: 新增 dmrs_evm_rms 数值输出.

dmrs_evm_str = '';  % 初始化DMRS EVM字符串
dmrs_evm_rms = NaN;  % 默认NaN表示无有效数据
if isempty(H_DMRS_Equ)
    return;
end

N_dmrs_sym = size(DMRS_COLUMN_INDEX, 2);
N_dmrs_sc  = size(DMRS_position, 2);

% ---- 端口分组: 将共享同一子载波的端口归入同一comb组 ----
port_groups = {};           % 每组内的端口列表
port_visited = false(DMRS_port, 1);
for nta = 1:DMRS_port
    if port_visited(nta), continue; end
    grp = [nta];
    for nta2 = nta+1:DMRS_port
        if ~port_visited(nta2) && isequaln(DMRS_position(nta,:,:), DMRS_position(nta2,:,:))
            grp = [grp, nta2];
            port_visited(nta2) = true;
        end
    end
    port_visited(nta) = true;
    port_groups{end+1} = grp;
end

DMRS_rx_eq_all = [];   % 收集所有均衡后的DMRS符号
DMRS_tx_orig_all = []; % 收集所有原始DMRS符号

for gi = 1:length(port_groups)
    grp_ports = port_groups{gi};
    N_active = length(grp_ports);
    rep_port = grp_ports(1);  % 代表端口（用于取y_sc）
    
    for np = 1:N_dmrs_sym
        sym_idx = DMRS_COLUMN_INDEX(rep_port, np);
        if isnan(sym_idx), continue; end
        sc_indices_fft = DMRS_position(rep_port, :, np);
        valid_mask = ~isnan(sc_indices_fft);
        
        for isc = 1:N_dmrs_sc
            if ~valid_mask(isc), continue; end
            
            % 构建联合信道矩阵 H_joint: Nr x N_active
            H_joint = zeros(Nr, N_active);
            x_orig_vec = zeros(N_active, 1);
            for ia = 1:N_active
                pt = grp_ports(ia);
                H_joint(:, ia) = squeeze(H_DMRS_Equ(:, pt, isc, np));
                x_orig_vec(ia) = DMRS_Signal(pt, isc, np);
            end
            
            % 接收信号 (同组端口共享同一子载波，y相同)
            y_sc = squeeze(FFT_Out_DMRS(:, rep_port, isc, np));
            
            % 联合MMSE (与 rx_vblast_mmse_vB 算法一致)
            PH = pinv(sigma^2 * eye(N_active) + H_joint' * H_joint);
            G = PH * H_joint';
            x_hat_raw = G * y_sc;   % N_active x 1
            
            % 偏置校正 (B-scaling, 与数据均衡路径一致)
            for ia = 1:N_active
                SNR_i = 1 / sigma^2 / abs(PH(ia,ia)) - 1;
                B = (1 + SNR_i) / SNR_i;
                x_hat_raw(ia) = x_hat_raw(ia) * B;
            end
            
            DMRS_rx_eq_all = [DMRS_rx_eq_all; x_hat_raw];
            DMRS_tx_orig_all = [DMRS_tx_orig_all; x_orig_vec];
        end
    end
end

% DMRS EVM (与数据EVM计算原理一致: RMS(error)/RMS(reference))
if ~isempty(DMRS_tx_orig_all)
    dmrs_evm_rms = sqrt(mean(abs(DMRS_rx_eq_all - DMRS_tx_orig_all).^2)) / sqrt(mean(abs(DMRS_tx_orig_all).^2));
    dmrs_evm_db  = 20 * log10(dmrs_evm_rms);
    dmrs_evm_str = sprintf('--DMRS_EVM:%.2f%%(%.1fdB)', dmrs_evm_rms*100, dmrs_evm_db);
end

end
