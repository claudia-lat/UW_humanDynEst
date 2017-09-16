function [X, dX, ddX, dddX, ddddX, a] = Septic(q0, dq0, ddq0, dddq0, qf, dqf, ddqf, dddqf, t)
    % 7th order line generator
    
    t0 = t(1);
    tf = t(end);
    
    Q = [1 t0   t0^2   t0^3     t0^4     t0^5      t0^6      t0^7;
         0 1  2*t0   3*t0^2   4*t0^3   5*t0^4    6*t0^5    7*t0^6;
         0 0  2      6*t0    12*t0^2  20*t0^3   30*t0^4   42*t0^5;
         0 0  0      6       24*t0    60*t0^2  120*t0^3  210*t0^4;
         1 tf   tf^2   tf^3     tf^4     tf^5      tf^6      tf^7;
         0 1  2*tf   3*tf^2   4*tf^3   5*tf^4    6*tf^5    7*tf^6;
         0 0  2      6*tf    12*tf^2  20*tf^3   30*tf^4   42*tf^5;
         0 0  0      6       24*tf    60*tf^2  120*tf^3  210*tf^4];
     
    a = Q\[q0,dq0,ddq0,dddq0,qf,dqf,ddqf,dddqf]';
%      a = inv(Q)*[q0,dq0,ddq0,qf,dqf,ddqf]';

     X = a(1) + a(2)*t + a(3)*t.^2 + a(4)*t.^3   + a(5)*t.^4    + a(6)*t.^5     + a(7)*t.^6     + a(8)*t.^7;
     dX =       a(2) + 2*a(3)*t  + 3*a(4)*t.^2 + 4*a(5)*t.^3  + 5*a(6)*t.^4   + 6*a(7)*t.^5   + 7*a(8)*t.^6;
     ddX =             2*a(3)    + 6*a(4)*t   + 12*a(5)*t.^2 + 20*a(6)*t.^3  + 30*a(7)*t.^4  + 42*a(8)*t.^5;
     dddX =                        6*a(4)     + 24*a(5)*t    + 60*a(6)*t.^2 + 120*a(7)*t.^3 + 210*a(8)*t.^4;
     ddddX =                                    24*a(5)      +120*a(6)*t    + 360*a(7)*t.^2 + 840*a(8)*t.^3;
end