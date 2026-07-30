function ok = crc24a_check(bits, crc_length)
%CRC24A_CHECK Check the CRC attached to an LDPC transport block.

if numel(bits) < crc_length + 1
    ok = false;
    return;
end

switch crc_length
    case 24
        polynomial = 'CRC24A';
    case 16
        polynomial = 'CRC16';
    otherwise
        error('crc24a_check:UnsupportedLength', ...
            'Unsupported transport-block CRC length: %d.', crc_length);
end

data_bits = bits(1:end-crc_length);
received_crc = bits(end-crc_length+1:end);
calculated_crc = crc_calc_212(data_bits, polynomial);
ok = isequal(received_crc(:), calculated_crc(:));
end
