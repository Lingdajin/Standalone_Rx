function [Statistics, NumOfErrorBit_s] = PDSCH_Demodulation_Revised_z( ...
    Data_after_Equ, SNR_after_Equ, Statistics, TransIndex, current_index)
%PDSCH_DEMODULATION_REVISED_Z Standalone demodulation with synchronized LDPC.

global SystemParam LDPCCodingRateMatchingParam HARQParam DataStruct

Ns = SystemParam.Ns;
NL = SystemParam.NL;
modulation_mode = LDPCCodingRateMatchingParam.modulation_mode;
src_len = LDPCCodingRateMatchingParam.src_len;
reference_bits = LDPCCodingRateMatchingParam.Data_for_code;

for stream_idx = 1:Ns
    if SystemParam.RML_Flag ~= 0
        error('PDSCH_Demodulation_Revised_z:RMLUnsupported', ...
            'The synchronized standalone LDPC path does not support RML input.');
    end

    layer_count = size(Data_after_Equ, 1);
    if layer_count == Ns
        layer_indices = stream_idx;
    else
        layer_start = sum(NL(1:stream_idx-1)) + 1;
        layer_indices = layer_start:layer_start + NL(stream_idx) - 1;
    end
    symbols = reshape(Data_after_Equ(layer_indices, :), 1, []);
    symbol_snr = reshape(SNR_after_Equ(layer_indices, :), 1, []);
    DataStruct.mod_order(current_index, 1:numel(modulation_mode)) = modulation_mode;

    des_bits = PDSCH_Symbols2Bits_ldpc(symbols, symbol_snr, ...
        modulation_mode(stream_idx), TransIndex(stream_idx), ...
        src_len(stream_idx), current_index);
    LDPCCodingRateMatchingParam.des_bits_all = ...
        [LDPCCodingRateMatchingParam.des_bits_all, ...
        des_bits(1:src_len(stream_idx))]; %#ok<AGROW>

    if LDPCCodingRateMatchingParam.partial_cb_decode
        Statistics.NumOfErrorBit_s(stream_idx) = NaN;
        Statistics.ratio_s(stream_idx) = NaN;
    else
        if isempty(reference_bits)
            tb_crc_ok = LDPCCodingRateMatchingParam.last_tb_crc_ok;
            Statistics.NumOfErrorBit_s(stream_idx) = ...
                (~tb_crc_ok) * src_len(stream_idx);
            Statistics.ratio_s(stream_idx) = ~tb_crc_ok;
        else
            if stream_idx == 1
                reference_start = 1;
            else
                reference_start = sum(src_len(1:stream_idx-1)) + ...
                    24 * (stream_idx - 1) + 1;
            end
            reference_range = reference_start:reference_start + src_len(stream_idx) - 1;
            [Statistics.NumOfErrorBit_s(stream_idx), ...
                Statistics.ratio_s(stream_idx)] = symerr( ...
                des_bits(1:src_len(stream_idx)), reference_bits(reference_range));
        end

        if stream_idx == 1
            if TransIndex(stream_idx) == HARQParam.MaxTranx && ...
                    Statistics.ratio_s(stream_idx) > 0
                Statistics.BER_arr_Num(stream_idx) = ...
                    Statistics.BER_arr_Num(stream_idx) + ...
                    Statistics.NumOfErrorBit_s(stream_idx);
                Statistics.BER_arr_naw(stream_idx) = ...
                    Statistics.BER_arr_naw(stream_idx) + ...
                    Statistics.ratio_s(stream_idx);
            end
        else
            Statistics.BER_arr_Num(stream_idx) = ...
                Statistics.BER_arr_Num(stream_idx) + ...
                Statistics.NumOfErrorBit_s(stream_idx);
            Statistics.BER_arr_naw(stream_idx) = ...
                Statistics.BER_arr_naw(stream_idx) + ...
                Statistics.ratio_s(stream_idx);
        end
    end
end

NumOfErrorBit_s = Statistics.NumOfErrorBit_s;
end
