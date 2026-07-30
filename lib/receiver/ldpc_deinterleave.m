function deinterleaved = ldpc_deinterleave(received_llr, modulation_order)
%LDPC_DEINTERLEAVE Reverse NR LDPC bit interleaving (TS 38.212 5.4.2.2).

input_length = numel(received_llr);
if modulation_order < 1 || modulation_order ~= fix(modulation_order) || ...
        mod(input_length, modulation_order) ~= 0
    error('ldpc_deinterleave:InvalidDimensions', ...
        'Input length %d is not divisible by modulation order %g.', ...
        input_length, modulation_order);
end

column_count = input_length / modulation_order;
interleaver = reshape(received_llr, modulation_order, column_count);
deinterleaved = reshape(interleaver.', 1, []);
end
