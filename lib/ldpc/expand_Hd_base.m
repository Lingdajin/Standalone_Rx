function Hd_full = expand_Hd_base(Hd_base, z)
%EXPAND_HD_BASE Expand an NR LDPC base matrix into a sparse parity matrix.

[row_base, col_base] = size(Hd_base);
Hd_full = sparse(row_base * z, col_base * z);
identity = speye(z);

for row_idx = 1:row_base
    row_range = (row_idx - 1) * z + (1:z);
    for col_idx = 1:col_base
        shift = Hd_base(row_idx, col_idx);
        if shift >= 0
            col_range = (col_idx - 1) * z + (1:z);
            Hd_full(row_range, col_range) = circshift(identity, shift, 2);
        end
    end
end
end
