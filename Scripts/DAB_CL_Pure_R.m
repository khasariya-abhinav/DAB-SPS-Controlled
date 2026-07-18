%% =======================================================================
% Project : DAB SPS Control
%
% File : DAB_CL_Pure_R.m
%
% Description:
% MATLAB script for parameter calculation of the SPS controlled
% Dual Active Bridge converter.
%
% Author : Abhinav Khasariya
% =======================================================================

%% DAB Converter Parameters (Full Load)
Vi = 20;               % Input Voltage (V)
Vo = 100;              % Output Voltage (V)
Po = 1000;             % Rated Output Power (W)
Io = Po / Vo;          % Nominal Output Current (A)
RL = Vo / Io;          % Load Resistance (Ohms)

fsw = 100e3;           % Switching Frequency (Hz)
n = 5;                 % Transformer Turns Ratio (Nsec/Npri)
delta_V = 0.01*Vo;

D = 0.32;              % Nominal Phase Shift Ratio

phi = D*pi;            % Phase delay in radians
        
Lk = ((1-D)*D*Vi*Vo)/(2*fsw*n*Po);   % Leakage Inductance (H)

Co = Io/(fsw*delta_V);          % Output Capacitance (F)          

% Transfer Function Calculations
s = tf('s');

% 2. Load Impedance Network ZL(s)
ZL = RL/ (1 + s * (RL) * Co);       

% OL Transfer functions for I & V 
G_id_inner = ((Vi) * (1 - 2*D) / (2 * fsw * Lk * n)) * (1/RL) * ZL;   % Transfer function: Phase Shift (d) to Load Current (Io)

G_v_outer = ZL;                           % Transfer function: Injected Current (I_ref) to Output Voltage (Vo)

                                          % This assumes the inner loop is tuned to be perfectly fast.


%% =========================================================
%               PI CONTROLLERS
%% =========================================================

% Inner Current Loop Controller
Kp_i = 0.264;
Ki_i = 800.46;
C_i = Kp_i + Ki_i/s;        % Inner PI Transfer Function

% Outer Voltage Loop Controller (Placeholders to be tuned)
Kp_v = 0.00195;
Ki_v = 69.962;
C_v = Kp_v + Ki_v/s;        % Outer PI Transfer Function

%% =========================================================
%%               CLOSED-LOOP CONFIGURATIONS
%% =========================================================

% --- 1. INNER CURRENT LOOP ---
G_inner_c = C_i * G_id_inner;         % The open-loop is the controller multiplied by the plant
T_inner_cl = feedback(G_inner_c, 1);   % The closed-loop uses unity negative feedback (H=1)
Bw_rad_i = bandwidth(T_inner_cl);
Bw_hz_i = Bw_rad_i/(2*pi);

% --- 2. OUTER VOLTAGE LOOP (CASCADED) ---
 
% The outer open-loop sees its controller, multiplied by the entire

G_vi_ol = C_v * T_inner_cl * G_v_outer;   % closed inner loop, multiplied by the outer plant.

%% The final system closed-loop transfer function
Tcl = feedback(G_vi_ol, 1);
Bw_rad = bandwidth(Tcl);
Bw_Hz = Bw_rad/(2*pi);

figure('Name', 'Individual open loops for I and V', 'NumberTitle', 'off');

% Display the Bode for Open-Loop Transfer Functions
subplot(2,1,1);
margin(G_v_outer);
title('Bode Plot & Stability Margins (Outer Voltage Open Loop)');
grid on;

% 2. Check the Time-Domain Step Response of the Final Closed System
subplot(2,1,2);
margin(G_id_inner);
title('Bode Plot & Stability Margins (Inner Current Open Loop)');
grid on;


%% =========================================================
%               STABILITY & RESPONSE ANALYSIS
%% =========================================================
% Generate a figure with the Bode plots and Step Response
figure('Name', 'Casacaded OL', 'NumberTitle', 'off');

% 1. Check Phase and Gain Margins of the Outer Open Loop
margin(G_vi_ol);
title('Bode Plot & Stability Margins (Open Loop System)');
grid on;

figure('Name', 'Cascaded CL Analysis', 'NumberTitle', 'off');

subplot(2,1,1);
margin(Tcl);
title('Bode Plot & Stability Margins (Closed Loop System)');
grid on;

% 2. Check the Time-Domain Step Response of the Final Closed System
subplot(2,1,2);
step(Tcl);
title('System Step Response');
ylabel('Output Voltage (V)');
grid on;

%% Display the Transfer Functions in Command Window
fprintf('====================================\n');
fprintf(' DAB CONVERTER PARAMETERS\n');
fprintf('====================================\n');

fprintf('Input Voltage          = %.2f V\n',Vi);
fprintf('Output Voltage        = %.2f V\n',Vo);

fprintf('Switching Frequency          = %.2f V\n',fsw);
fprintf('Turn Ratio        = %.2f V\n',n);
fprintf('duty ratio          = %.2f V\n',D);
fprintf('Phase dealy in radians        = %.4f rad/s \n',phi);

fprintf('Leakage Inductance          = %.10f H\n',Lk);
fprintf('Output Capacitance        = %.6f F\n',Co);

fprintf('Bandwidth of System    =%.5f rad , %.5f Hz\n', Bw_rad, Bw_Hz);

fprintf('Bandwidth of Closed current loop    =%.5f rad , ', Bw_rad_i);
fprintf('=%.5f Hz\n', Bw_hz_i);
