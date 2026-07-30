%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Output parameters:
        % H_Innse: frequency domaion H, with size m*n*p, and:
                % m: Pilot_port*Nr;
                % n: used subcarrier index;
                % p: OFDM symbol index of data region.
    % Modified in 2012.3 based on previous CE.
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ H_Inuse ] = expPDP_CE(Pilot_port,Nr,Nd,Nc_used,PILOT_COLUMN_INDEX,DATA_COLUMN_INDEX,FFT_Out_Pilot,M_expPDP)

for nra=1:Nr
    for nta = 1:Pilot_port
        PILOT_COLUMN_INDEX_temp = PILOT_COLUMN_INDEX(nta,~isnan(PILOT_COLUMN_INDEX(nta,:)));    % 除去PILOT_COLUMN_INDEX中设置的NaN
        P_ns = length(PILOT_COLUMN_INDEX_temp);                                                 % P_ns:导频所占符号数
        H_est = zeros(Nc_used,P_ns);
        for np = 1:P_ns
            H_est(:,np)=squeeze(M_expPDP(nra,nta,np,:,:))* squeeze(FFT_Out_Pilot(nra,nta,:,np));
        end
       
        if size(H_est,2) == 1
            Pilot_Ant_Pair=repmat(H_est,1,Nd);                                                      % 时域只有一列时，重复插值
        else
            Pilot_Ant_Pair=interp1(PILOT_COLUMN_INDEX_temp,H_est.',[1:Nd],'linear','extrap').';     % 时域不止一列时，线性插值
        end
        H_Inuse((nta-1)*Nr+nra,:,:) = Pilot_Ant_Pair(:,DATA_COLUMN_INDEX);                          % 取出数据列信道冲激响应
    end
end