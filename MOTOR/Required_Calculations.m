
%Required Values Calculations
%knowns
F_1 = 1500; %lbs
F_2 = 2500; %lbs
F_MAX = 6000;
Screw_lead = .166; %in/rev
Speed_1500 = .6;% in/s
Speed_2500 = .52;%in/s
Gear_Efficiency = .95; % 95 percent
Ball_Screw_Efficiency = .9; %9 percent 
Safety_Factor = 1.1; % 10 percent Applied at last step of caluclations
%Calculations
Actuator_Gear_Ratio_Torque = Gear_Efficiency^3 * ((75/15) * (49/26) * (48/18));
Actuator_Gear_Ratio_Speed = ((75/15) * (49/26) * (48/18));

Screw_rpm_1500 = Speed_1500/Screw_lead * 60; % RPM
Screw_rpm_2500 = Speed_2500/Screw_lead * 60; % RPM
% rpm required to move actuator at specified speeds (RPM)
Motor_rpm_1500 = Actuator_Gear_Ratio_Speed * Screw_rpm_1500;
Motor_rpm_2500 = Actuator_Gear_Ratio_Speed * Screw_rpm_2500;
% Motor torque Required to move actuator at specified load (lbf-in)
Torque_1500 =((F_1*Screw_lead) / (2*pi*Actuator_Gear_Ratio_Torque * Ball_Screw_Efficiency)); 
Torque_2500 =((F_2*Screw_lead) / (2*pi*Actuator_Gear_Ratio_Torque * Ball_Screw_Efficiency));
Torque_6000 =(F_MAX*Screw_lead) / (2*pi*Actuator_Gear_Ratio_Torque * Ball_Screw_Efficiency);

save('Required_Numbers.mat');
