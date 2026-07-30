function FFT_Out = OFDM_DeModulater(Data_Rx,FFT_size,LengthOfGI,SamplesPerOFDM,Nr,Nd,PhaseComp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Description: 
% (1) % This function accomplishes OFDM demodulation as follows:
        % Step 1: parallel to serial
        % Step 2: remove CP
        % Step 3: FFT (含相位补偿撤销)
%% Input Parameters:
    % Data_Rx: input signals
    % FFT_size: FFT size
    % LengthOfGI: CP length or guard interval length
    % SamplesPerOFDM: sample number of each OFDM symbol
    % Nr: number of reveiving antenna
    % Nd: number of OFDM symbols in each RB pair
    % PhaseComp: 每符号相位补偿向量 1×Nd (TS 38.211, 默认全1=无补偿)
%% Output Parameters:
    % FFT_Out: Nr*FFT_size*Nd, OFDM demoulated signals
%% Modification records:
% (1) modify annotations in 2012.11.4.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 处理CP向量输入 (3GPP TS 38.211: 每0.5ms首符号CP较长)
if isscalar(LengthOfGI)
    cp_vec = LengthOfGI * ones(1, Nd);
else
    cp_vec = LengthOfGI(:).';
end

FFT_Out = zeros(Nr,FFT_size,Nd);
for nra = 1:Nr
    idx = 1;
    for sym = 1:Nd
        cp_len = cp_vec(sym);
        FFT_In = Data_Rx(nra, idx+cp_len : idx+cp_len+FFT_size-1).';
        idx = idx + FFT_size + cp_len;
        % 撤销相位补偿 (TS 38.211 §5.3.1)
        if ~all(PhaseComp == 1)
            FFT_In = FFT_In .* conj(PhaseComp(sym));
        end
        % FFT Transform (fftshift: 将DC从索引1移回中心, 匹配信道估计的fftshift排序)
        FFT_Out(nra,:,sym) = fftshift(fft(FFT_In) ./ sqrt(FFT_size), 1);
    end
end
