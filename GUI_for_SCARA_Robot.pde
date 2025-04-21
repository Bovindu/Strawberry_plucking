/*
   Arduino based SCARA Robot GUI
   by Dejan, www.HowToMechatronics.com AccelStepper: http://www.airspayce.com/mikem/arduino/AccelStepper/index.html

*/
import processing.serial.*;
import controlP5.*; 
import static processing.core.PApplet.*;

Serial myPort; //<>//
ControlP5 cp5; // controlP5 object

int j1Slider = 0;
int j2Slider = 0;
int j3Slider = 0;
//int zSlider = 100;
int j1JogValue = 0;
int j2JogValue = 0;
int j3JogValue = 0;
//int zJogValue = 0;
int speedSlider = 250;
int accelerationSlider = 250;
int gripperValue = 0;
int gripperAdd=0;
int positionsCounter = 0;


int saveStatus = 0;
int runStatus = 0;

int slider1Previous = 0;
int slider2Previous = 0;
int slider3Previous = 0;
//int sliderzPrevious = 100;
int speedSliderPrevious = 50;
int accelerationSliderPrevious = 50;
int gripperValuePrevious = 0;

boolean activeIK = false;

int xP=10;
int yP=150;
int zP=100;
float L1 = 140; // L1 = 228mm
//float L2 = 136.5; // L2 = 136.5mm
float h = 228.5;
float theta1, theta2, theta3;

String[] positions = new String[100];

String data;
Textlabel errorMsg;

void setup() {
  println(" start ...");
  size(960, 800);
  myPort = new Serial(this, "COM4", 19200);
  
  cp5 = new ControlP5(this);

  PFont pfont = createFont("Arial", 25, true); // use true/false for smooth/no-smooth
  ControlFont font = new ControlFont(pfont, 22);
  ControlFont font2 = new ControlFont(pfont, 25);
  
  errorMsg = cp5.addTextlabel("errorMsg")
    .setText("error messages will appear here ")
    .setPosition(10, 550) // Position it at the bottom of the window
    .setFont(font2)
    .setColorValue(color(255, 0, 0)); // Set the color to red


  //J1 controls
  cp5.addSlider("j1Slider")
    .setPosition(110, 190)
    .setSize(270, 30)
    .setRange(-90, 181) // Slider range, corresponds to Joint 1 or theta1 angle that the robot can move to
    .setColorLabel(#3269c2)
    .setFont(font)
    .setCaptionLabel("")
    ;
  cp5.addButton("j1JogMinus")
    .setPosition(110, 238)
    .setSize(90, 40)
    .setFont(font)
    .setCaptionLabel("JOG-")
    ;
  cp5.addButton("j1JogPlus")
    .setPosition(290, 238)
    .setSize(90, 40)
    .setFont(font)
    .setCaptionLabel("JOG+")
    ;
  cp5.addNumberbox("j1JogValue")
    .setPosition(220, 243)
    .setSize(50, 30)
    .setRange(0, 20)
    .setFont(font)
    .setMultiplier(0.1)
    .setValue(1)
    .setDirection(Controller.HORIZONTAL) // change the control direction to left/right
    .setCaptionLabel("")
    ;

  //J2 controls
  cp5.addSlider("j2Slider")
    .setPosition(110, 315)
    .setSize(270, 30)
    .setRange(0, 135)
    .setColorLabel(#3269c2)
    .setFont(font)
    .setCaptionLabel("")
    ;
  cp5.addButton("j2JogMinus")
    .setPosition(110, 363)
    .setSize(90, 40)
    .setFont(font)
    .setCaptionLabel("JOG-")
    ;
  cp5.addButton("j2JogPlus")
    .setPosition(290, 363)
    .setSize(90, 40)
    .setFont(font)
    .setCaptionLabel("JOG+")
    ;
  cp5.addNumberbox("j2JogValue")
    .setPosition(220, 368)
    .setSize(50, 30)
    .setRange(0, 20)
    .setFont(font)
    .setMultiplier(0.1)
    .setValue(1)
    .setDirection(Controller.HORIZONTAL) // change the control direction to left/right
    .setCaptionLabel("")
    ;
  //J3 controls
  cp5.addSlider("j3Slider")
    .setPosition(110, 440)
    .setSize(270, 30)
    .setRange(33, 180)
    .setColorLabel(#3269c2)
    .setFont(font)
    .setCaptionLabel("")
    ;
  cp5.addButton("j3JogMinus")
    .setPosition(110, 493)
    .setSize(90, 40)
    .setFont(font)
    .setCaptionLabel("JOG-")
    ;
  cp5.addButton("j3JogPlus")
    .setPosition(290, 493)
    .setSize(90, 40)
    .setFont(font)
    .setCaptionLabel("JOG+")
    ;
  cp5.addNumberbox("j3JogValue")
    .setPosition(220, 493)
    .setSize(50, 30)
    .setRange(0, 20)
    .setFont(font)
    .setMultiplier(0.1)
    .setValue(1)
    .setDirection(Controller.HORIZONTAL) // change the control direction to left/right
    .setCaptionLabel("")
    ;


  cp5.addTextfield("xTextfield")
    .setPosition(530, 205)
    .setSize(70, 40)
    .setFont(font)
    .setColor(255)
    .setCaptionLabel("")
    ;
  cp5.addTextfield("yTextfield")
    .setPosition(680, 205)
    .setSize(70, 40)
    .setFont(font)
    .setColor(255)
    .setCaptionLabel("")
    ;
  cp5.addTextfield("zTextfield")
    .setPosition(830, 205)
    .setSize(70, 40)
    .setFont(font)
    .setColor(255)
    .setCaptionLabel("")
    ;

  cp5.addButton("move")
    .setPosition(590, 315)
    .setSize(240, 45)
    .setFont(font)
    .setCaptionLabel("MOVE TO POSITION")
    ;

  cp5.addButton("savePosition")
    .setPosition(470, 520)
    .setSize(215, 50)
    .setFont(font2)
    .setCaptionLabel("SAVE POSITION")
    ;

  cp5.addButton("run")
    .setPosition(725, 520)
    .setSize(215, 50)
    .setFont(font2)
    .setCaptionLabel("RUN PROGRAM")
    ;

  cp5.addButton("updateSA")
    .setPosition(760, 590)
    .setSize(150, 40)
    .setFont(font)
    .setCaptionLabel("(Update)")
    ;

  cp5.addButton("clearSteps")
    .setPosition(490, 650)
    .setSize(135, 40)
    .setFont(font)
    .setCaptionLabel("(CLEAR)")
    ;

  cp5.addSlider("accelerationSlider")
    .setPosition(720, 740)
    .setSize(180, 30)
    .setRange(10, 500)
    .setColorLabel(#3269c2)
    .setFont(font)
    .setCaptionLabel("")
    ;
   cp5.addSlider("speedSlider")
    .setPosition(490, 740)
    .setSize(180, 30)
    .setRange(10, 500)
    .setColorLabel(#3269c2)
    .setFont(font)
    .setCaptionLabel("")
    ;
  cp5.addSlider("gripperValue")
    .setPosition(605, 445)
    .setSize(190, 30)
    .setRange(0, 180)
    .setColorLabel(#3269c2)
    .setFont(font)
    .setCaptionLabel("")
    ;
}

void draw() { 
  background(#F2F2F2); // background black
  textSize(26);
  fill(33);
  text("Forward Kinematics", 120, 135); 
  text("Inverse Kinematics", 590, 135); 
  textSize(40);
  text("SCARA Robot Control", 260, 60); 
  textSize(45);
  text("J1", 35, 250); 
  text("J2", 35, 375);
  text("J3", 35, 500);
  //text("Z", 35, 625);
  textSize(22);
  text("Speed", 545, 730);
  text("Acceleration", 745, 730);

  //println("PREV: "+accelerationSlider);
  fill(speedSlider);
  fill(accelerationSlider);
  fill(j1Slider);
  fill(j2Slider);
  fill(j3Slider);
  //fill(zSlider);
  fill(j1JogValue);
  fill(j2JogValue);
  fill(j3JogValue);
  //fill(zJogValue);
  fill(gripperValue);


  //updateData();
  //println(data);

  saveStatus=0; // keep savePosition variable 0 or false. See, when button SAVE pressed it makes the value 1, which indicates to store the value in the arduino code

  // If slider moved, calculate new position of X,Y and Z with forward kinematics
  if (slider1Previous != j1Slider) {
    if (activeIK == false) {     // Check whether the inverseKinematics mode is active, Executre Forward kinematics only if inverseKinematics mode is off or false
      theta1 = round(cp5.getController("j1Slider").getValue()); // get the value from the slider1
      theta2 = round(cp5.getController("j2Slider").getValue());
      theta3 = round(cp5.getController("j3Slider").getValue());
      float Beta1 = theta3 - theta2;
      if (Beta1 > 40 &&  Beta1 < 145){
        forwardKinematics();
        updateData();
        println(data);
        myPort.write(data);
        errorMsg.setText("");
      }
      else{
        errorMsg.setText("ERROR : Arm 3 cant Reach Beta = "+Beta1);
      }
      
    }
  }
  slider1Previous = j1Slider;

  if (slider2Previous != j2Slider) {
    if (activeIK == false) {     // Check whether the inverseKinematics mode is active, Executre Forward kinematics only if inverseKinematics mode is off or false
      theta1 = round(cp5.getController("j1Slider").getValue()); // get the value from the slider1
      theta2 = round(cp5.getController("j2Slider").getValue());
      theta3 = round(cp5.getController("j3Slider").getValue());
      float Beta2 = theta3 - theta2;
      if (Beta2 > 40 &&  Beta2 < 145){
        forwardKinematics();
        updateData();
        println(data);
        myPort.write(data);
        errorMsg.setText("");
      }
      else{
        errorMsg.setText("ERROR : Arm 3 cant Reach Beta = " +Beta2);
      }
      
    }
  }
  slider2Previous = j2Slider;

  if (slider3Previous != j3Slider) {
    if (activeIK == false) {     // Check whether the inverseKinematics mode is active, Executre Forward kinematics only if inverseKinematics mode is off or false
      theta1 = round(cp5.getController("j1Slider").getValue()); // get the value from the slider1
      theta2 = round(cp5.getController("j2Slider").getValue());
      theta3 = round(cp5.getController("j3Slider").getValue());
      float Beta3 = theta3 - theta2;
      if (Beta3 > 40 &&  Beta3 < 145){
        forwardKinematics();
        updateData();
        println(data);
        myPort.write(data);
        errorMsg.setText("");
      }
      else{
        errorMsg.setText("ERROR : Arm 3 cant Reach, Beta = " +Beta3);
      }
      
    }
  }
  slider3Previous = j3Slider;

  if (gripperValuePrevious != gripperValue) {
    if (activeIK == false) {     // Check whether the inverseKinematics mode is active, Executre Forward kinematics only if inverseKinematics mode is off or false
      gripperAdd = round(cp5.getController("gripperValue").getValue());
      gripperValue=gripperAdd;
      updateData();
      println(data);
      myPort.write(data);
    }
  }
  gripperValuePrevious = gripperValue;
  activeIK = false; // deactivate inverseKinematics so the above if statements can be executed the next interation

  fill(33);
  textSize(32);
  text("X: ", 500, 290);
  text(xP, 533, 290);
  text("Y: ", 650, 290);
  text(yP, 685, 290);
  text("Z: ", 800, 290);
  text(zP, 835, 290);
  textSize(26);
  text("Gripper", 650, 420);
  text("OPEN", 510, 470);
  text("CLOSE", 810, 470);
  textSize(18);

  if (positionsCounter >0 ) {
    text(positions[positionsCounter-1], 460, 630);
    text("Last saved position: No."+(positionsCounter-1), 460, 600);
  } else {
    text("Last saved position:", 460, 600);
    text("None", 460, 630);
  }
}

 // FORWARD KINEMATICS
void forwardKinematics() {
  float theta1F = theta1 * PI / 180;   // degrees to radians
  float theta2F = theta2 * PI / 180;
  float theta3F = theta3 * PI / 180;
  float x = 2 * L1 * cos((theta3F - theta2F)/2) * sin((theta3F + theta2F)/2) * cos (theta1F);
  float y = 2 * L1 * cos((theta3F - theta2F)/2) * sin((theta3F + theta2F)/2) * sin (theta1F);
  float z = h + 2*L1* cos((theta3F - theta2F)/2) * cos((theta3F + theta2F)/2);
  xP = round(x + 20 * cos(theta1F));
  yP = round(y + 20 * sin(theta1F));
  zP = round (z - 74);
}

 // INVERSE KINEMATICS
void inverseKinematics(float x, float y, float z) {
  println ("running inverse kinamatics");
  float temp1 = x /(sqrt(sq(x) + sq(y)));
  theta1 = acos(temp1);
  if (temp1 < -1 || temp1 > 1) {
    println("Theta1 out of bounds");
    errorMsg.setText("Theta1 out of bounds");
    println ("temp1: "+temp1);
    theta1 = 0;
  }
  else {
    println ("temp1: "+temp1);
    theta1 = acos(temp1);
    println ("theta1: "+theta1*180/PI);
  }
  x= x - 20 * cos(theta1);
  y= y - 20 * sin(theta1);
  z= z + 74;
  
  float shi = 0.0;
  float temp2 = (0.5/L1) * sqrt(sq(x) + sq(y) + sq(z-h));
  if (temp2 < -1 || temp2 > 1) {
    println("Theta2 and Theta3 out of bounds");
    errorMsg.setText("Theta2 and Theta3 out of bounds");
    println ("temp2: "+temp2);
    theta2 = 0;
    theta3 = PI/2;
  }
  else {
    shi = acos(temp2);
    float phi = 0.0;
    float temp3 = (z-h)/sqrt(sq(x) + sq(y));
    phi = atan(temp3);
    theta2 = PI/2 - shi - phi;
    theta3 = theta2 + 2 * shi;
    println ("theta2: "+theta2);
    println ("theta: "+theta3);
    errorMsg.setText(""); // Clear error message if values are within bounds
  }
  
  theta3 = theta3 * 180 / PI;
  theta2 = theta2 * 180 / PI;
  theta1 = theta1 * 180 / PI;

 // Angles adjustment depending in which quadrant the final tool coordinate x,y is
  
  if (x < 0 & y < 0) {       // 3d quadrant
    theta1 = 180 + theta1;
  }
  if (x > 0 & y < 0) {       // 4th quadrant
    theta1 = -theta1;
  }

  theta1=round(theta1);
  theta2=round(theta2);
  theta3=round(theta3);
  
  cp5.getController("j1Slider").setValue(theta1);
  cp5.getController("j2Slider").setValue(theta2);
  cp5.getController("j3Slider").setValue(theta3);
}

void controlEvent(ControlEvent theEvent) {  

  if (theEvent.isController()) { 
    println(theEvent.getController().getName());
  }
}

public void xTextfield(String theText) {
  //If we enter a value into the Textfield, read the value, convert to integer, set the inverseKinematics mode active
  xP=Integer.parseInt(theText);
  activeIK = true;
  inverseKinematics(xP, yP, zP); // Use inverse kinematics to calculate the J1(theta1), J2(theta2), and J3(phi) positions
  //activeIK = false;
  println("Test; x: "+xP+" y: "+yP+ " z: "+zP);
  println("Test; theta1: "+theta1+" theta2: "+theta2+ "theta3: "+theta3);
}
public void yTextfield(String theText) {
  yP=Integer.parseInt(theText);
  activeIK = true;
  inverseKinematics(xP, yP, zP);
  //activeIK = false;
  println("Test; x: "+xP+" y: "+yP+ " z: "+zP);
  println("Test; theta1: "+theta1+" theta2: "+theta2+ "theta3: "+theta3);
}
public void zTextfield(String theText) {
  zP=Integer.parseInt(theText);
  activeIK = true;
  inverseKinematics(xP, yP, zP);
  println("Test; x: "+xP+" y: "+yP+ " z: "+zP);
  println("Test; theta1: "+theta1+" theta2: "+theta2+ "theta3: "+theta3);
}

public void j1JogMinus() {
  int a = round(cp5.getController("j1Slider").getValue());
  a=a-j1JogValue;
  cp5.getController("j1Slider").setValue(a);
}
//J1 control
public void j1JogPlus() {
  int a = round(cp5.getController("j1Slider").getValue());
  a=a+j1JogValue;
  cp5.getController("j1Slider").setValue(a);
}
//J2 control
public void j2JogMinus() {
  int a = round(cp5.getController("j2Slider").getValue());
  a=a-j2JogValue;
  cp5.getController("j2Slider").setValue(a);
}
public void j2JogPlus() {
  int a = round(cp5.getController("j2Slider").getValue());
  a=a+j2JogValue;
  cp5.getController("j2Slider").setValue(a);
}
//J3 control
public void j3JogMinus() {
  int a = round(cp5.getController("j3Slider").getValue());
  a=a-j3JogValue;
  cp5.getController("j3Slider").setValue(a);
}
public void j3JogPlus() {
  int a = round(cp5.getController("j3Slider").getValue());
  a=a+j3JogValue;
  cp5.getController("j3Slider").setValue(a);
}

public void move() {

  myPort.write(data);
  println(data);
}

public void savePosition() {
  // Save the J1, J2, J3 position in the array 
  theta1 = round(cp5.getController("j1Slider").getValue()); // get the value from the slider1
  theta2 = round(cp5.getController("j2Slider").getValue());
  theta3 = round(cp5.getController("j3Slider").getValue());
  float Beta0 = theta3 - theta2;
  if (Beta0 > 40 &&  Beta0 < 145){
   positions[positionsCounter]="J1="+str(round(cp5.getController("j1Slider").getValue()))
    +"; J2=" + str(round(cp5.getController("j2Slider").getValue()))
    +"; J3="+str(round(cp5.getController("j3Slider").getValue()));
  positionsCounter++;
  saveStatus = 1;
  updateData();
  myPort.write(data);
  saveStatus=0;
  }
  else{
        errorMsg.setText("ERROR : Arm 3 cant Reach, Beta = " +Beta0);
      }
  
}

public void run() {

  if (runStatus == 0) {
    cp5.getController("run").setCaptionLabel("STOP");
    cp5.getController("run").setColorLabel(#e74c3c);

    runStatus = 1;
  } else if (runStatus == 1) {
    runStatus = 0;
    cp5.getController("run").setCaptionLabel("RUN PROGRAM");
    cp5.getController("run").setColorLabel(255);
  }
  updateData();
  myPort.write(data);
}
public void updateSA() {
  myPort.write(data);
}
public void clearSteps() {
  saveStatus = 2; // clear all steps / program
  updateData();
  myPort.write(data);
  println("Clear: "+data);
  positionsCounter=0;
  saveStatus = 0;
}

public void updateData() {
  data = str(saveStatus)
    +","+str(runStatus)
    +","+str(round(cp5.getController("j1Slider").getValue())) 
    +","+str(round(cp5.getController("j2Slider").getValue()))
    +","+str(round(cp5.getController("j3Slider").getValue()))
    +","+str(gripperValue)
    +","+str(speedSlider)
    +","+str(accelerationSlider);
}
