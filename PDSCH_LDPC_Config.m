function config = PDSCH_LDPC_Config()
%PDSCH_LDPC_CONFIG Data-scrambling and decoder settings for the receiver.

config.RNTI = 1;
config.nID = 0;
config.q = 0;
config.max_iterations = 50;
config.LDPC_decoder_cpp_alter = true;  % true=使用C++ BP译码器, false=使用纯MATLAB sum-product译码器
end
