function [ H_AMC,H_BF,SNRLoopStatistic, AI_SNRLoopStatistic ] = PDSCH_Receiver(Data_Rx,MatrixForCE,Fading_Weight,MFading_Weight,BF_Matrix,SNR_line,SNRLoopStatistic, AI_SNRLoopStatistic, sigma,frame_counter,SNR_dB,snr_N,InterferencePower)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Description:
% (1) PDSCH_Receiver simulates the Receiver in PDSCH.
% (2) This process can be generally divided into the following parts:
% Step 1: OFDM demodulationg enerate beamforming matrixes (only essential when TM7/TM8)
% Step 2: channel estimation
% Step 3: equalizaion
% Step 4: process from equalized data to bits
% Step 5: statistic caculation and determine whether retransmission is needed
% (3) Each step above may contain several substeps, which are declared in
% the front of corresponding functions.
%% Input Parameters:
% Data_Rx: receiving data
% MatrixForCE: structure variable,inculding components:
% M_LMMSE_odd_CRS and M_LMMSE_even_CRS: matrixes for LMMSE CE based on CRS.
% M_expPDP_CRS: matrix for expPDP CE based on CRS.
% M_LMMSE_odd_DMRS and M_LMMSE_even_DMRS: matrixes for LMMSE CE based on DMRS.
% M_expPDP_DMRS: matrix for expPDP CE based on DMRS.
% Fading_Weight: [Nr*Nt*NumOfTaps]*Nd, channel impulse response in time domain
% BF_Matrix: beamforming matrixes
% SNR_line: linear SNR
% SNRLoopStatistic: structure variable, statistic of each SNR loop
% sigma: noise standard deviation
% frame_counter: current frame index
% SNR_dB: SNR set, unit:dB
% snr_N: current SNR circulation index
%% Output Parameters:
% H_AMC: channel frequency response for AMC
% H_BF: hannel frequency response for beamforming
% SNRLoopStatistic: structure variable, statistic of each SNR loop
% AI_SNRLoopStatistic: structure variable, statistic of each SNR loop for AI demodulation
%% Modification records:
% (1) Modify annotations in 2012.11.4.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global SystemParam
global DataPilotIndexParam
global PilotParam
global TurboCodingRateMatchingParam
global HARQParam
global LDPCCodingRateMatchingParam
global fs_estimate_history
global N_Matraix
global SC_perM
global CSIRS_perM
global DataStruct
global save_interval
TM                   = SystemParam.TM;
Ns_max               = SystemParam.Ns_max;
Ns                   = SystemParam.Ns;
Nt                   = SystemParam.Nt;
Nr                   = SystemParam.Nr;
CRS_port             = SystemParam.CRS_port;
Nd                   = SystemParam.Nd;
FFT_size             = SystemParam.FFT_size;
LengthOfGI           = SystemParam.LengthOfGI_vec;   % 3GPP可变CP向量 (1×Nd)
SamplesPerOFDM       = SystemParam.SamplesPerOFDM;
CE_Mode_CRS          = SystemParam.CE_Mode_CRS;
CE_Mode_DMRS         = SystemParam.CE_Mode_DMRS;
CE_Mode_CSIRS        = SystemParam.CE_Mode_CSIRS;
CSIRS_flag           = SystemParam.CSIRS_flag;
RetransmissionIsBind = SystemParam.RetransmissionIsBind;
CRS_position         = PilotParam.CRS_position;
CRS_COLUMN_INDEX     = PilotParam.CRS_COLUMN_INDEX;
Data_Index           = DataPilotIndexParam.Data_Index;
MaxTrans             = HARQParam.MaxTranx;
TransIndex           = HARQParam.TransIndex;
channel_code         = SystemParam.channel_code;
layer_num            = SystemParam.DMRS_port;

%% OFDM Demodulation
FFT_Out = OFDM_DeModulater(Data_Rx,FFT_size,LengthOfGI,SamplesPerOFDM,Nr,Nd,SystemParam.PhaseComp_vec);
% 保存接收端经过解OFDM后的数据
current_index = mod(frame_counter-1,save_interval)+1;
%DataStruct.Data_after_de_ofdm(current_index,:,:,:) = FFT_Out;

% %% ======================================================= AI ====================================================================
% % 获取DMRS原信号，供后续AI均衡调用
% DMRS_Signal  = PilotParam.DMRS_Signal;
% DMRS_position = PilotParam.DMRS_position;
% DMRS_COLUMN_INDEX = PilotParam.DMRS_COLUMN_INDEX;
% src_len              = LDPCCodingRateMatchingParam.src_len;
% DMRS = zeros(layer_num,FFT_size,Nd);
% for loop_layer = 1:layer_num
%     for np = 1:size(DMRS_COLUMN_INDEX,2)
%         DMRS(loop_layer,DMRS_position(loop_layer,:,np),DMRS_COLUMN_INDEX(loop_layer,np)) =  reshape(squeeze(DMRS_Signal(loop_layer,:,np)),1,[]); 	 % 放置DMRS导频
%     end
% end

% % 将接收端信道均衡前的数据传入python，调用AI模型输出软比特信息
% AI_llr = AI_receiver_call(FFT_Out, DMRS, Data_Index);

% [ AI_SNRLoopStatistic,AI_NumOfErrorBit_s ] = AI_PDSCH_Demodulation_Revised_z(AI_llr,AI_SNRLoopStatistic,TransIndex,current_index);

% if RetransmissionIsBind == 1                            % 捆绑式重传
%     if sum(AI_NumOfErrorBit_s) ~= 0
%         AI_NumOfErrorBit_s = ones(1,Ns_max);               % 一流错认为两流都错
%         AI_SNRLoopStatistic.err_frame(TransIndex) = AI_SNRLoopStatistic.err_frame(TransIndex) + 1;
%     end
% end
% % Count first transmission frame and first transmission error frame.
% for nta = 1:Ns
%     if  TransIndex(nta) == 1
%         AI_SNRLoopStatistic.BLER_t_f(nta) = AI_SNRLoopStatistic.BLER_t_f(nta) + 1;
%         if AI_NumOfErrorBit_s(nta) ~= 0
%             AI_SNRLoopStatistic.BLER_e_f(nta) = AI_SNRLoopStatistic.BLER_e_f(nta) + 1;%iBLER
%         end
%     end
% end
% for nta = 1:Ns
%     if TransIndex(nta) == 1
%         if AI_NumOfErrorBit_s(nta) == 0
%             HARQParam.ACK_adjust(nta) = 0;
%         else
%             HARQParam.ACK_adjust(nta) = 1;
%         end
%     end
% end
% % Count throughput, throughput frame and change ACK, TransIndex value
% % --------------------------HARQ-ACK--------------------------
% for nta = 1:Ns
%     if AI_NumOfErrorBit_s(nta) == 0
%         HARQParam.ACK(nta) = 0;
%         HARQParam.TransIndex(nta) = 1;
%         AI_SNRLoopStatistic.Throughput(nta) = AI_SNRLoopStatistic.Throughput(nta) + src_len(nta);
%         AI_SNRLoopStatistic.Throughput_frame(nta)= AI_SNRLoopStatistic.Throughput_frame(nta) + 1;
%     else
%         HARQParam.ACK(nta) = 1;
%         HARQParam.TransIndex(nta) = TransIndex(nta) + 1;
%         if HARQParam.TransIndex(nta) > MaxTrans
%             HARQParam.ACK(nta) = 0;
%             HARQParam.TransIndex(nta) = 1;
%             AI_SNRLoopStatistic.error_frame(nta) = AI_SNRLoopStatistic.error_frame(nta) + 1;
%         end
%     end
% end



for nra = 1:Nr
    % Get received user data
    FFT_Out_User(nra,:) = FFT_Out(nra,Data_Index);
    % Get received DMRS
    switch TM
        case {7,8,9,'NR'}
            DMRS_port = SystemParam.DMRS_port;
            Nc_used_DMRS = SystemParam.Nc_used_DMRS;
            DMRS_position = PilotParam.DMRS_position;
            DMRS_COLUMN_INDEX = PilotParam.DMRS_COLUMN_INDEX;
            for nta = 1:DMRS_port
                for np = 1:size(DMRS_COLUMN_INDEX,2)
                    FFT_Out_DMRS(nra,nta,:,np) = FFT_Out(nra,DMRS_position(nta,:,np),DMRS_COLUMN_INDEX(nta,np));
                end
            end
        case {2,3,4}
            FFT_Out_DMRS = [];
        otherwise
            error('Wrong TM!')
    end
    % Get received CRS or CSIRS
    switch TM
        case {2,3,4,7,8}
            for nta = 1:CRS_port
                P_ns = length(find(~isnan(CRS_COLUMN_INDEX(nta,:)))); %取出NaN后导频符号数
                for np = 1:P_ns
                    FFT_Out_CRS(nra,nta,:,np) = FFT_Out(nra,CRS_position(nta,:,np),CRS_COLUMN_INDEX(nta,np));    % port0、1、2、3导频位置不一样
                end
            end
            FFT_Out_CSIRS = [];
        case 9
            CSIRS_port = SystemParam.CSIRS_port;
            CSIRS_COLUMN_INDEX = PilotParam.CSIRS_COLUMN_INDEX;
            CSIRS_position = PilotParam.CSIRS_position;
            for nta = 1:CSIRS_port
                for np = 1:size(CSIRS_COLUMN_INDEX,2)
                    FFT_Out_CSIRS(nra,nta,:,np) = FFT_Out(nra,CSIRS_position(nta,:,np),CSIRS_COLUMN_INDEX(nta,np));
                end
            end
            FFT_Out_CRS = [];
        case 'NR'
            CSIRS_flag          = SystemParam.CSIRS_flag;
            if CSIRS_flag == 1
                CSIRS_port = SystemParam.CSIRS_port;
                CSIRS_COLUMN_INDEX = PilotParam.CSIRS_COLUMN_INDEX;
                CSIRS_position = PilotParam.CSIRS_position;
                %                 for nta = 1:CSIRS_port
                for nta = 1:1           % TRS only 1 port
                    for np = 1:size(CSIRS_COLUMN_INDEX,2)
                        FFT_Out_CSIRS(nra,nta,:,np) = FFT_Out(nra,CSIRS_position(nta,:,np),CSIRS_COLUMN_INDEX(nta,np));
                    end
                end
            else
                FFT_Out_CRS = [];
                FFT_Out_CSIRS = [];    %zlh 关闭csirs
            end
        otherwise
            error('Wrong TM!')
    end
end
% CSIRS_port1 = 1;
% M_expPDP_CSIRS = MatrixForCE.M_expPDP_CSIRS;
% for nrb = 1:N_Matraix
%     stp = (nrb-1)*SC_perM+1;
%     edp = nrb * SC_perM;
%     stp1 = (nrb-1)*CSIRS_perM+1;
%     edp1 = nrb * CSIRS_perM;
%     FFT_Out_CSIRS_RB = FFT_Out_CSIRS(:,:,stp1:edp1,:);
%     [ a, b c d e f ] = size(M_expPDP_CSIRS);
%     M_expPDP_CSIRS_temp = zeros(b,c,d,e,f);
%     M_expPDP_CSIRS_temp(:,:,:,:,:) = M_expPDP_CSIRS(nrb,:,:,:,:,:);
%     H_temp = expPDP_TRS(CSIRS_port1,Nr,SC_perM,FFT_Out_CSIRS_RB,PilotParam.CSIRS_COLUMN_INDEX,M_expPDP_CSIRS_temp);
%     H_TRS(stp:edp,:)= H_temp;
% end
% %% Doppler shif estimation and compensation
% if CSIRS_flag == 1
%     his_weight = 0.7;
%     fs_estimate_now = fs_TRSbased(H_TRS); 
% %     fs_estimate_history  = his_weight*fs_estimate_history + (1-his_weight)*fs_estimate_now;
% end
%% other one
% if CSIRS_flag == 1
%     his_weight = 0.7;
%     fs_estimate_now = fs_CSIRSbased(squeeze(FFT_Out_CSIRS),PilotParam.CSIRS_Signal); %size(FFT_Out_CSIRS) = 2 1 54 2
% %     fs_estimate_history  = his_weight*fs_estimate_history + (1-his_weight)*fs_estimate_now;
% end
% Data_Rx = Data_Rx.*repmat(exp(-1i*2*pi*fs_estimate_history*[0:1:SystemParam.LengthOfBurst-1]*SystemParam.dt),Nr,1);
% FFT_Out = OFDM_DeModulater(Data_Rx,FFT_size,LengthOfGI,SamplesPerOFDM,Nr,Nd);
% for nra = 1:Nr
%     % Get received user data
%     FFT_Out_User(nra,:) = FFT_Out(nra,Data_Index);
%     % Get received DMRS
%     switch TM
%         case {7,8,9,'NR'}
%             DMRS_port = SystemParam.DMRS_port;
%             Nc_used_DMRS = SystemParam.Nc_used_DMRS;
%             DMRS_position = PilotParam.DMRS_position;
%             DMRS_COLUMN_INDEX = PilotParam.DMRS_COLUMN_INDEX;
%             for nta = 1:DMRS_port
%                 for np = 1:size(DMRS_COLUMN_INDEX,2)
%                     FFT_Out_DMRS(nra,nta,:,np) = FFT_Out(nra,DMRS_position(nta,:,np),DMRS_COLUMN_INDEX(nta,np));
%                 end
%             end
%         case {2,3,4}
%             FFT_Out_DMRS = [];
%         otherwise
%             error('Wrong TM!')
%     end
%     % Get received CRS or CSIRS
%     switch TM
%         case {2,3,4,7,8}
%             for nta = 1:CRS_port
%                 P_ns = length(find(~isnan(CRS_COLUMN_INDEX(nta,:)))); %取出NaN后导频符号数
%                 for np = 1:P_ns
%                     FFT_Out_CRS(nra,nta,:,np) = FFT_Out(nra,CRS_position(nta,:,np),CRS_COLUMN_INDEX(nta,np));    % port0、1、2、3导频位置不一样
%                 end
%             end
%             FFT_Out_CSIRS = [];
%         case 9
%             CSIRS_port = SystemParam.CSIRS_port;
%             CSIRS_COLUMN_INDEX = PilotParam.CSIRS_COLUMN_INDEX;
%             CSIRS_position = PilotParam.CSIRS_position;
%             for nta = 1:CSIRS_port
%                 for np = 1:size(CSIRS_COLUMN_INDEX,2)
%                     FFT_Out_CSIRS(nra,nta,:,np) = FFT_Out(nra,CSIRS_position(nta,:,np),CSIRS_COLUMN_INDEX(nta,np));
%                 end
%             end
%             FFT_Out_CRS = [];
%         case 'NR'
%             FFT_Out_CRS = [];
%             FFT_Out_CSIRS = [];    %zlh 关闭csirs
%         otherwise
%             error('Wrong TM!')
%     end
% end

%% TD-OCC解扩合并 (NR DMRSLength=2): 双符号→单符号, 降噪3dB, 恢复正交性
did_dmrs_despread = false;
if strcmp(TM,'NR') && SystemParam.DMRSLength == 2 && SystemParam.DMRS_Type ~= 1
    Nsym_total = size(DMRS_COLUMN_INDEX,2);       % 实际DMRS符号总数
    Npos_expected = SystemParam.NumOfAddDMRS + 1;
    if Nsym_total == 2*Npos_expected
        % 备份全局PilotParam，CE结束后恢复，避免下一帧重复解扩
        DMRS_Signal_bak = PilotParam.DMRS_Signal;
        DMRS_Pos_bak = PilotParam.DMRS_position;
        DMRS_Col_bak = PilotParam.DMRS_COLUMN_INDEX;

        Npos = Npos_expected;
        FFT_Out_DMRS_ds = zeros(Nr, DMRS_port, Nc_used_DMRS, Npos);
        DMRS_Signal_ds   = zeros(size(PilotParam.DMRS_Signal,1), Nc_used_DMRS, Npos);
        DMRS_Pos_ds      = zeros(size(DMRS_position,1), Nc_used_DMRS, Npos);
        DMRS_Col_ds      = zeros(size(DMRS_COLUMN_INDEX,1), Npos);
        for pos = 1:Npos
            s0 = (pos-1)*2 + 1;  s1 = s0 + 1;
            for lp = 1:DMRS_port
                if lp <= 4   % TD-OCC=[+1,+1] → 加
                    FFT_Out_DMRS_ds(:,lp,:,pos) = (FFT_Out_DMRS(:,lp,:,s0) + FFT_Out_DMRS(:,lp,:,s1)) / 2;
                    DMRS_Signal_ds(lp,:,pos) = (PilotParam.DMRS_Signal(lp,:,s0) + PilotParam.DMRS_Signal(lp,:,s1)) / 2;
                else         % TD-OCC=[+1,-1] → 减
                    FFT_Out_DMRS_ds(:,lp,:,pos) = (FFT_Out_DMRS(:,lp,:,s0) - FFT_Out_DMRS(:,lp,:,s1)) / 2;
                    DMRS_Signal_ds(lp,:,pos) = (PilotParam.DMRS_Signal(lp,:,s0) - PilotParam.DMRS_Signal(lp,:,s1)) / 2;
                end
            end
            DMRS_Pos_ds(:,:,pos) = DMRS_position(:,:,s0);
            DMRS_Col_ds(:,pos)   = DMRS_COLUMN_INDEX(:,s0);
        end
        FFT_Out_DMRS = FFT_Out_DMRS_ds;
        PilotParam.DMRS_Signal       = DMRS_Signal_ds;
        PilotParam.DMRS_position     = DMRS_Pos_ds;
        PilotParam.DMRS_COLUMN_INDEX = DMRS_Col_ds;
        did_dmrs_despread = true;
    elseif Nsym_total ~= Npos_expected
        error('DMRSLength=2 expects Nsym_total=%d or %d, but got %d.', 2*Npos_expected, Npos_expected, Nsym_total);
    end
end

MatrixForCE          = MatrixForCE_Gen(sigma);
%% Channel Estimation
FFT_Out_DMRS_for_CE = FFT_Out_DMRS;
if strcmp(TM, 'NR') && SystemParam.DMRS_Type == 1 && DMRS_port <= 8
    % Type-1 CDM groups use FD-OCC for up to four layers and joint FD/TD-OCC
    % for layers 5-8. Keep original joint samples for DMRS EVM; channel
    % estimation receives per-port virtual observations.
    FFT_Out_DMRS_for_CE = nr_dmrs_fd_occ_despread(FFT_Out_DMRS, ...
        PilotParam.DMRS_Signal, PilotParam.DMRS_position, DMRS_port);
end
[ H_AMC,H_Equalization,H_BF,H_DMRS_Equ ] = PDSCH_ChannelEstimation( CE_Mode_CRS,CE_Mode_DMRS,CE_Mode_CSIRS,MatrixForCE,Fading_Weight,FFT_Out_CRS,FFT_Out_DMRS_for_CE,FFT_Out_CSIRS,BF_Matrix);
%% DMRS Equalization and EVM Calculation (before PilotParam restoration)
[dmrs_evm_str, dmrs_evm_rms] = DMRS_Equalizer_EVM(H_DMRS_Equ, FFT_Out_DMRS, SystemParam.DMRS_port, ...
    PilotParam.DMRS_position, PilotParam.DMRS_COLUMN_INDEX, PilotParam.DMRS_Signal, Nr, sigma);
% 累加DMRS EVM (有效数值时)
if ~isnan(dmrs_evm_rms)
    SNRLoopStatistic.DMRS_EVM_sum = SNRLoopStatistic.DMRS_EVM_sum + dmrs_evm_rms;
    SNRLoopStatistic.DMRS_EVM_count = SNRLoopStatistic.DMRS_EVM_count + 1;
end
if did_dmrs_despread
    PilotParam.DMRS_Signal = DMRS_Signal_bak;
    PilotParam.DMRS_position = DMRS_Pos_bak;
    PilotParam.DMRS_COLUMN_INDEX = DMRS_Col_bak;
end
%% Equalization(or Signal Detection)
H_Equalization2 = 0;
[ Data_after_Equ,SNR_after_Equ ] = PDSCH_Equalizer(TM,H_Equalization,FFT_Out_User,CRS_port,Nt,Nr,Data_Index,SNR_line,sigma,H_Equalization2,InterferencePower);
%scatterplot(Data_after_Equ)
if SystemParam.RML_Flag == 0
    %DataStruct.data_rx(current_index,:,:) = Data_after_Equ;
else
    %DataStruct.llr_raw(current_index,:) = Data_after_Equ;
end
%% Demodulation, decoding and combining
% % 星座图诊断用
% global Debug_Data_after_Equ Debug_SNR_after_Equ
% Debug_Data_after_Equ = Data_after_Equ;
% Debug_SNR_after_Equ = SNR_after_Equ;
LDPCCodingRateMatchingParam.des_bits_all = [];  % 重置EVM解码比特缓存
if channel_code==1
    modulation_mode      = TurboCodingRateMatchingParam.modulation_mode;
    src_len              = TurboCodingRateMatchingParam.src_len;
    Data_for_code        = TurboCodingRateMatchingParam.Data_for_code;
    [ SNRLoopStatistic,NumOfErrorBit_s ] = PDSCH_Symbols2Bits(Data_after_Equ,SNR_after_Equ,modulation_mode,SNRLoopStatistic,TransIndex,Data_for_code,src_len);
elseif channel_code==2
    src_len              = LDPCCodingRateMatchingParam.src_len;
    [ SNRLoopStatistic,NumOfErrorBit_s ] = PDSCH_Demodulation_Revised_z(Data_after_Equ,SNR_after_Equ,SNRLoopStatistic,TransIndex,current_index);
end

%% EVM计算 (仅无误码frame: 收端解码比特→重编码→重调制→理想星座点)
evm_str = '';   % 初始化EVM信息字符串
if all(NumOfErrorBit_s == 0) && channel_code == 2
    try
        des_bits_all = LDPCCodingRateMatchingParam.des_bits_all;
        if ~isempty(des_bits_all)
            ideal_Mod = reencode_for_evm(des_bits_all, LDPCCodingRateMatchingParam, SystemParam, HARQParam);
            Ncmp = min(size(Data_after_Equ,2), size(ideal_Mod,2));
            rx_vec = reshape(Data_after_Equ(:, 1:Ncmp), 1, []);
            tx_vec = reshape(ideal_Mod(:, 1:Ncmp), 1, []);
            evm_rms = sqrt(mean(abs(rx_vec - tx_vec).^2)) / sqrt(mean(abs(tx_vec).^2));
            evm_db  = 20 * log10(evm_rms);
            evm_str = sprintf('--EVM:%.2f%%(%.1fdB)', evm_rms*100, evm_db);
            % 累加数据EVM
            SNRLoopStatistic.EVM_sum = SNRLoopStatistic.EVM_sum + evm_rms;
            SNRLoopStatistic.EVM_count = SNRLoopStatistic.EVM_count + 1;
        end
    catch ME
        evm_str = sprintf('--EVM:failed(%s)', ME.message);
    end
elseif ~all(NumOfErrorBit_s == 0) && channel_code == 2
    evm_str = '--EVM:skip(err)';
end

%% Caculate Statistic of Each Frame Circulation
% Judge if two streams retransmission is indepent<0> or binded<1>.
if RetransmissionIsBind == 1                            % 捆绑式重传
    if sum(NumOfErrorBit_s) ~= 0
        NumOfErrorBit_s = ones(1,Ns_max);               % 一流错认为两流都错
        SNRLoopStatistic.err_frame(TransIndex) = SNRLoopStatistic.err_frame(TransIndex) + 1;
    end
end
% Count first transmission frame and first transmission error frame.
for nta = 1:Ns
    if  TransIndex(nta) == 1
        SNRLoopStatistic.BLER_t_f(nta) = SNRLoopStatistic.BLER_t_f(nta) + 1;
        if NumOfErrorBit_s(nta) ~= 0
            SNRLoopStatistic.BLER_e_f(nta) = SNRLoopStatistic.BLER_e_f(nta) + 1;%iBLER
        end
    end
end
for nta = 1:Ns
    if TransIndex(nta) == 1
        if NumOfErrorBit_s(nta) == 0
            HARQParam.ACK_adjust(nta) = 0;
        else
            HARQParam.ACK_adjust(nta) = 1;
        end
    end
end
% Count throughput, throughput frame and change ACK, TransIndex value
% --------------------------HARQ-ACK--------------------------
for nta = 1:Ns
    if NumOfErrorBit_s(nta) == 0
        HARQParam.ACK(nta) = 0;
        HARQParam.TransIndex(nta) = 1;
        SNRLoopStatistic.Throughput(nta) = SNRLoopStatistic.Throughput(nta) + src_len(nta);
        SNRLoopStatistic.Throughput_frame(nta)= SNRLoopStatistic.Throughput_frame(nta) + 1;
    else
        HARQParam.ACK(nta) = 1;
        HARQParam.TransIndex(nta) = TransIndex(nta) + 1;
        if HARQParam.TransIndex(nta) > MaxTrans
            HARQParam.ACK(nta) = 0;
            HARQParam.TransIndex(nta) = 1;
            SNRLoopStatistic.error_frame(nta) = SNRLoopStatistic.error_frame(nta) + 1;
        end
    end
end
% --------------------------强制传输最大次数--------------------------
% HARQParam.TransIndex(nta) = TransIndex(nta) + 1;
% if HARQParam.TransIndex(nta) > MaxTrans
%     HARQParam.ACK(nta) = 0;
%     HARQParam.TransIndex(nta) = 1;
%     if NumOfErrorBit_s(nta) == 0
%         SNRLoopStatistic.Throughput(nta) = SNRLoopStatistic.Throughput(nta) + src_len(nta);
%         SNRLoopStatistic.Throughput_frame(nta)= SNRLoopStatistic.Throughput_frame(nta) + 1;
%     else
%         SNRLoopStatistic.error_frame(nta) = SNRLoopStatistic.error_frame(nta) + 1;
%     end
% else
%     HARQParam.ACK(nta) = 1;
% end

% Print statistic of each frame circulation
switch TM
    case {'NR',9}
        layernum = DMRS_port;
    otherwise
        layernum = Ns;
end
if mod(frame_counter,1) == 0
    if Ns_max == 1
        fprintf('SNR:%.1f[dB]--N_Frame:%d--n_s_f:%d--N_Block:%d--Ns:%d--layernum:%d--Sum_BER:%.3f--tempBLER1:%.3f--TransIndex:%d--BLER:%.3f--myTP:%.3f%s%s\n',SNR_dB(snr_N),frame_counter,SystemParam.n_s_f,SNRLoopStatistic.BLER_t_f,SystemParam.Ns,layernum,SNRLoopStatistic.BER_arr_naw,SNRLoopStatistic.BLER_e_f/SNRLoopStatistic.BLER_t_f,TransIndex,SNRLoopStatistic.error_frame/SNRLoopStatistic.BLER_t_f,sum(SNRLoopStatistic.Throughput_frame)./frame_counter,evm_str,dmrs_evm_str);
        %fprintf('AI : SNR:%.1f[dB]--N_Frame:%d--N_Block:%d--Ns:%d--layernum:%d--Sum_BER:%.3f--tempBLER1:%.3f--TransIndex:%d--BLER:%.3f--myTP:%.3f%s\n',SNR_dB(snr_N),frame_counter,AI_SNRLoopStatistic.BLER_t_f,SystemParam.Ns,layernum,AI_SNRLoopStatistic.BER_arr_naw,AI_SNRLoopStatistic.BLER_e_f/AI_SNRLoopStatistic.BLER_t_f,TransIndex,AI_SNRLoopStatistic.error_frame/AI_SNRLoopStatistic.BLER_t_f,sum(AI_SNRLoopStatistic.Throughput_frame)./frame_counter,evm_str);
    else
        fprintf('SNR:%d[dB]--N_Frame:%d--n_s_f:%d--Ns:%d--layernum:%d--Sum_BER1:%.3f--Sum_BER2:%.3f--tempBLER:%e%s%s\n',SNR_dB(snr_N),frame_counter,SystemParam.n_s_f,SystemParam.Ns,layernum,SNRLoopStatistic.BER_arr_naw(1),SNRLoopStatistic.BER_arr_naw(2),sum(SNRLoopStatistic.BLER_e_f)/sum(SNRLoopStatistic.BLER_t_f),evm_str,dmrs_evm_str);
        %fprintf('AI : SNR:%d[dB]--N_Frame:%d--Ns:%d--layernum:%d--Sum_BER1:%.3f--Sum_BER2:%.3f--tempBLER:%e%s\n',SNR_dB(snr_N),frame_counter,AI_SNRLoopStatistic.BLER_t_f,SystemParam.Ns,layernum,AI_SNRLoopStatistic.BER_arr_naw(1),AI_SNRLoopStatistic.BER_arr_naw(2),sum(AI_SNRLoopStatistic.BLER_e_f)/sum(AI_SNRLoopStatistic.BLER_t_f),evm_str);
    end
end

end

