function [ CB_rmbits, rm_pos ] = LDPC_ratematch( CBS,CBcoded_bits,BGtype,z,TransIndex,Er,rv_idx_seq,l_padding  )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Name£ºLDPC_ratematch
% Input: 
%   r: the order of CB
%   CBS: length of the CB
%   CBcoded_bits: encoded bits of the CB
%   BGtype: Base graph type
%   z: lifting factor
%   TransIndex: time of transmission of the CB
%   Er: the rate matching length for the CB
%   rv_idx_seq: the retransmission sequence order of RV
% Output:
%  CB_rmbits: CB rate matching data
% Description£º
% (1) This function generates rate-matching data of one CB.
% Detail:
%    
%% Modification records:
% (1) Created by zhangjingwen in 2018.3.1.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
N = length(CBcoded_bits);
% if I_LBRM == 0
%     Ncb = N;
% else
%     R_LBRM = 2/3;
%     Nref = floor(TBS_LBRM./C./R_LBRM); %TBS_LBRM is determined in TS38.214
%     Ncb = min(N,Nref);
% end
N_cb = N;
Kr = CBS - 2*z;

rv_idx = rv_idx_seq(TransIndex);
if strcmp(BGtype, 'BG1')
    kb = 22;
    switch rv_idx
        case 0
            k0 = 1;
        case 1
            k0 = floor(17*N_cb/66/z)*z+1;
        case 2
            k0 = floor(33*N_cb/66/z)*z+1;
        case 3
            k0 = floor(56*N_cb/66/z)*z+1;
    end
else if strcmp(BGtype, 'BG2')
        kb = 10;
        switch rv_idx
            case 0
                k0 = 1;
            case 1
                k0 = floor(13*N_cb/50/z)*z+1;
            case 2
                k0 = floor(25*N_cb/50/z)*z+1;
            case 3
                k0 = floor(43*N_cb/50/z)*z+1;
        end
    end
end
k = 1;
j = 0;

tst_pos = 1:1:N_cb;
while k <= Er
    if mod(k0+j,N_cb) <= Kr || mod(k0+j,N_cb) > (Kr+l_padding)
        if mod(k0+j,N_cb) == 0
            CB_rmbits(k) = CBcoded_bits(N_cb);
            rm_pos(k) = tst_pos (N_cb);
        else
            CB_rmbits(k) = CBcoded_bits(mod(k0+j,N_cb));
            rm_pos(k) = tst_pos (mod(k0+j,N_cb));
        end
        k = k+1;
    end
    j = j+1;
end

end

