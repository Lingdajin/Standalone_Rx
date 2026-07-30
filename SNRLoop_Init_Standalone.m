function SNRLoopStatistic = SNRLoop_Init_Standalone(Ns_max)
% 为独立接收机创建最小SNRLoopStatistic结构
SNRLoopStatistic.BLER_t_f = zeros(1, Ns_max);
SNRLoopStatistic.BLER_e_f = zeros(1, Ns_max);
SNRLoopStatistic.BER_arr_naw = zeros(1, Ns_max);
SNRLoopStatistic.BER_arr_Num = zeros(1, Ns_max);
SNRLoopStatistic.NumOfErrorBit_s = zeros(1, Ns_max);
SNRLoopStatistic.ratio_s = zeros(1, Ns_max);
SNRLoopStatistic.error_frame = zeros(1, Ns_max);
SNRLoopStatistic.err_frame = zeros(1, 4);
SNRLoopStatistic.Throughput = zeros(1, Ns_max);
SNRLoopStatistic.Throughput_frame = zeros(1, Ns_max);
SNRLoopStatistic.EVM_sum = 0;
SNRLoopStatistic.EVM_count = 0;
SNRLoopStatistic.DMRS_EVM_sum = 0;
SNRLoopStatistic.DMRS_EVM_count = 0;
SNRLoopStatistic.EVM_avg = 0;
SNRLoopStatistic.DMRS_EVM_avg = 0;
end
