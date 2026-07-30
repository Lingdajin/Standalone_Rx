%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output parameters:
    % H_Innse: frequency domaion H, with size m*n*p, and:
    % m: Nt*Nr;
    % n: used subcarrier index;
    % p: OFDM symbol index of data region.
% Modified in 2012.3 based on previous CE.
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ H_Inuse ] = Ideal_CE(Nt,Nr,Nc_Index,FFT_size,Path_Delay,NumOfTaps,Fading_Weight,DATA_COLUMN_INDEX)

[a, NumOfsymbol] = size(Fading_Weight);                                                          % NumOfsymbol:OFDM符号个数
H_Ideal_All = zeros(Nt*Nr,FFT_size,NumOfsymbol); 
for nSym = 1:NumOfsymbol
    Fading_Weight_Repilot = reshape(Fading_Weight(:,nSym),NumOfTaps,Nt*Nr);  % 单个OFDM符号的经历的路径衰减权重
    for nra=1:Nr 
        for nta=1:Nt
            Chan_Coef=zeros(FFT_size,1); % 时域信道冲激响应---数组
            for loop_tap=1:length(Path_Delay)  % 遍历每一条路径
                Chan_Coef(Path_Delay(loop_tap)+1) = Chan_Coef(Path_Delay(loop_tap)+1)+Fading_Weight_Repilot(loop_tap,(nra-1)*Nt+nta);
                % 遍历所有路径，将对应的**路径增益（Fading_Weight_Repilot）**累加到对应的路径延迟位置（Path_Delay）上
            end
            H_Ideal_per_Channel_All = fftshift(fft(Chan_Coef));    % h -> H, fftshift使DC居中匹配Nc_Index
            H_Ideal_All((nta-1)*Nr+nra,:,nSym) = reshape(H_Ideal_per_Channel_All,1,[]);
        end
    end
    H_Inuse_temp = H_Ideal_All(:,Nc_Index,:);                                                   % 从全频域中取出所需子载波的信道冲激响应
end
H_Inuse = H_Inuse_temp(:,:,DATA_COLUMN_INDEX);

end