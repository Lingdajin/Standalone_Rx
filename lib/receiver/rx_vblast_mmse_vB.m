function [Detect_Out,SNR_MMSE] = rx_vblast_mmse_vB(H,Y,NoiPow)
% MMSE detection
%接收矢量先左乘G再左乘B，B的作用是将星座点归一
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check parameters
[Nr, Nt] = size(H);
if Nr<Nt
    error('BLAST requires the number of transmit antennas is larger than receive antennas.');
end
[tmp, L] = size(Y);
if tmp~=Nr
    error('input parameter size error');
end
% end of check parameters
Rn=NoiPow*diag(ones(1,Nt),0);  
%注意这块是噪声的相关阵，如果你的系统中噪声相关阵不是对角阵，或者还有用户干扰，小区间干扰的话，请注意替代。

% G = pinv(Rn+H'*H)*H';
% Detect_Out = G*Y;
% 
% PH=inv(diag(ones(1,Nt),0)+H'*H*inv(Rn));
% for nt=1:Nt
%     SNR_MMSE(nt)=1/abs(PH(nt,nt))-1;
%     B=(1+SNR_MMSE(nt))/SNR_MMSE(nt);
%     Detect_Out(nt,:)=Detect_Out(nt,:)*B;
% end
PH=pinv(NoiPow*diag(ones(1,Nt),0)+H'*H);
G = PH*H';
Detect_Out = G*Y;
for nt=1:Nt
    SNR_MMSE(nt)=1/(NoiPow)/abs(PH(nt,nt))-1;
end
for nt=1:Nt
    B=(1+SNR_MMSE(nt))/SNR_MMSE(nt);
    Detect_Out(nt,:)=Detect_Out(nt,:)*B;
end