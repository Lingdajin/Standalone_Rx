function [des_bits, crc_ok, cfg] = ldpc_llr_to_bits(llr_input, cfg, stream_idx)
%LDPC_LLR_TO_BITS Decode one PDSCH codeword from demodulated LLR values.

if nargin < 3
    stream_idx = 1;
end
if stream_idx < 1 || stream_idx > cfg.Ns || stream_idx ~= fix(stream_idx)
    error('ldpc_llr_to_bits:InvalidStream', ...
        'stream_idx=%g is outside the valid range [1, %d].', stream_idx, cfg.Ns);
end

C = cfg.C_save(stream_idx);
F = cfg.F_save(stream_idx);
offset = cfg.stream_offset(stream_idx);
E_vec = cfg.len_Er_save(offset + (1:C));
expected_length = sum(E_vec);
llr_input = reshape(llr_input, 1, []);
if numel(llr_input) ~= expected_length
    error('ldpc_llr_to_bits:InvalidLLRLength', ...
        'Stream %d needs %d LLR values, but received %d.', ...
        stream_idx, expected_length, numel(llr_input));
end

CBS = cfg.len_CB_save(stream_idx);
sim_param = cfg.SimParam_list{stream_idx};
llr_buffer = cfg.LLRbuffer_list{stream_idx};
recovered_llr = cfg.to_decode_softvalue_list{stream_idx};
rm_positions = cfg.rm_pos_list{stream_idx};
harq_index = cfg.harq_trans_idx(stream_idx);
if harq_index < 1 || harq_index > cfg.HARQMaxTrans
    error('ldpc_llr_to_bits:InvalidHARQIndex', ...
        'HARQ index %d is outside the configured range [1, %d].', ...
        harq_index, cfg.HARQMaxTrans);
end

descrambled_llr = ldpc_descramble(llr_input, cfg.RNTI(stream_idx), ...
    cfg.nID(stream_idx), cfg.q(stream_idx));

block_end = 0;
for block_idx = 1:C
    block_start = block_end + 1;
    block_end = block_end + E_vec(block_idx);
    llr_buffer{block_idx, harq_index} = ldpc_deinterleave( ...
        descrambled_llr(block_start:block_end), ...
        cfg.modulation_mode(stream_idx));
end

z = sim_param.liftZ;
padding_length = sim_param.l_padding;
information_end = CBS - 2 * z;
Hd_full = expand_Hd_base(sim_param.Hd_base, z);
codeword_length = size(Hd_full, 2);
if C == 1
    decoded_block_length = CBS;
else
    decoded_block_length = CBS - 24;
end
des_bits = zeros(1, C * decoded_block_length);

position_end = 0;
for block_idx = 1:C
    block_llr = llr_buffer{block_idx, harq_index};
    position_start = position_end + 1;
    position_end = position_end + E_vec(block_idx);
    block_positions = rm_positions(position_start:position_end);

    contribution = accumarray(block_positions(:), block_llr(:), ...
        [size(recovered_llr, 2), 1], @sum, 0).';
    recovered_llr(block_idx, :) = recovered_llr(block_idx, :) + contribution;

    decoder_input = recovered_llr(block_idx, :);
    if padding_length > 0
        filler_reliability = max(1, 10 * max(abs(decoder_input)));
        decoder_input(information_end + (1:padding_length)) = filler_reliability;
    end
    decoder_input = [zeros(1, 2 * z), decoder_input];

    complete_input = zeros(1, codeword_length);
    copy_length = min(numel(decoder_input), codeword_length);
    complete_input(1:copy_length) = decoder_input(1:copy_length);
    decoded_block = LDPC_decoder(complete_input, Hd_full, CBS, ...
        sim_param.iterationNumLDPC);

    output_range = (block_idx - 1) * decoded_block_length + ...
        (1:decoded_block_length);
    des_bits(output_range) = decoded_block(1:decoded_block_length);
end

if F > numel(des_bits)
    error('ldpc_llr_to_bits:InvalidFillerLength', ...
        'Filler length %d exceeds the decoded length %d.', F, numel(des_bits));
end
des_bits = des_bits(1:end-F);

cfg.LLRbuffer_list{stream_idx} = llr_buffer;
cfg.to_decode_softvalue_list{stream_idx} = recovered_llr;
crc_ok = crc24a_check(des_bits, cfg.crc_len(stream_idx));
end
