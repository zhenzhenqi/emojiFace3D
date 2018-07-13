import controlP5.*;
import peasy.*;
import SimpleOpenNI.*;
import processing.video.*;

static int EMOJI_COUNT = 3;

SimpleOpenNI context;
Movie myMovie;
ControlP5 cp5;

ArrayList < PShape > emojis = new ArrayList < PShape > ();
ArrayList < KinectUser > kusers = new ArrayList < KinectUser > ();
PVector headPosition = new PVector();
PVector shoulderLeftJointPos = new PVector();
PVector shoulderRightJointPos = new PVector();
PVector neckPos = new PVector();

int[] userMap;

float zoomF = 0.5f;
float rotX = radians(180); // by default rotate the hole scene 180deg around the x-axis, 
// the data from openni comes upside down
float rotY = radians(0);

PVector bodyCenter = new PVector();
PVector bodyDir = new PVector();
PVector com = new PVector();
PVector com2d = new PVector();

float camera_adjust_x;
float camera_adjust_y;
float camera_adjust_scale;

// tested values: make depth map and rgb image match
// for background removal stuff
float color_scaler = 0.67;
float depth_scaler = 1.88;
float depth_offset_x = 195.8;
float depth_offset_y = -31;


float user_draw_x_offset=0;

PeasyCam cam;

////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
/////////////////////  S E T U P ///////////////////////////////////////
////////////////////////////////////////////////////////////

void setup() {
  size(1280, 720, P3D); 
  //cam = new PeasyCam(this, 100);

  //controlp5
  cp5 = new ControlP5(this);
  //cp5.setAutoDraw(false);
  cp5.addSlider("user_draw_x_offset").setRange(-500, 500).setSize(900, 10).linebreak();
  //cp5.addSlider("

  context = new SimpleOpenNI(this);
  if (context.isInit() == false) {
    println("Can't init SimpleOpenNI, maybe the camera is not connected!");
    exit();
    return;
  }

  context.setMirror(false);
  context.enableDepth();
  context.enableUser();
  context.enableRGB();
  perspective(radians(45), float(width) / float(height), 10, 150000);

  // maskedRGB = new PImage(640, 480, RGB);

  myMovie = new Movie(this, "Psychedelic Geometry Vj Loop-HD.mp4");
  myMovie.loop();
  //myMovie.play();

  //load emoji obj
  println("start loading emoji obj");
  String path = sketchPath("data/");
  File theDir = new File(path);
  String[] theList = theDir.list();
  for (int i = 0; i < theList.length - 1; i++) {
    if (theList[i].contains(".obj")) {
      emojis.add(loadShape(theList[i]));
      if (emojis.size() > EMOJI_COUNT) {
        break;
      }
      println("loaded " + i );
    }
  }
  println("finish loading obj files");
}

////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
//////////////////////// D R A W ////////////////////////////////////
////////////////////////////////////////////////////////////

void draw() {
  background(255);

  //beginCamera();
  //camera();

  //setup lighting for better 3d model viewing
  directionalLight(200, 200, 200, 0.5, -0.5, 1);
  ambientLight(100, 100, 100);

  ////////////////////////////////////////////////////////////
  ////////////////////// background removal stuff ////////////////////////////////////////////


  //update kinect data
  context.update();
  //get usermap for background removal
  userMap = context.userMap();
  //draw movie 
  image(myMovie, 0, 0);
  PImage noBgImg =  backgroundRemoval(context.userMap(), context.rgbImage().get());
  //draw user without background
  
  //todo: adjust   user_draw_x_offset   to match 3d models
  image(noBgImg, user_draw_x_offset, 0);


  ////////////////////////////////////////////////////////////
  ///////////////////////  draw 3d models /////////////////////////////////////

  //hack coordinates to match screen views

  pushMatrix();
  pushStyle();
  translate(width / 2, height / 2, 0);
  rotateX(rotX);
  rotateY(rotY);
  scale(zoomF);
  translate(0, 0, -1000); 


  int[] userList = context.getUsers();
  for (int i = 0; i < userList.length; i++) {

    drawSkeleton(i);

    context.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_HEAD, headPosition);
    context.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_LEFT_SHOULDER, shoulderLeftJointPos);
    context.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_RIGHT_SHOULDER, shoulderRightJointPos);
    context.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_NECK, neckPos);

    pushMatrix();

    translate(headPosition.x, headPosition.y, headPosition.z);
    rotateY(((PI / 2) * (shoulderLeftJointPos.z - shoulderRightJointPos.z)) / 200);
    fill(0, 235);
    stroke(200);
    strokeWeight(1);
    stroke(0, 0);
    hint(DISABLE_DEPTH_TEST);
    if (userList.length != 0 && headPosition.z != 0) {
      scale(210);
      for (int po = 0; po < kusers.size(); po++) {
        if (kusers.get(po).id == i + 1) {
          shape(emojis.get(kusers.get(po).emojiIndex));
          //box(1);
        }
      }
    }
    hint(ENABLE_DEPTH_TEST);
    popMatrix();
  }

  popStyle();
  popMatrix();

  //endCamera();
}




// draw the skeleton with the selected joints
void drawSkeleton(int userId) {
  strokeWeight(3);
  // to get the 3d joint data
  drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);
  drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);

  drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);

  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);

  drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);

  drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);
  // draw body direction
  //getBodyDirection(userId, bodyCenter, bodyDir);
  //bodyDir.mult(200); // 200mm length
  //bodyDir.add(bodyCenter);
}

// -----------------------------------------------------------------
// SimpleOpenNI user events




void onNewUser(SimpleOpenNI curContext, int userId) {
  println("onNewUser - userId: " + userId);
  println("\tstart tracking skeleton");

  context.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI curContext, int userId) {
  for (int i = 0; i < kusers.size(); i++) {
    if (kusers.get(i).id == userId) {
      kusers.remove(i);
    }
  }
  println("onLostUser - userId: " + userId);
}

void onVisibleUser(SimpleOpenNI curContext, int userId) {
  //println("onVisibleUser - userId: " + userId);
  kusers.add(new KinectUser(userId, floor(random(0, emojis.size()))));
}


void getBodyDirection(int userId, PVector centerPoint, PVector dir) {
  PVector jointL = new PVector();
  PVector jointH = new PVector();
  PVector jointR = new PVector();
  float confidence;

  // draw the joint position
  confidence = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, jointL);
  confidence = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_HEAD, jointH);
  confidence = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, jointR);

  // take the neck as the center point
  confidence = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_NECK, centerPoint);


  PVector up = PVector.sub(jointH, centerPoint);
  PVector left = PVector.sub(jointR, centerPoint);

  dir.set(up.cross(left));
  dir.normalize();
}

void keyPressed() {
}

void movieEvent(Movie m) {
  m.read();
}
