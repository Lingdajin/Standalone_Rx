function [des_bits, tb_crc_ok, cb_crc_ok, cfg, decoded_cb_bits] = ...
    ldpc_llr_to_bits(llr_input, cfg, stream_idx, C_cut, LDPC_decoder_cpp_alter)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ldpc_llr_to_bits - LDPC decoder: soft-demodulation LLR to decoded bits
%%
%% This function descrambles, deinterleaves, rate-recovers, and LDPC-decodes
%% one transport stream. C_cut optionally limits decoding to leading CBs.
%%
%% Inputs:
%%   llr_input  - soft-demodulation LLR sequence for one stream
%%   cfg        - decoder configuration from ldpc_decoder_config()
%%   stream_idx - optional 1-based stream index; default is 1
%%   C_cut      - optional CB count; 0 (default) decodes every CB
%%   LDPC_decoder_cpp_alter - optional; false (default) uses MATLAB decoder
%%
%% Outputs:
%%   des_bits   - full TB payload vector; undecoded positions contain -1
%%   tb_crc_ok  - TB CRC result, or [] when only part of the TB was decoded
%%   cb_crc_ok  - CRC24B result for each decoded CB of a segmented TB
%%   decoded_cb_bits - one row per CB; undecoded CB rows contain -1
%%
%% Dependencies:
%%   ldpc_descramble.m, ldpc_deinterleave.m, expand_Hd_base.m, LDPC_decoder.m
%%   crc24a_check.m, crc24b_check.m
%% Parameter validation
if nargin < 3
    stream_idx = 1;
end
if nargin < 4
    C_cut = 0;
end
if stream_idx < 1 || stream_idx > cfg.Ns || stream_idx ~= fix(stream_idx)
    error('ldpc_llr_to_bits:InvalidStream', ...
        'stream_idx=%d is outside [1, %d].', stream_idx, cfg.Ns);
end
if ~islogical(LDPC_decoder_cpp_alter) || ~isscalar(LDPC_decoder_cpp_alter)
    error('ldpc_llr_to_bits:InvalidDecoderSelection', ...
        'LDPC_decoder_cpp_alter must be a logical scalar.');
end
%% CB selection
% C_cut = 0 decodes the complete transport block; otherwise decode its
% leading C_cut code blocks only.
total_C = cfg.C_save(stream_idx);
if ~isnumeric(C_cut) || ~isscalar(C_cut) || ~isreal(C_cut) || ...
        ~isfinite(C_cut) || C_cut ~= floor(C_cut)
    error('ldpc_llr_to_bits:InvalidCcut', ...
        'C_cut必须是非负整数;设置为0代表译码所有CB块.');
end
if C_cut == 0
    C = total_C;
elseif C_cut < 1 || C_cut > total_C
    error('ldpc_llr_to_bits:CcutOutOfRange', ...
        'C_cut=%d 超出范围 [1, %d];设置为0代表译码所有CB块.', C_cut, total_C);
else
    C = C_cut;
end
F      = cfg.F_save(stream_idx);
RNTI   = cfg.RNTI(stream_idx);
nID    = cfg.nID(stream_idx);
q      = cfg.q(stream_idx);

% 定位本流在 len_Er_save / rm_pos 中的起止位置
offset = cfg.stream_offset(stream_idx);
E_vec  = cfg.len_Er_save(offset+1 : offset+C);
all_E_vec = cfg.len_Er_save(offset+1 : offset+total_C);
CBS    = cfg.len_CB_save(stream_idx);

llr_input = reshape(llr_input, 1, []);
if numel(llr_input) ~= sum(all_E_vec)
    error('ldpc_llr_to_bits:InvalidLLRLength', ...
        'Stream %d needs %d LLR values, but received %d.', ...
        stream_idx, sum(all_E_vec), numel(llr_input));
end

SimParam            = cfg.SimParam_list{stream_idx};
LLRbuffer           = cfg.LLRbuffer_list{stream_idx};
to_decode_softvalue = cfg.to_decode_softvalue_list{stream_idx};
rm_pos_all          = cfg.rm_pos_list{stream_idx};
harqCount           = cfg.harq_trans_idx(stream_idx);
if harqCount < 1 || harqCount > cfg.HARQMaxTrans || harqCount ~= fix(harqCount)
    error('ldpc_llr_to_bits:InvalidHARQIndex', ...
        'HARQ index %d is outside [1, %d].', harqCount, cfg.HARQMaxTrans);
end

%% ======================= Step 1: 解扰 =======================
descramed_softvalue = ldpc_descramble(llr_input, RNTI, nID, q);

%% ======================= Step 2: CB分割 + 解交织 =======================
ModuOrder = cfg.modulation_mode(stream_idx);
end_pos = 0;
for r = 1:C
    start_pos = 1 + end_pos;
    end_pos   = sum(E_vec(1:r));
    softvalue_C = descramed_softvalue(start_pos:end_pos);
    softvalue_deinter = ldpc_deinterleave(softvalue_C, ModuOrder);
    LLRbuffer{r, harqCount} = softvalue_deinter;
end

%% ======================= Step 3: 速率恢复 + LDPC译码 =======================
decoded_cb_bits = -ones(total_C, CBS);
if total_C > 1
    cb_crc_ok = false(1, C);
    decoded_payload_length = CBS - 24;
else
    cb_crc_ok = [];
    decoded_payload_length = CBS;
end
decoded_bits = zeros(1, C * decoded_payload_length);
z         = SimParam.liftZ;
l_padding = SimParam.l_padding;
K_cb      = CBS - 2*z;
iter      = SimParam.iterationNumLDPC;
Hd_base   = SimParam.Hd_base;
[row_base, col_base] = size(Hd_base);
row_H = row_base * z;
col_H = col_base * z;

for r = 1:C
    % --- 3a. 获取当前CB的LLR ---
    LLRbuffer_now = cell2mat(LLRbuffer(r, harqCount));

    % --- 3b. 速率恢复: 将LLR填入正确位置 ---
    st_p = sum(E_vec(1:r-1)) + 1;
    ed_p = sum(E_vec(1:r));
    rm_pos_thisCB = rm_pos_all(st_p:ed_p);
    contribution = accumarray(rm_pos_thisCB(:), LLRbuffer_now(:), ...
        [size(to_decode_softvalue, 2), 1], @sum, 0).';
    to_decode_softvalue(r, :) = to_decode_softvalue(r, :) + contribution;

    % --- 3c. 填充位赋极大值 + 前置2z个零 ---
    recovered_cb = to_decode_softvalue(r, :);
    recovered_cb(K_cb+1 : K_cb+l_padding) = ...
        max(1, 10 * max(abs(to_decode_softvalue(r, :)))) * ones(1, l_padding);
    to_decode_softvalue_final = zeros(1, 2*z + numel(recovered_cb));
    to_decode_softvalue_final(2*z+1:end) = recovered_cb;

    % --- 3d. LDPC译码(选择纯MATLAB sum-product译码器 或 C++ BP译码器) ---
    if LDPC_decoder_cpp_alter  %C++版本译码器
        LLR_combine_tmp = zeros(1, col_H);
        copy_len = min(length(to_decode_softvalue_final), col_H);
        LLR_combine_tmp(1:copy_len) = to_decode_softvalue_final(1:copy_len);
        CBbits_dec = decoder_opt(LLR_combine_tmp, row_H, col_H, iter, ...
                                Hd_base, z, row_base, col_base);
    else                                %纯MATLAB sum-product译码器
        LLR_combine_tmp = zeros(1, col_H);
        copy_len = min(length(to_decode_softvalue_final), col_H);
        LLR_combine_tmp(1:copy_len) = to_decode_softvalue_final(1:copy_len);
        % 将基矩阵扩展为完整校验矩阵 (首次循环时计算, 后续复用)
        if ~exist('Hd_full', 'var')
            Hd_full = expand_Hd_base(Hd_base, z);
        end
        CBbits_dec = LDPC_decoder(LLR_combine_tmp, Hd_full, CBS, iter);
    end

    decoded_cb_bits(r, :) = CBbits_dec(1:CBS);

    % --- 3e. 提取信息位 (去掉CB-CRC填充) ---
    output_range = (r-1) * decoded_payload_length + (1:decoded_payload_length);
    if total_C == 1
        decoded_bits(output_range) = CBbits_dec(1:CBS);
    else
        cb_crc_ok(r) = crc24b_check(CBbits_dec(1:CBS));
        decoded_bits(output_range) = CBbits_dec(1:CBS-24);
    end
end

%% ======================= Step 4: 更新HARQ状态 =======================
cfg.LLRbuffer_list{stream_idx}           = LLRbuffer;
cfg.to_decode_softvalue_list{stream_idx} = to_decode_softvalue;

%% ======================= Step 5: TB CRC =======================
% A TB CRC is meaningful only when every CB in the TB has been decoded.
tb_crc_ok = [];
if total_C == 1
    output_length = CBS - F;
else
    output_length = total_C * (CBS - 24) - F;
end
des_bits = -ones(1, output_length);
copy_length = min(numel(decoded_bits), output_length);
des_bits(1:copy_length) = decoded_bits(1:copy_length);

if C == total_C
    if nargout >= 2
        tb_crc_ok = ~isempty(des_bits) && ...
            crc24a_check(des_bits, cfg.crc_len(stream_idx));
    end
end
% 若整体TB CRC通过，则所有CB的CRC24B也视为通过
if isequal(tb_crc_ok, true)
    cb_crc_ok = true(1, C);
end

end
