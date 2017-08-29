
% This script could change depending on the analysis.  Hereafter an
% example on how to use it.

fig = figure();
axes1 = axes('Parent',fig,'FontSize',16);
              box(axes1,'on');
              hold(axes1,'on');
              grid on;

subplot (211) 
plot1 = plot(interpData.forces.RightFoot.value(3,:),'b','lineWidth',1.5); 
ylabel('rightFoot','HorizontalAlignment','center',...
       'FontWeight','bold',...
       'FontSize',18,...
       'Interpreter','latex');
hold on
plot2 = plot(interpData.d.links.RightFoot.extForces(3,:),'r','lineWidth',1.5);
xlim([0 size(sampling_master_time,2)])
grid on;

subplot (212) 
plot3 = plot(interpData.forces.LeftFoot.value(3,:),'b','lineWidth',1.5); 
ylabel('leftFoot','HorizontalAlignment','center',...
       'FontWeight','bold',...
       'FontSize',18,...
       'Interpreter','latex');
xlim([0 size(sampling_master_time,2)])
grid on;
% note: no plot4 of the estimated external forces on the LeftFoot because
% it is the base.  Its estimation is not supported by berdy.

leg = legend([plot1,plot2],{'human-force-provider','human-dynamics-estimator'},'Location','northeast');
set(leg,'Interpreter','latex', ...
       'Position',[0.436917552718887 0.0353846154974763 0.158803168001834 0.0237869821356598], ...
       'Orientation','horizontal');
set(leg,'FontSize',13);

% put a title on the top of the subplots
ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
text(0.5, 1,'\bf External force [N]','HorizontalAlignment','center','VerticalAlignment', 'top','FontSize',14);

