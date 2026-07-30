function [ des_bits,Soft_tobe_decode_tmp] = Deratematching_Decode_Combing_SS( demodued_softvalue,Soft_tobe_decode_tmp,rm_pos,len_Er,len_bk,C,len_dk,F,TransIndex,Rc,niter,lc,decode_sig,cl)
%%
% 注意：此函数只适用于单流情况。
rx_bits=zeros(1,sum(len_bk));
index_buffer = 0;
for r_idx=1:C          % C is the number of code blocks
    % separate the whole stream into small blocks
    st_p=sum(len_Er(1:r_idx-1))+1;
    ed_p=sum(len_Er(1:r_idx));
    devided_block=demodued_softvalue(st_p:ed_p);
    rm_idx=rm_pos(st_p:ed_p);
    % rate dematch
    to_decode_softvalue=zeros(1,len_dk(r_idx));
    for ii=1:length(devided_block)
        to_decode_softvalue(rm_idx(ii))=to_decode_softvalue(rm_idx(ii))+devided_block(ii);
    end

    % Combining %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Soft_tobe_decode_tmp(TransIndex,index_buffer+1:index_buffer+len_dk(r_idx))=to_decode_softvalue;
    index_buffer = index_buffer+len_dk(r_idx);
    Soft_tobe_decode = sum(Soft_tobe_decode_tmp((1:TransIndex),:),1);
    decoded_bits = TurboDe36212_clip(Soft_tobe_decode(index_buffer-len_dk(r_idx)+1:index_buffer),Rc,niter,lc,decode_sig,cl);
    % cyclic redundancy check for each code block
    st_p = sum(len_bk(1:r_idx-1))+1;
    ed_p = sum(len_bk(1:r_idx));
    rx_bits(st_p:ed_p) = decoded_bits(1:ed_p-st_p+1);
end % end r_idx
des_bits = rx_bits(F+1:end); % abandon the filled bits

end

