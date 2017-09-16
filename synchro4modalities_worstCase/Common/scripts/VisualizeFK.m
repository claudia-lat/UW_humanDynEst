% load and visualize
cd C:\Documents\aslab\projects\jf2lin\APARS\EKF_Vlad

%% Load model 
model = CModel.load('Models/Lower_Body.xml');

T = transl(0.05,0.05,0);
T(1:3,1:3) = rotz(-pi/2)*rotx(-pi/2);
sensor_knee = SensorCore('knee_sens');
model.addSensor(sensor_knee,'rknee0',T);

T = transl(0.05,0.05,0);
T(1:3,1:3) = rotz(-pi/2)*rotx(-pi/2);
sensor_ankle = SensorCore('knee_sens');
model.addSensor(sensor_ankle,'rankle0',T);

model.forwardKinematics();

%%
% Finally we visualize the model
%Create Visualizer Visualizer(name,width,height)
vis = Visualizer('vis',640,480);
%Add the model to the visualizer, note sensors must be attached before
%adding the model to visualizer or it will not display them
vis.addModel(model);

%%
% model.position = [0 0 0 -pi/2 0 0]';
model.position(1:5) = [0 0 0 0 0];
model.position(1:5) = [-2.06 0 0 2.74 0];
model.position(1:5) = [-0.4 0 0 1.8 0];
model.forwardKinematics();
%Must update visualizer to properly display model
vis.update();

%%
% clear vis;