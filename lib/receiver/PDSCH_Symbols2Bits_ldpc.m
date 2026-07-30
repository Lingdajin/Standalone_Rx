function [ des_bits ] = PDSCH_Symbols2Bits_ldpc( Data_for_Demod,SNR_Mod,modulation_mode,TransIndex,src_len,current_index )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Description: 
% (1) PDSCH_Symbols2Bits is the reverse of Bits2Symbols, is to transform
    % equalized symbols to bits.
% (2) This function can be generally divided into the following parts:
        % Step 1: soft demodulation
        % Step 2: LDPC decoding
        % Step 3: combine retransmission data
%% Input Parameters:
    % Data_after_Equ: input symbols, i.e., data after equalization
    % SNR_after_Equ: SNR on each equalized data position:
    % modulation_mode: modulation mode, 1 for BPSK, 2 for QPSK, 4 for 16QAM, 6 for 64QAM
    % SNRLoopStatistic: structure variable, statistic of each SNR loop
    % TransIndex, retransmission index
    % Data_for_code: 1*sum(src_len), data befor turbo/LDPC coding
    % src_len: source bits length
%% Output Parameters:
    % des_bits: bits after decoding
%     % SNRLoopStatistic: structure variable, statistic of each SNR loop
%     % NumOfErrorBit_s: 1*Ns, error bits number in current frame
%% Modification records:
% (1) Add annotations in 2012.11.4.
% (2) Change function name "PDSCH_Demodulation" to "PDSCH_Symbols2Bits" in 2012.11.4.
% (3) Change decoding and HARQ in 2018.3.4.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global aaa ccc  BF_Matrix
global SystemParam
global LDPCCodingRateMatchingParam
global HARQParam
global DataStruct

Ns          = SystemParam.Ns;
len_Er_save = LDPCCodingRateMatchingParam.len_Er_save;
len_CB_save = LDPCCodingRateMatchingParam.len_CB_save;
C_save      = LDPCCodingRateMatchingParam.C_save;
F_save      = LDPCCodingRateMatchingParam.F_save;
for loop_Ns = 1:Ns
    if loop_Ns == 1
        E = len_Er_save(1:C_save(1));
        CBS = len_CB_save(1);
        SimParam = LDPCCodingRateMatchingParam.SimParam_1;
        LLRbuffer = LDPCCodingRateMatchingParam.LLRbuffer_1;
        to_decode_softvalue = LDPCCodingRateMatchingParam.to_decode_softvalue_1;
        rm_pos = LDPCCodingRateMatchingParam.rm_pos_1;
    else
%         st_p1 = et_p1+1;
%         et_p1 = sum(len_Er_save);
        E = len_Er_save(C_save(1)+1:end);
        CBS = len_CB_save(C_save(1)+1);
        SimParam = LDPCCodingRateMatchingParam.SimParam_2;
        LLRbuffer = LDPCCodingRateMatchingParam.LLRbuffer_2;
        to_decode_softvalue = LDPCCodingRateMatchingParam.to_decode_softvalue_2;
        rm_pos = LDPCCodingRateMatchingParam.rm_pos_2;
    end
    ModuOrder = modulation_mode(loop_Ns);
    C = C_save(loop_Ns);
    F = F_save(loop_Ns);
    harqCount=TransIndex(loop_Ns);
    
    SNR_Mod_1 = ones(1, 2880);

    %% soft demodulation
%     demodued_softvalue = newsoft_demodulation36211(Data_for_Demod,2^ModuOrder,SNR_Mod);
    demodued_softvalue = newsoft_demodulation36211(Data_for_Demod,2^ModuOrder,SNR_Mod);
    %DataStruct.llr_raw(current_index,:) = demodued_softvalue(1,:);
    
    % % ==== LLR诊断 (仅第一次) ====
    % global LLR_Debug_Done
    % if isempty(LLR_Debug_Done)
    %     LLR_Debug_Done = false;
    % end
    % if ~LLR_Debug_Done && loop_Ns == 1
    %     LLR_Debug_Done = true;
    %     fprintf('[LLR诊断] demodued_softvalue: len=%d mean=%.3f std=%.3f min=%.3f max=%.3f\n', ...
    %         length(demodued_softvalue), mean(demodued_softvalue), std(demodued_softvalue), ...
    %         min(demodued_softvalue), max(demodued_softvalue));
    %     hard_bits = double(demodued_softvalue < 0);
    %     fprintf('[LLR诊断] 前80 hard bits: %s\n', num2str(hard_bits(1:80)));
    %     descramed_softvalue_test = descramble(demodued_softvalue);
    %     fprintf('[LLR诊断] 解扰后: mean=%.3f std=%.3f\n', mean(descramed_softvalue_test), std(descramed_softvalue_test));
    % end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%调试用 zlh%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     bbb  = zeros(1,length(demodued_softvalue));
%     for iii = 1:length(demodued_softvalue) 
%         if demodued_softvalue(iii)<0
%             bbb(iii) = 1;
%         elseif demodued_softvalue(iii)==0
%             error('demodued_softvalue(iii)==0');
%         else
%             bbb(iii) = 0;
%         end
%     end
% %     [a2,b2] = symerr(ccc,Data_for_Demod);
% %     plot(ccc,'ro');
% %     hold on
% %     plot(Data_for_Demod,'b.')
%     [a1,b1] = biterr(aaa,bbb);
% % %     diffe = find(aaa~=bbb); 
%     kkk = mean(abs(demodued_softvalue));
% %     if kkk>10000
% %         demodued_softvalue = demodued_softvalue/kkk*100;
% %         kkk = mean(abs(demodued_softvalue));
% %     end
% % %     lklk = sum(sum(abs(BF_Matrix).^2));
%     fprintf('Errorbit:%d  biterr:%.3f  LLRmean:%d\n',a1,b1,kkk);
% % %     hold off
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    descramed_softvalue = descramble(demodued_softvalue);
     end_pos = 0;
     for r = 1:C
         start_pos = 1+end_pos;
         end_pos = sum(E(1:r));
         softvalue_C= descramed_softvalue(start_pos:end_pos);
         softvalue_deinter = LDPC_deinterleaver( softvalue_C,ModuOrder );% 解交织
         LLRbuffer{r,harqCount} = softvalue_deinter;
     end
     des_bits=[];
     for r=1:C
         LLRbuffer_now = cell2mat(LLRbuffer(r,harqCount));
%          LLRbuffer_now1 = LLRbuffer(r,:);
%          Er = E(r);
%          LLR_combine = IRCombining(SimParam,CBS,harqCount,Er,LLRbuffer_now1);
         st_p=sum(E(1:r-1))+1;
         ed_p=sum(E(1:r));
         rm_pos_thisCB = rm_pos(st_p:ed_p);
%          for jj = 1:length(rm_pos_thisCB)
%              to_decode_softvalue(r,rm_pos_thisCB(jj))=to_decode_softvalue(r,rm_pos_thisCB(jj))+LLRbuffer_now(jj);
%          end
         to_decode_softvalue(r,rm_pos_thisCB)=to_decode_softvalue(r,rm_pos_thisCB)+LLRbuffer_now;
         z = SimParam.liftZ;
         l_padding = SimParam.l_padding;
         K_cb = CBS-2*z;
         to_decode_softvalue_final = to_decode_softvalue(r,:);
         to_decode_softvalue_final(K_cb+1:K_cb+l_padding) = 10*max(to_decode_softvalue(r,:))*ones(1,l_padding);
         to_decode_softvalue_final = [zeros(1,2*z) to_decode_softvalue_final];
%          Nd_bits = length(LLR_combine);
%          BGtype = SimParam.BGtype;
         iter = SimParam.iterationNumLDPC;
         Hd_base = SimParam.Hd_base;
         [row_base,col_base] = size(Hd_base);
         row_H = row_base*z;
         col_H = col_base*z;
         LLR_combine_tmp = zeros(1,col_H);
         LLR_combine_tmp(1:length(to_decode_softvalue_final))=to_decode_softvalue_final;
         CBbits_dec = decoder_opt(LLR_combine_tmp,row_H,col_H,iter,Hd_base,z,row_base,col_base);
         if C == 1
             des_bits=[des_bits CBbits_dec(1:CBS)];
         else
             des_bits=[des_bits CBbits_dec(1:CBS-24)];
         end
     end
     if loop_Ns == 1
          LDPCCodingRateMatchingParam.LLRbuffer_1=LLRbuffer;
          LDPCCodingRateMatchingParam.to_decode_softvalue_1=to_decode_softvalue;
     else
          LDPCCodingRateMatchingParam.LLRbuffer_2=LLRbuffer;
          LDPCCodingRateMatchingParam.to_decode_softvalue_2=to_decode_softvalue;
     end
end
%%
end