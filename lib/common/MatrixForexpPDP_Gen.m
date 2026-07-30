%% Created by HuLijie, 2010-8-11
%% version 1.0
%% modified by zhangxiaofeng,2011-5-17
%% calculate the MMSE matrix

function M_expPDP = MatrixForexpPDP_Gen(path_power,path_delay,Pilot_Signal,Pilot_position,PILOT_COLUMN_INDEX,sigma,FFT_size,Pilot_port,Nr,Nc_Index)

fft_mat = dftmtx(FFT_size);                             % DFT矩阵 (原生排序: DC在行1)
fft_mat = fftshift(fft_mat, 1);                         % 行重排: DC在行N/2+1, 匹配Nc_Index的fftshift排序
P_len = size(Pilot_position,2);                         % P_len: length of Pilot symbol
NoiseI = diag(ones(1,P_len))*(sigma^2);
for nra=1:Nr
    for nta = 1:Pilot_port
        P_ns = length(PILOT_COLUMN_INDEX(nta,~isnan(PILOT_COLUMN_INDEX(nta,:)))); %取出NaN后导频符号数
        for np = 1:P_ns                                 %针对每一导频列            
            F1 = fft_mat(Pilot_position(nta,:,np),path_delay+1);
            PS_np = Pilot_Signal(nta,:,np);
            Pilot_Matrix = diag(PS_np);
            Matrix_forINV = NoiseI + Pilot_Matrix * F1 * diag(path_power) *  F1' * Pilot_Matrix';
            F2 = fft_mat(Nc_Index,path_delay+1);
            M_expPDP_temp = F2 * diag(path_power) * F1'*Pilot_Matrix'/Matrix_forINV;
            M_expPDP(nra,nta,np,:,:)=M_expPDP_temp;
        end
    end
end
end