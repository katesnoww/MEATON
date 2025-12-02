%%  Inputs
load('Required_Numbers.mat');
V = input('Enter Nominal Voltage (in V): ');    % Supply Voltage (V)
Kt_mNm = input('Enter torque constant Kt (in mNm/A): ');
Ke_V_per_krpm = input('Enter Back EMF Constant (in V/krpm): ');
I0_mA = input('Enter no-load current I0 (in mA): ');
omega_nl_rpm = input('Enter no-load speed (in rpm): ');
T_Stall = input('Enter Stall Torque  (in lbf-in), (6.34 = MAX) : ');   % torque for 6000lb of actuator load (lbf·in)
R_Phase2Phase = input('Enter Phase to Phase Resistance (in Ohms): ');
Vin = 28;
%% --- Unit Conversions ---
Nm_to_lbf_in = 8.8507;
Kt_SI = Kt_mNm * 1e-3;                % (N·m/A)
I0 = I0_mA * 1e-3;                    % (A)
Kt = Kt_SI * Nm_to_lbf_in;            % (lbf·in/A)
Ke = 1000/Ke_V_per_krpm;
%% --- Motor characteristics ---
T = linspace(0, T_Stall, 200);
I = I0 + (T ./ Kt);
omega = omega_nl_rpm * (1 - T./T_Stall);
% power Calculations
P_in = V .* I;
T_Nm = T ./ Nm_to_lbf_in;
omega_rad = (omega .*2.*pi)./60;
P_out = T_Nm .* omega_rad;
Motor_efficiency = P_out./P_in;
P_electrical = P_out ./ Motor_efficiency;

%% Ryans Model
throttle = Vin/V;
I_mot = (V - (omega ./ Ke)) / R_Phase2Phase;
n_mot = (1 - (I0./I_mot))./(1+(I_mot.*R_Phase2Phase*Ke./omega));
Pin_mot = I_mot .* V; % motor input power [W]
% --- ESC ---
% throttle = ((omega / Kv) + (I_mot * Rm)) / Vout_batt
n_esc = 1.6054 * (1 - 1 ./ (1 + 1.6519 * (throttle .^ 0.6455)));
Pin_esc = Pin_mot ./ n_esc;
P_in = Pin_mot + Pin_esc;
%



%% ============================================================
%   MOTOR PERFORMANCE ANALYSIS — 2×2 GRID (RETRACTION + EXTENSION)
%% ============================================================

figure('Position',[50 50 1200 800],'Color','w');

%% =========================
%  REQUIRED VALUES
%% =========================
T_ret  = Torque_1500;
T_ext  = Torque_2500;

RPM_ret = Motor_rpm_1500;
RPM_ext = Motor_rpm_2500;

I_limit = 20;      % updated limit
P_limit = 560;     % updated limit

% Evaluate motor values at the two required torques
I_ret  = interp1(T, I,    T_ret);
I_ext  = interp1(T, I,    T_ext);

P_ret  = interp1(T, P_in, T_ret);
P_ext  = interp1(T, P_in, T_ext);

%% ============================================================
%  SUBPLOT (1,1) — SPEED vs TORQUE (SHADE ABOVE CURVE)
%% ============================================================
subplot(2,2,1); hold on; grid on; box on;

% Motor speed curve
plot(T, omega, 'b-', 'LineWidth', 2);

% Required points
h_ret = plot(T_ret, RPM_ret, 'mo', 'MarkerSize', 8, ...
     'MarkerFaceColor','m','LineWidth',2);
h_ext = plot(T_ext, RPM_ext, 'go', 'MarkerSize', 8, ...
     'MarkerFaceColor','g','LineWidth',2);

% === SHADE REGION ABOVE MOTOR CURVE ===
x_shade = [T, fliplr(T)];
y_shade = [omega, repmat(max(omega)*1.15, 1, length(T))];

fill(x_shade, y_shade, [1 0.6 0.6], ...
     'FaceAlpha',0.2, 'EdgeColor','none');

xlabel('Torque (lbf·in)');
ylabel('Speed (rpm)');
title('Speed vs Torque');

legend({'Motor Curve','Extension Loads','Retraction Loads','Impossible to Attain Region'}, ...
       'Location','northeast');

xlim([0 T_Stall*1.1]);
ylim([0 max(omega)*1.15]);

%% ============================================================
%  SUBPLOT (1,2) — CURRENT vs TORQUE (SHADED ABOVE LIMIT=15A)
%% ============================================================
subplot(2,2,2); hold on; grid on; box on;

% Motor current curve
plot(T, I, 'b-', 'LineWidth', 2);

% Limit line
yline(I_limit,'r--','LineWidth',2);

% Required points
plot(T_ret, I_ret, 'mo', 'MarkerSize',8,'MarkerFaceColor','m');
plot(T_ext, I_ext, 'go', 'MarkerSize',8,'MarkerFaceColor','g');

% === SHADE ABOVE LIMIT ===
fill([0 T_Stall T_Stall 0], ...
     [I_limit I_limit max(I)*1.1 max(I)*1.1], ...
     [1 0.6 0.6], 'FaceAlpha',0.15, 'EdgeColor','none');

xlabel('Torque (lbf·in)');
ylabel('Current (A)');
title('Current vs Torque');

legend({'Motor Curve','Limit (15 A)','Extension Loads','Retraction Loads','Limit Exceeded Region'}, ...
       'Location','northwest');

xlim([0 T_Stall*1.05]);

%% ============================================================
%  SUBPLOT (2,1) — INPUT POWER vs TORQUE (SHADED ABOVE LIMIT=360W)
%% ============================================================
subplot(2,2,3); hold on; grid on; box on;

% Power curve
plot(T, P_in, 'b-', 'LineWidth', 2);

% Limit line
yline(P_limit,'r--','LineWidth',2);

% Required points
plot(T_ret, P_ret, 'mo','MarkerSize',8,'MarkerFaceColor','m');
plot(T_ext, P_ext, 'go','MarkerSize',8,'MarkerFaceColor','g');

% 300 W point
if any(P_in >= 500)
    T300 = interp1(P_in, T, 500);
    plot(T300, 500, 'ks','MarkerSize',10,'LineWidth',2,'MarkerFaceColor','y');
end

% 360 W point
if any(P_in >= 560)
    T360 = interp1(P_in, T, 560);
    plot(T360, 560, 'kd','MarkerSize',10,'LineWidth',2,'MarkerFaceColor','m');
end

% === SHADE ABOVE LIMIT ===
fill([0 T_Stall T_Stall 0], ...
     [P_limit P_limit max(P_in)*1.1 max(P_in)*1.1], ...
     [1 0.6 0.6], 'FaceAlpha',0.15, 'EdgeColor','none');

xlabel('Torque (lbf·in)');
ylabel('Input Power (W)');
title('Input Power vs Torque');

legend({'Motor Curve','Limit (560 W)','Extensions Loads','Retraction Loads', ...
        '500W Point','560W Point','Limit Exceeded Region'}, ...
       'Location','northwest');

xlim([0 T_Stall*1.05]);

%% ============================================================
%  SUBPLOT (2,2) — EMPTY PANEL
%% ============================================================
subplot(2,2,4);
axis off;

%% Performance Checks (Fixed to Use Your Script's Variables)

% === Required torque points ===
T_ret = Torque_1500;      % Retraction torque
T_ext = Torque_2500;      % Extension torque

% === Required speed points ===
RPM_ret = Motor_rpm_1500; % Retraction speed
RPM_ext = Motor_rpm_2500; % Extension speed

% === Evaluate power at required torques ===
P_ret = interp1(T, P_in, T_ret);   % power at retraction torque
P_ext = interp1(T, P_in, T_ext);   % power at extension torque

fprintf('\n----------------------------------------\n');
fprintf(' Input Power at Required Points:\n');
fprintf('----------------------------------------\n');

fprintf('  Retraction Point:\n');
fprintf('     Torque = %.3f lbf-in\n', T_ret);
fprintf('     Speed  = %.0f rpm\n',   RPM_ret);
fprintf('     -> Input Power = %.2f W\n\n', P_ret);

fprintf('  Extension Point:\n');
fprintf('     Torque = %.3f lbf-in\n', T_ext);
fprintf('     Speed  = %.0f rpm\n',   RPM_ext);
fprintf('     -> Input Power = %.2f W\n\n', P_ext);
