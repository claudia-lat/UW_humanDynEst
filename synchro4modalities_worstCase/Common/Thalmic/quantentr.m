function xquant = quantentr(x,quantlvl)

% The function quantentr quantizes the signal x into quantlvl levels using
% a codebook defined by [0:1:quantlvl-1].
% Inputs:
% x - input signal
% quantlvl - a number of quantization levels
% Output:
% xquant - a quantized version of the input signal
% Author: Ervin Sejdic, March 4th, 2009.

xmax = max(x);
xmin = min(x);
quantstep = (xmax-xmin)/quantlvl;
partition = (xmin+quantstep):quantstep:(xmax-quantstep);
xquant = quantiz(x,partition,(0:1:quantlvl-1));
% end of function