# This is a mod for ICE cars exported from automation the car company tycoon game in BeamNG.drive to turn into hybrid cars or  EVs exported from the game to get a advance electric control.

# If you want to submit content containing this mod to a media platform, please indicate this repository URL.

Here is the guide for using it.

## Hybrid

 1. Export the car and cancel "Zip-Pack Mod".
    ![alt text](pictures/image1_1.png)

 2. Download the pack from GitHub.

    https://github.com/NiZhaZi/Beamng-Hybrid-Mod
    https://github.com/NiZhaZi/Hybrid-PC-Edit/releases
    https://github.com/NiZhaZi/Torque-Table-Creator/releases
    ![alt text](pictures/image2_1.png)
    ![alt text](pictures/image2_2.png)
    ![alt text](pictures/image2_3.png)

 3. Unzip the zip file from the first link of step 2. Copy all files under "hybrid" folder to the folder of exported car.

    ![alt text](pictures/image3_1.png)
    ![alt text](pictures/image3_2.png)
    ![alt text](pictures/image3_3.png)

 4. Run the .exe file downloaded from the second link. Choose the form of hybrid and click the "copy" button.

    ![alt text](pictures/image4_1.png)

 5. Open the .pc file of the car which is waiting for being modified and paste the content under "parts" part. Comment the duplicate lines. If the function is not needed, the content in the quotation marks can be deleted.

    ![alt text](pictures/image5_1.png)
    ![alt text](pictures/image5_2.png)
    ![alt text](pictures/image5_3.png)

 6. Start the game and choose the car to check if the car was modified correctly. Some parts can be exchanged in the game menu.

    ![alt text](pictures/image6_1.png)
    ![alt text](pictures/image6_2.png)

 7. The "controller" part of the "main" slot of the car can be edited like this to allow AI in the game to drive the modified car.

    ![alt text](pictures/image7_1.png)



## EV
   1. Export the car and cancel "Zip-Pack Mod".

      ![alt text](pictures/image8_1.png)

   2. Download the pack from GitHub.

      https://github.com/NiZhaZi/Beamng-Hybrid-Mod
      https://github.com/NiZhaZi/Torque-Table-Creator/releases
      ![alt text](pictures/image2_1.png)
      ![alt text](pictures/image2_3.png)

   3. Unzip the zip file from the first link of step 2. Copy all files under "EV" folder to the folder of exported car.

      ![alt text](pictures/image9_1.png)

   4. Copy the code under.

      ```
      "Camso_Engine": "Advance_Engine_ElectricController",
      // "Motor_Drive_Type": "Front_Single_Rear_None",
      // "Motor_Drive_Type": "Front_Dual_Rear_None",
      // "Motor_Drive_Type": "Front_None_Rear_Single",
      // "Motor_Drive_Type": "Front_None_Rear_Dual",
      "Motor_Drive_Type": "Front_Single_Rear_Single",
      // "Motor_Drive_Type": "Front_Single_Rear_Dual",
      // "Motor_Drive_Type": "Front_Dual_Rear_Single",
      // "Motor_Drive_Type": "Front_Dual_Rear_Dual",

      "Camso_ElectricMotor_F": "Single_ElectricMotor_F",
      // "Camso_ElectricMotor_F": "Dual_ElectricMotor_F",
      "Camso_ElectricMotor_R": "Single_ElectricMotor_R",
      //"Camso_ElectricMotor_R": "Dual_ElectricMotor_R",
      "Camso_differential_front": "Single_motor_differential_front",
      // "Camso_differential_front": "Dual_motor_differential_front",
      "Camso_differential_rear": "Single_motor_differential_rear",
      // "Camso_differential_rear": "Dual_motor_differential_rear",

      "Camso_DSE": "EV_DSE_01",
      "Camso_TC": "EV_TC",
      "Camso_ESC": "EV_ESC",
      "Camso_DriveModes": "EV_DriveModes_01",

      "Dynamic_System": "",
      "Dynamic_awd": "",
      "Dynamic_lsd": "",
      "Rear_Wheel_Steering": "",
      "Suspension_Lift": "",
      ```

   5. Open the .pc file of the car which is waiting for being modified and paste the content under "parts" part. Comment the duplicate lines. If the function is not needed, the content in the quotation marks can be deleted.

      ![alt text](pictures/image10_1.png)

   6. Start the game and choose the car to check if the car was modified correctly.

      ![alt text](pictures/image11_1.png)



## Automation Description Scriptions

   Replace the "indexNumber"s with fixtures' index number and put them into Automation game's description box to use.

   1. Steering Wheel
   ```
   ~prop:indexNumber,steering,0,1,0,0,0,0,-900,900,0,1.75~
   ```

   2. Pedals and Parking Brake (For pedals' first number, -1 represents firewall mount and 1 represents floor mount.)
   ```
   ~prop:indexNumber,throttle_input,-1,0,0,0,0,0,0,40,0,10~
   ~prop:indexNumber,brake_input,-1,0,0,0,0,0,0,40,0,10~
   ~prop:indexNumber,clutch_input,-1,0,0,0,0,0,0,40,0,10~
   ~prop:indexNumber,parkingbrake_input,1,0,0,0,0,0,0,10,0,10~
   ```
   3. Extensional Functions
   ```
   ~prop:indexNumber,hourNeedle,0,-1,0,0,0,0,0,360,0,1~
   ~prop:indexNumber,minuNeedle,0,-1,0,0,0,0,0,360,0,1~
   ~prop:indexNumber,wiper,0,-1,0,0,0,0,0,90,0,1~
   ~prop:indexNumber,wiper,0,1,0,0,0,0,0,173,0,2~
   ```