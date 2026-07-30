function [ SNRLoopStatistic,NumOfErrorBit_s ] = PDSCH_Symbols2Bits( Data_after_Equ,SNR_after_Equ,modulation_mode,SNRLoopStatistic,TransIndex,Data_for_code,src_len )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Description: 
% (1) PDSCH_Symbols2Bits is the reverse of Bits2Symbols, is to transform
    % equalized symbols to bits.
% (2) This function can be generally divided into the following parts:
        % Step 1: soft demodulation
        % Step 2: turbo decoding
        % Step 3: combine retransmission data
        % Step 4: caculate BER
%% Input Parameters:
    % Data_after_Equ: input symbols, i.e., data after equalization
    % SNR_after_Equ: SNR on each equalized data position:
    % modulation_mode: modulation mode, 1 for BPSK, 2 for QPSK, 4 for 16QAM, 6 for 64QAM
    % SNRLoopStatistic: structure variable, statistic of each SNR loop
    % TransIndex, retransmission index
    % Data_for_code: 1*sum(src_len), data befor turbo coding
    % src_len: source bits length
%% Output Parameters:
    % SNRLoopStatistic: structure variable, statistic of each SNR loop
    % NumOfErrorBit_s: 1*Ns, error bits number in current frame
%% Modification records:
% (1) Add annotations in 2012.11.4.
% (2) Change function name "PDSCH_Demodulation" to "PDSCH_Symbols2Bits" in 2012.11.4.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global SystemParam
global TurboCodingRateMatchingParam

Ns          = SystemParam.Ns;
NL          = TurboCodingRateMatchingParam.NL;
len_Er_save = TurboCodingRateMatchingParam.len_Er_save;
len_bk_save = TurboCodingRateMatchingParam.len_bk_save;
len_dk_save = TurboCodingRateMatchingParam.len_dk_save;
C_save      = TurboCodingRateMatchingParam.C_save;
F_save      = TurboCodingRateMatchingParam.F_save;
rm_pos_save = TurboCodingRateMatchingParam.rm_pos_save;
Rc          = TurboCodingRateMatchingParam.Rc;
niter       = TurboCodingRateMatchingParam.niter;
lc          = TurboCodingRateMatchingParam.lc;
decode_sig  = TurboCodingRateMatchingParam.decode_sig;
cl          = TurboCodingRateMatchingParam.cl;

NumOfErrorBit_s = zeros(1,Ns);
ratio_s = zeros(1,Ns);

for loop_Ns = 1:Ns
    if loop_Ns == 1
        st_p1 = 1;
        et_p1 = sum(len_Er_save(1:C_save(loop_Ns)));
        len_Er = len_Er_save(1:C_save(1));
        len_bk = len_bk_save(1:C_save(1));
        len_dk = len_dk_save(1:C_save(1));
    else
        st_p1 = et_p1+1;
        et_p1 = sum(len_Er_save);
        len_Er = len_Er_save(C_save(1)+1:end);
        len_bk = len_bk_save(C_save(1)+1:end);
        len_dk = len_dk_save(C_save(1)+1:end);
    end
    rm_pos = rm_pos_save(st_p1:et_p1);
    % derate matching
    layer_num = size(Data_after_Equ,1);
    if layer_num == Ns
        Data_for_Demod = reshape(Data_after_Equ(loop_Ns,:),1,[]);
        SNR_Mod = reshape(SNR_after_Equ(loop_Ns,:),1,[]);
    else
        Data_for_Demod = reshape(Data_after_Equ((loop_Ns-1)*NL(1)+1:(loop_Ns-1)*NL(1)+NL(loop_Ns),:),1,[]);
        SNR_Mod = reshape(SNR_after_Equ((loop_Ns-1)*NL(1)+1:(loop_Ns-1)*NL(1)+NL(loop_Ns),:),1,[]);
    end
    % soft demodulation
    demodued_softvalue = newsoft_demodulation36211(Data_for_Demod,2^modulation_mode(loop_Ns),SNR_Mod);
    % 反速率匹配，译码，重传合并
    if loop_Ns == 1
        [ des_bits,TurboCodingRateMatchingParam.Soft_tobe_decode_tmp_1] = Deratematching_Decode_Combing_SS( demodued_softvalue,TurboCodingRateMatchingParam.Soft_tobe_decode_tmp_1,rm_pos,len_Er,len_bk,C_save(loop_Ns),len_dk,F_save(loop_Ns),TransIndex(loop_Ns),Rc,niter,lc,decode_sig,cl);
    else
        [ des_bits,TurboCodingRateMatchingParam.Soft_tobe_decode_tmp_2] = Deratematching_Decode_Combing_SS( demodued_softvalue,TurboCodingRateMatchingParam.Soft_tobe_decode_tmp_2,rm_pos,len_Er,len_bk,C_save(loop_Ns),len_dk,F_save(loop_Ns),TransIndex(loop_Ns),Rc,niter,lc,decode_sig,cl);
    end
    % Calculation of Symbol Error Rate
    if loop_Ns == 1
        [NumOfErrorBit_s(loop_Ns) ratio_s(loop_Ns)] = symerr(des_bits(1:src_len(loop_Ns)),Data_for_code(1:src_len(loop_Ns)));
    else
        [NumOfErrorBit_s(loop_Ns) ratio_s(loop_Ns)] = symerr(des_bits(1:src_len(loop_Ns)),Data_for_code(src_len(1)+24+1:src_len(1)+24+src_len(2)));
    end
    SNRLoopStatistic.BER_arr_Num(loop_Ns) = SNRLoopStatistic.BER_arr_Num(loop_Ns) + NumOfErrorBit_s(loop_Ns);
    SNRLoopStatistic.BER_arr_naw(loop_Ns) = SNRLoopStatistic.BER_arr_naw(loop_Ns) + ratio_s(loop_Ns);
end
%%
end