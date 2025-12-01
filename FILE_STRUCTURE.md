```
├─art
│  └─sound
│          wipers1.wav
│          wipers2.wav
│
├─lua
│  ├─common
│  └─ge
│      └─extensions
│              weatherToVe.lua
│
└─vehicles
    └─(vehicle_Name)
        │  input_actions_Advance_functions.interaction.json
        │  input_actions_Auto_control.interaction.json
        │  input_actions_AWD_control.interaction.json
        │  input_actions_DCT_idle.interaction.json
        │  input_actions_EV.interaction.json
        │  input_actions_Hybrid.interaction.json
        │  input_actions_Hybrid_brake.interaction.json
        │  input_actions_Light_control.interaction.json
        │  input_actions_REEV_control.interaction.json
        │  input_actions_Wiper.interaction.json
        │  lights.materials.json
        │
        ├─Automation
        │  │  speedlimiter.jbeam
        │  │
        │  ├─EV
        │  │  │  advance_electric_motor_controller.jbeam
        │  │  │  differential_f.jbeam
        │  │  │  differential_r.jbeam
        │  │  │  electric_motor_front.jbeam
        │  │  │  electric_motor_rear.jbeam
        │  │  │
        │  │  └─dse
        │  │          automation_dse_drivemodes_ev.jbeam
        │  │          automation_dse_esc_ev.jbeam
        │  │          automation_dse_ev.jbeam
        │  │          automation_dse_tc_ev.jbeam
        │  │
        │  └─Hybrid
        │      │  automation_transfercase.jbeam
        │      │  digidash_ev.jbeam
        │      │
        │      ├─dse
        │      │      automation_dse.jbeam
        │      │      automation_dse_drivemodes.jbeam
        │      │      automation_dse_esc.jbeam
        │      │      automation_dse_tc.jbeam
        │      │
        │      ├─gearboxs
        │      │      automatic_gearbox.jbeam
        │      │      cvt_advance_gearbox.jbeam
        │      │      cvt_gearbox.jbeam
        │      │      dct_gearbox.jbeam
        │      │      dht_gearbox.jbeam
        │      │      ecvt_gearbox.jbeam
        │      │      gear_amount.jbeam
        │      │      mt_gearbox.jbeam
        │      │      sequential_gearbox.jbeam
        │      │
        │      └─Single Motors
        │              front_motor_differential_table.jbeam
        │              motor_differential_f.jbeam
        │              motor_differential_r.jbeam
        │              rear_motor_differential_table.jbeam
        │
        ├─inputmaps
        │      keyboard_Advance_functions.json
        │      keyboard_Auto_control.json
        │      keyboard_AWD_control.json
        │      keyboard_DCT_idle.json
        │      keyboard_EV.json
        │      keyboard_Hybrid.json
        │      keyboard_Hybrid_brake.json
        │      keyboard_Light_control.json
        │      keyboard_REEV_control.json
        │      keyboard_Wiper.json
        │
        ├─jbeam_files
        │  │  AVAS.jbeam
        │  │  dctIdle.jbeam
        │  │  driveShaft.jbeam
        │  │  electricBattery.jbeam
        │  │  functions.jbeam
        │  │  hybridMain.jbeam
        │  │  rearWheelSteering.jbeam
        │  │  torqueTable.jbeam
        │  │
        │  ├─Configures
        │  │      hybridConfigures.jbeam
        │  │      hybridControlConfigures.jbeam
        │  │      motorControlConfigures.jbeam
        │  │      powerGeneratorConfigures.jbeam
        │  │      singleMotorConfigures.jbeam
        │  │
        │  └─table
        │          awdTable.jbeam
        │          frontTable.jbeam
        │          rearTable.jbeam
        │
        └─lua
            │  console.lua
            │  controller.lua
            │
            ├─controller
            │  │  advanceTurbo.lua
            │  │  dctIdle.lua
            │  │  shiftLogic-dctGearboxAdv.lua
            │  │
            │  ├─advanceEV
            │  │      evdrive.lua
            │  │      motorLimit.lua
            │  │
            │  ├─chassis
            │  │      4wsAdvance.lua
            │  │      rwsControl.lua
            │  │      suspensionLift.lua
            │  │
            │  ├─drivingDynamics
            │  │  └─supervisors
            │  │      │  HybridTC.lua
            │  │      │
            │  │      └─slipProviders
            │  │              HybridVSS.lua
            │  │
            │  ├─dynamicSys
            │  │      dynamicAWD.lua
            │  │      dynamicAWD2.lua
            │  │      dynamicLSD.lua
            │  │
            │  ├─functions
            │  │      autoControl.lua
            │  │      keyAngle.lua
            │  │      spoilerControl.lua
            │  │      vehicleInfo.lua
            │  │      wiper.lua
            │  │
            │  ├─hybrid
            │  │      eshawd.lua
            │  │      hybridControl.lua
            │  │      motorControl.lua
            │  │      powerGenerator.lua
            │  │      singleMotors.lua
            │  │
            │  ├─lightControl
            │  │      autoHeadLight.lua
            │  │      flashLight.lua
            │  │      lights.lua
            │  │      rpmLights.lua
            │  │
            │  └─vehicleController
            │      │  eVehicleController.lua
            │      │  vehicleController_original.lua
            │      │
            │      └─shiftLogic
            │              dctGearboxAdv.lua
            │
            └─powertrain
                    eatGearbox.lua
                    ectGearbox.lua
                    edtGearbox.lua
                    emtGearbox.lua
                    estGearbox.lua
                    hybridEngine.lua
                    motorShaft.lua
```