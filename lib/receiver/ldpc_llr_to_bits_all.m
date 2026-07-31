function [des_bits_all, crc_results, cfg] = ldpc_llr_to_bits_all(llr_cell, cfg)
%LDPC_LLR_TO_BITS_ALL Decode and concatenate all configured PDSCH codewords.

if ~iscell(llr_cell) || numel(llr_cell) ~= cfg.Ns
    error('ldpc_llr_to_bits_all:InvalidInput', ...
        'llr_cell must contain exactly %d codeword vectors.', cfg.Ns);
end

des_bits_all = [];
crc_results = false(1, cfg.Ns);
for stream_idx = 1:cfg.Ns
    [stream_bits, crc_results(stream_idx), ~, cfg] = ...
        ldpc_llr_to_bits(llr_cell{stream_idx}, cfg, stream_idx);
    des_bits_all = [des_bits_all, stream_bits]; %#ok<AGROW>
end
end
