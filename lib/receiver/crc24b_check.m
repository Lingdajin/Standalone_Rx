function ok = crc24b_check(bits)
%CRC24B_CHECK Check the CRC24B attached to a segmented LDPC code block.

crc_length = 24;
if numel(bits) <= crc_length
    ok = false;
    return;
end

data_bits = bits(1:end-crc_length);
received_crc = bits(end-crc_length+1:end);
calculated_crc = crc_calc_212(data_bits, 'CRC24B');
ok = isequal(received_crc(:), calculated_crc(:));
end
