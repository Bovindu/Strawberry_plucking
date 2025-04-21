/*
   Arduino based SCARA Robot 
   by Dejan, www.HowToMechatronics.com
   AccelStepper: http://www.airspayce.com/mikem/arduino/AccelStepper/index.html

*/
#include <AccelStepper.h>
#include <Servo.h>
#include <math.h>
#define ENABLE_PIN   8 

const int speed = 800; //homing speed
const int acceleration = 600; //homing acceleration

const int J2_limitSwitch = 10; // changed due to wire change
const int J3_limitSwitch = 9;// changed due to wire change
const int J1_limitSwitch = 11;  // Adjust according to your CNC shield limit switch configuration


// Define the stepper motors and the pins the will use
AccelStepper stepperJ1(AccelStepper::DRIVER, 4, 7);
AccelStepper stepperJ2(AccelStepper::DRIVER, 2, 5); // (Type:driver, STEP, DIR)
AccelStepper stepperJ3(AccelStepper::DRIVER, 3, 6);


Servo gripperServo;  // create servo object to control a servo


double x = 10.0;
double y = 10.0;
double z = 10.0;
double L1 = 140; // L1 = 228mm
double theta1, theta2, theta3;

int stepper1Position, stepper2Position, stepper3Position;
//int P_stepper1Position, P_stepper2Position, P_stepper3Position;

const float theta1AngleToSteps = 2.380952381*8; //gear ratio 90:21
const float theta2AngleToSteps = 2.380952381*4; // gear ration 90:21
const float theta3AngleToSteps = 2.380952381*8; // gear ration 90:21

byte inputValue[5];
int k = 0;

String content = "";
int data[8];

int theta1Array[100];
int theta2Array[100];
int theta3Array[100];
int gripperArray[100];
int positionsCounter = 0;

void setup() {
  pinMode(ENABLE_PIN, OUTPUT);  // Optional: For enabling the driver
  // Initialize the ENABLE pin
  digitalWrite(ENABLE_PIN, LOW);  // Optional: Set LOW to enable the driver (set HIGH to disable)
  Serial.begin(19200); // check this rate

  pinMode(J1_limitSwitch, INPUT_PULLUP);
  pinMode(J2_limitSwitch, INPUT_PULLUP);
  pinMode(J3_limitSwitch, INPUT_PULLUP);

  // Stepper motors max speed
  stepperJ1.setMaxSpeed(1000);
  stepperJ1.setAcceleration(400);
  stepperJ2.setMaxSpeed(1000);
  stepperJ2.setAcceleration(400);
  stepperJ3.setMaxSpeed(1000);
  stepperJ3.setAcceleration(400);

  gripperServo.attach(13);
  // initial servo value - open gripper
  data[2] = 0;
  data[3] = 10;
  data[4] = 90;
  data[5] = 50;
  data[6] = speed;
  gripperServo.write(90);
  delay(500);
  //data[5] = 100;
  homing();
}

void loop() { 
  //delay(2000);
  //stepperJ1.moveTo(0 * theta1AngleToSteps);
  //stepperJ1.runToPosition();
  //stepperJ3.moveTo(90 * theta3AngleToSteps);
  //stepperJ3.runToPosition();
  //stepperJ2.moveTo(45 * theta2AngleToSteps);
  //stepperJ2.runToPosition();
  //stepperJ3.moveTo(135 * theta3AngleToSteps);
  //stepperJ3.runToPosition();
    
  
  if (Serial.available()) {
    content = Serial.readString(); // Read the incomding data from Processing
    // Extract the data from the string and put into separate integer variables (data[] array)
    for (int i = 0; i < 8; i++) {
      int index = content.indexOf(","); // locate the first ","
      data[i] = atol(content.substring(0, index).c_str()); //Extract the number from start to the ","
      content = content.substring(index + 1); //Remove the number from the string
    }
    /*
     data[0] - SAVE button status
     data[1] - RUN button status
     data[2] - Joint 1 angle
     data[3] - Joint 2 angle
     data[4] - Joint 3 angle
     data[5] - Gripper value
     data[6] - Speed value
     data[7] - Acceleration value
    */
    // If SAVE button is pressed, store the data into the appropriate arrays
    
    if (data[0] == 1) {
      theta1Array[positionsCounter] = data[2] * theta1AngleToSteps; //store the values in steps = angles * angleToSteps variable
      theta2Array[positionsCounter] = data[3] * theta2AngleToSteps;
      theta3Array[positionsCounter] = data[4] * theta3AngleToSteps;
      gripperArray[positionsCounter] = data[5];
      positionsCounter++;
    }
    // clear data
    if (data[0] == 2) {
      // Clear the array data to 0
      memset(theta1Array, 0, sizeof(theta1Array));
      memset(theta2Array, 0, sizeof(theta2Array));
      memset(theta3Array, 0, sizeof(theta3Array));
      memset(gripperArray, 0, sizeof(gripperArray));
      positionsCounter = 0;
    }
  }
  // If RUN button is pressed
  while (data[1] == 1) {
    stepperJ1.setSpeed(data[6]);
    stepperJ2.setSpeed(data[6]);
    stepperJ3.setSpeed(data[6]);
    stepperJ1.setAcceleration(data[7]);
    stepperJ2.setAcceleration(data[7]);
    stepperJ3.setAcceleration(data[7]);

    // execute the stored steps
    for (int i = 0; i <= positionsCounter - 1; i++) {
      if (data[1] == 0) {
        break;
      }
      stepperJ1.moveTo(theta1Array[i]);
      stepperJ2.moveTo(theta2Array[i]);
      stepperJ3.moveTo(theta3Array[i]);
      while (stepperJ1.currentPosition() != theta1Array[i] || stepperJ2.currentPosition() != theta2Array[i] || stepperJ3.currentPosition() != theta3Array[i] ) {
        stepperJ1.run();
        stepperJ2.run();
        stepperJ3.run();
      }
      if (i == 0) {
        gripperServo.write(gripperArray[i]);
      }
      else if (gripperArray[i] != gripperArray[i - 1]) {
        gripperServo.write(gripperArray[i]);
        delay(800); // wait 0.8s for the servo to grab or drop - the servo is slow
      }

      //check for change in speed and acceleration or program stop
      if (Serial.available()) {
        content = Serial.readString(); // Read the incomding data from Processing
        // Extract the data from the string and put into separate integer variables (data[] array)
        for (int i = 0; i < 8; i++) {
          int index = content.indexOf(","); // locate the first ","
          data[i] = atol(content.substring(0, index).c_str()); //Extract the number from start to the ","
          content = content.substring(index + 1); //Remove the number from the string
        }

        if (data[1] == 0) {
          break;
        }
        // change speed and acceleration while running the program
        stepperJ1.setSpeed(data[6]);
        stepperJ2.setSpeed(data[6]);
        stepperJ3.setSpeed(data[6]);
        stepperJ1.setAcceleration(data[7]);
        stepperJ2.setAcceleration(data[7]);
        stepperJ3.setAcceleration(data[7]);
      }
    }
    
      // execute the stored steps in reverse
      for (int i = positionsCounter - 2; i >= 0; i--) {
      if (data[1] == 0) {
        break;
      }
      stepperJ1.moveTo(theta1Array[i]);
      stepperJ2.moveTo(theta2Array[i]);
      stepperJ3.moveTo(theta3Array[i]);
      while (stepperJ1.currentPosition() != theta1Array[i] || stepperJ2.currentPosition() != theta2Array[i] || stepperJ3.currentPosition() != theta3Array[i] ) {
        stepperJ1.run();
        stepperJ2.run();
        stepperJ3.run();
      }
      gripperServo.write(gripperArray[i]);

      if (Serial.available()) {
        content = Serial.readString(); // Read the incomding data from Processing
        // Extract the data from the string and put into separate integer variables (data[] array)
        for (int i = 0; i < 8; i++) {
          int index = content.indexOf(","); // locate the first ","
          data[i] = atol(content.substring(0, index).c_str()); //Extract the number from start to the ","
          content = content.substring(index + 1); //Remove the number from the string
        }
        if (data[1] == 0) {
          break;
        }
      }
      }
    
     
  }

  stepper1Position = data[2] * theta1AngleToSteps;
  stepper2Position = data[3] * theta2AngleToSteps;
  stepper3Position = data[4] * theta3AngleToSteps;

  stepperJ1.setSpeed(data[6]);
  stepperJ2.setSpeed(data[6]);
  stepperJ3.setSpeed(data[6]);

  stepperJ1.setAcceleration(data[7]);
  stepperJ2.setAcceleration(data[7]);
  stepperJ3.setAcceleration(data[7]);
  
  stepperJ1.moveTo(stepper1Position);
  stepperJ2.moveTo(stepper2Position);
  stepperJ3.moveTo(stepper3Position);

  while (stepperJ1.currentPosition() != stepper1Position || stepperJ2.currentPosition() != stepper2Position || stepperJ3.currentPosition() != stepper3Position ) {
    if (!digitalRead(J3_limitSwitch) || !digitalRead(J2_limitSwitch) || !digitalRead(J1_limitSwitch) ){
    }
    stepperJ1.run();
    stepperJ2.run();
    stepperJ3.run();
  }  
  delay(100);
  gripperServo.write(data[5]);
  delay(300); 
}

void serialFlush() {
  while (Serial.available() > 0) {  //while there are characters in the serial buffer, because Serial.available is >0
    Serial.read();         // get one character
  }
}

void homing(){
  J2_homeAxis();
  //X_positionA();
  J3_homeAxis();
  //Y_positionA();
  J1_homeAxis();
  //Z_positionA();
  stepperJ1.moveTo(0 * theta1AngleToSteps);
  stepperJ1.runToPosition();
  //P_stepper1Position = 0 * theta1AngleToSteps;
  stepperJ3.moveTo(90 * theta3AngleToSteps);
  stepperJ3.runToPosition();
  //P_stepper3Position = 90 * theta3AngleToSteps;
  stepperJ2.moveTo(10 * theta2AngleToSteps);
  stepperJ2.runToPosition();
  //P_stepper2Position = 10 * theta2AngleToSteps;
}

void J1_homeAxis() {
  // Move Z-axis motor rapidly until the limit switch is activated
  while (digitalRead(J1_limitSwitch)) {  
    stepperJ1.setSpeed(-speed);  // Move stepper rapidly in the negative direction
    stepperJ1.runSpeed();
  }
  stepperJ1.setCurrentPosition(0);
  stepperJ1.moveTo(30*8);
  stepperJ1.runToPosition();
  // Once limit switch is activated, reverse slowly until disengaging the limit
  while (digitalRead(J1_limitSwitch)) {  
    stepperJ1.setSpeed(-speed/5);  // Move stepper rapidly in the negative direction
    stepperJ1.runSpeed();
  }
  // Set the current position as zero once disengaged from the limit switch
  stepperJ1.setCurrentPosition(round(-103 * theta1AngleToSteps));//-214.285714
}

void J3_homeAxis() {
  // Move Y-axis motor rapidly until the limit switch is activated
 // Move Z-axis motor rapidly until the limit switch is activated
  while (digitalRead(J3_limitSwitch)) {  
    stepperJ3.setSpeed(speed);  // Move stepper rapidly in the negative direction
    stepperJ3.runSpeed();
  }
  stepperJ3.setCurrentPosition(0);
  stepperJ3.moveTo(-30*8);
  stepperJ3.runToPosition();
  // Once limit switch is activated, reverse slowly until disengaging the limit
  while (digitalRead(J3_limitSwitch)) {  
    stepperJ3.setSpeed(speed/5);  // Move stepper rapidly in the negative direction
    stepperJ3.runSpeed();
  }
  // Set the current position as zero once disengaged from the limit switch
 
  stepperJ3.setCurrentPosition(round(142 * theta3AngleToSteps));
}

void J2_homeAxis() {
 // Move Z-axis motor rapidly until the limit switch is activated
  while (digitalRead(J2_limitSwitch)) {  
    stepperJ2.setSpeed(-speed+300);  // Move stepper rapidly in the negative direction
    stepperJ2.runSpeed();
    if (!digitalRead(J3_limitSwitch)){
    stepperJ3.setCurrentPosition(0);
    stepperJ3.moveTo(-100*8);
    stepperJ3.runToPosition();
    }
  }
  stepperJ2.setCurrentPosition(0);
  stepperJ2.moveTo(30*8);
  stepperJ2.runToPosition();
  // Once limit switch is activated, reverse slowly until disengaging the limit
  while (digitalRead(J2_limitSwitch)) {  
    stepperJ2.setSpeed(-speed/5);  // Move stepper rapidly in the negative direction
    stepperJ2.runSpeed();
  }
  // Set the current position as zero once disengaged from the limit switch
  stepperJ2.setCurrentPosition(0);
}