%Demo read data script

%Add path to all the needed classes
addpath([pwd '\Classes']);

%Load up IMU data using imuDataHandle Class
imu_header_path = 'E:\SensorCalibration\0006667D713A_navid_allimudata.header';
imu = arsLoader(imu_header_path);

%Plot IMU gyroscope and accelerometer function
imu.plot();


%Access Calibrated Data values 
imu.accelerometerCalibrated;
imu.gyroscopeCalibrated;

%Access time, note it starts at system time so offset by imu.time(1)
%For example plot integral of gyro
figure(1);
plot(imu.time-imu.time(1),rad2deg(cumtrapz(imu.time,imu.gyroscopeCalibrated)));

%Load up motion capture data
mocap_trc_path = 'E:\SensorCalibration\navid_ALLIMUDATA_1_smooth.trc';
trc = readTrc(mocap_trc_path);
%To access actual marker data use trc.data.{Marker Name}
%For example plot topleft marker
%NOTE MARKER DATA IS IN MM not METERS 
figure(3);
clf
plot(trc.data.Time,trc.data.TopLeft);
title('Mocap TopLeft position')
xlabel('Time');
ylabel('Position (mm)')

%Function to compute rotation matrix based on 3 markers
N = size(trc.data.Frame,1);

%Cameras sample at 200Hz imu at 50Hz so take every 4rth camera sample 
N = size(trc.data.Frame,1);
topLeft = reshape(smooth((trc.data.TopLeft')',5,'lowess'),N,[]);
topLeft = topLeft(1:4:end,:)/1000;
bottomRight = reshape(smooth((trc.data.BottomRight')',5,'lowess'),N,[]);
bottomRight = bottomRight(1:4:end,:)/1000;
bottomLeft = reshape(smooth((trc.data.BottomLeft')',5,'lowess'),N,[]);
bottomLeft = bottomLeft(1:4:end,:)/1000;
top = bottomRight;
mid = bottomLeft;
right = topLeft;

P = right; %Q->P = x-axis
Q = mid;  %crossProd(x-axis, Q->R) = z-axis
R = top;     %crossProd(x-axis, z-axis) = Q->R = y-axis
[R_imu_0, R_0_imu] = points2rot(P,Q,R);

%Calculate gravity as seen by the platform based on the rotation of the
%three markers
%Calculate Expected Gravity
mocap_accel = zeros(size(R_imu_0,3),3);
for i=1:size(R_0_imu,3)
    mocap_accel(i,:) = R_0_imu(:,:,i)*[0;0;9.8061];
end
figure(4);
clf
plot(mocap_accel)
hold on
plot(imu.accelerometerCalibrated,'--')
title('Platform Accel and IMU Accel');

%What we really want is to go from imu.accelerometerCalibrated -> R_0_imu
%We can convert rotation matrix to euler angles using rotm2eul(R)


