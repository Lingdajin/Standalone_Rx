function [ E ] = Erdetermination( NL,Qm,G,C )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Name£ºErdetermination
% Input: 
%   NL: the number of transmission layers that the transport block is mapped onto
%   Qm: modulation order
%   G: the total number of coded bits available for transmission of the transport block
%   C: number of CB
% Output:
%  E: vector, the rate matching output sequence length for CBs
% Description£º
% (1) This function generates rate matching output sequence length for CBs.
% Detail:
%    
%% Modification records:
% (1) Created by zhangjingwen in 2018.3.1.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
j = 0;
for r = 1:C
    if j <= C - mod(G/(NL*Qm),C)-1
        E(r) = NL*Qm*floor(G/NL/Qm/C);
    else
        E(r) = NL*Qm*ceil(G/NL/Qm/C);
    end
    j=j+1;
end
end

