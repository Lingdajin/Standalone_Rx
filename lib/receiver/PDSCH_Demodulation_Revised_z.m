function [ Statistics, NumOfErrorBit_s ] = PDSCH_Demodulation_Revised_z( Data_after_Equ,SNR_after_Equ,Statistics,TransIndex,current_index )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 程序名称：PUSCH_Demodulation_Revised
% 描    述：
% (1) PUSCH Demodulation
% 修改记录：
% Created by 下行与上行 2012.5
% Revised by 下行与上行 2012.7
%   detail:   adjust function to be more efficient, 
%               by means of running newsoft demodulation only once
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global SystemParam
global DataStruct
global LDPCCodingRateMatchingParam
global HARQParam
global save_interval

Ns          = SystemParam.Ns;
NL          = SystemParam.NL;

for loop_Ns = 1:Ns
    if SystemParam.RML_Flag == 0
        layer_num = size(Data_after_Equ,1);
        if layer_num == Ns
            Data_for_Demod = reshape(Data_after_Equ(loop_Ns,:),1,[]);
            SNR_Mod = reshape(SNR_after_Equ(loop_Ns,:),1,[]);
        else
            Data_for_Demod = reshape(Data_after_Equ((loop_Ns-1)*NL(1)+1:(loop_Ns-1)*NL(1)+NL(loop_Ns),:),1,[]);
            SNR_Mod = reshape(SNR_after_Equ((loop_Ns-1)*NL(1)+1:(loop_Ns-1)*NL(1)+NL(loop_Ns),:),1,[]);
        end

        %% Demodulation, decoding and combining
            modulation_mode      = LDPCCodingRateMatchingParam.modulation_mode;
            src_len              = LDPCCodingRateMatchingParam.src_len;
            Data_for_code        = LDPCCodingRateMatchingParam.Data_for_code;  % 源bit信息
            DataStruct.mod_order(current_index,1:length(modulation_mode)) = modulation_mode;
            [ des_bits ] = PDSCH_Symbols2Bits_ldpc(Data_for_Demod,SNR_Mod,modulation_mode,TransIndex,src_len,current_index);
    else
        %R-ML输出的是软信息，对应的单位是比特，reshape时须注意，（MMSE是符号）
        modulation_mode      = LDPCCodingRateMatchingParam.modulation_mode;
        src_len              = LDPCCodingRateMatchingParam.src_len;
        Data_for_code        = LDPCCodingRateMatchingParam.Data_for_code;
        [ des_bits ] = PDSCH_Symbols2Bits_ldpc_rml(Data_after_Equ,modulation_mode,TransIndex,src_len);
    end

    % 保存解调出的源比特信息
    %DataStruct.data_decoded(current_index, 1:src_len) = des_bits(1:src_len);
    % 累积所有码字的解码比特，供EVM重编码使用
    LDPCCodingRateMatchingParam.des_bits_all = [LDPCCodingRateMatchingParam.des_bits_all, des_bits(1:src_len(loop_Ns))];

    % Calculation of Symbol Error Rate %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 若原始比特不可用 (Data_for_code为空), 使用CRC校验: CRC失败→全错, CRC通过→全对
    use_crc_only = isempty(Data_for_code);
    if use_crc_only
        crc_ok = ~isempty(des_bits) && crc24a_check(des_bits, LDPCCodingRateMatchingParam.crc_len);
        if crc_ok
            Statistics.NumOfErrorBit_s(loop_Ns) = 0;
            Statistics.ratio_s(loop_Ns) = 0;
        else
            Statistics.NumOfErrorBit_s(loop_Ns) = src_len(loop_Ns);
            Statistics.ratio_s(loop_Ns) = 1;
        end
    end
    if loop_Ns == 1
        if ~use_crc_only
            [Statistics.NumOfErrorBit_s(loop_Ns), Statistics.ratio_s(loop_Ns)] = symerr(des_bits(1:src_len(loop_Ns)),Data_for_code(1:src_len(loop_Ns)));
        end
        if TransIndex == HARQParam.MaxTranx && Statistics.ratio_s(loop_Ns)>0
            Statistics.BER_arr_Num(loop_Ns) = Statistics.NumOfErrorBit_s(loop_Ns) + Statistics.BER_arr_Num(loop_Ns);
            Statistics.BER_arr_naw(loop_Ns)=Statistics.BER_arr_naw(loop_Ns)+Statistics.ratio_s(loop_Ns);
        end
    else
        if ~use_crc_only
            [Statistics.NumOfErrorBit_s(loop_Ns), Statistics.ratio_s(loop_Ns)] = symerr(des_bits(1:src_len(loop_Ns)),Data_for_code(src_len(1)+24+1:src_len(1)+24+src_len(2)));
        end
        Statistics.BER_arr_Num(loop_Ns) = Statistics.NumOfErrorBit_s(loop_Ns) + Statistics.BER_arr_Num(loop_Ns);
        Statistics.BER_arr_naw(loop_Ns)=Statistics.BER_arr_naw(loop_Ns)+Statistics.ratio_s(loop_Ns);
    end
end
NumOfErrorBit_s = Statistics.NumOfErrorBit_s;
%%
end

%% ====== CRC24A 校验 (调用 crc_calc_212) ======
function ok = crc24a_check(bits, crc_len)
% 对解码比特做 CRC24A 校验
% bits: [data_bits(1:end-crc_len), crc_attach(end-crc_len+1:end)]
if length(bits) < crc_len + 1, ok = false; return; end
data_bits = bits(1:end-crc_len);
crc_rcvd  = bits(end-crc_len+1:end);
crc_calc  = crc_calc_212(data_bits, 'CRC24A');
ok = isequal(crc_rcvd(:), crc_calc(:));
end