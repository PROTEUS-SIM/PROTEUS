function status = odeOutputFcn(tau,~,~,T,dispProgress)
% Display progress after progressing dtplo seconds:

if dispProgress && ~isempty(tau)
    
    tplo = evalin('base','tplo');  	% Time to display progress (s)
    dtplo = evalin('base','dtplo');	% Increm. time to display progress (s)
    
    t = tau(end)*T;

    if t >= tplo
      
        % Display progress:
        disp(['t = ' num2str(tplo,'%.2e') ' s'])
        
        % Update time to display progress:
        tplo = tplo+ dtplo;
        assignin('base','tplo',tplo)    

    end

end

% Stop integration if timeout_reached is true.
status = evalin('base','timeout_reached');

end