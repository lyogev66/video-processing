function S_next_tag = sampleParticles(S_prev, C)
N = size(S_prev,2);
S_next_tag = zeros(size(S_prev));
%sampling each partical
for n=1:N
    r=rand(1);
    indicator = find(C>=r,1,'first');
    if ~isempty(indicator)
        S_next_tag(:,n) = S_prev(:,indicator);
    end
end
% if the value of the next S is mostly zeros take the prev one more than
% half of the matrix are zeros
    if (sum(sum(S_next_tag==0))> (6*N/2))
        S_next_tag = S_prev;
    end
end 
