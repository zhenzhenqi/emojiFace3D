import SimpleOpenNI.*;
import processing.video.*;


static int EMOJI_COUNT = 3;



Movie myMovie;

PVector head_position = new PVector();
PVector Shoulder_left_jointPos = new PVector();
PVector Shoulder_right_jointPos = new PVector();
PVector neck_jointPos = new PVector();
boolean handsTrackFlag = false;
PVector handVec = new PVector();

int[] userMap;

SimpleOpenNI context;
float zoomF = 0.5f;
float rotX = radians(180); // by default rotate the hole scene 180deg around the x-axis, 
// the data from openni comes upside down
float rotY = radians(0);
boolean autoCalib = true;

PVector bodyCenter = new PVector();
PVector bodyDir = new PVector();
PVector com = new PVector();
PVector com2d = new PVector();

float camera_adjust_x, camera_adjust_y, camera_adjust_scale;


color[] userClr = new color[] {
  color(255, 0, 0), 
  color(0, 255, 0), 
  color(0, 0, 255), 
  color(255, 255, 0), 
  color(255, 0, 255), 
  color(0, 255, 255)
};




ArrayList < PShape > emojis = new ArrayList < PShape > ();
ArrayList < KinectUser > kusers = new ArrayList < KinectUser > ();

float color_scaler = 0.67;
float depth_scaler = 1.88;
float depth_offset_x = 195.8;
float depth_offset_y = -31;


void setup() {
  size(1280, 720, P3D); // strange, get drawing error in the cameraFrustum if i use P3D, in opengl there is no problem
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

void draw() {
  // update the cam
  context.update();

  image(myMovie, 0, 0);
  PImage noBgImg =  backgroundRemoval(context.userMap(), context.rgbImage().get());
  image(noBgImg, 0, 0);


  PVector myPositionScreenCoords = new PVector(); //storage device
  //convert the weird kinect coordinates to screen coordinates.
  context.convertRealWorldToProjective(handVec, myPositionScreenCoords);

  pushMatrix();

  translate(-600, -500, -1000);
  scale(3);

  int[] userList = context.getUsers();

  popMatrix();

  // set the scene pos
  translate(width / 2, height / 2, 0);
  rotateX(rotX);
  rotateY(rotY);
  scale(zoomF);

  translate(0, 0, -1000); // set the rotation center of the scene 1000 infront of the camera



  // draw the skeleton if it's available
  userMap = context.userMap();

  for (int i = 0; i < userList.length; i++) {

    if (context.isTrackingSkeleton(userList[i]))
      drawSkeleton(userList[i]);


    float confident;
    confident = context.getJointPositionSkeleton(userList[i], 
      SimpleOpenNI.SKEL_HEAD, head_position);
    confident = context.getJointPositionSkeleton(userList[i], 
      SimpleOpenNI.SKEL_LEFT_SHOULDER, Shoulder_left_jointPos);
    confident = context.getJointPositionSkeleton(userList[i], 
      SimpleOpenNI.SKEL_RIGHT_SHOULDER, Shoulder_right_jointPos);
    confident = context.getJointPositionSkeleton(userList[i], 
      SimpleOpenNI.SKEL_NECK, neck_jointPos);

    pushMatrix();
    translate(head_position.x, head_position.y, head_position.z);
    rotateY(((PI / 2) * (Shoulder_left_jointPos.z - Shoulder_right_jointPos.z)) / 200);
    fill(0, 235);
    stroke(200);
    strokeWeight(1);
    stroke(0, 0);

    directionalLight(200, 200, 200, 0.5, -0.5, 1);

    //    pointLight(200, 200, 200, width/2, 2000, 1500);
    //    lights();
    ambientLight(100, 100, 100);

    if (userList.length != 0 && head_position.z != 0) {
      scale(210);
      for (int po = 0; po < kusers.size(); po++) {

        if (kusers.get(po).id == i + 1) {
          //          println("confirm");
          shape(emojis.get(kusers.get(po).emojiIndex));
        }
      }
    }

    popMatrix();
  }
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
  getBodyDirection(userId, bodyCenter, bodyDir);
  bodyDir.mult(200); // 200mm length
  bodyDir.add(bodyCenter);
  strokeWeight(1);
}

void drawLimb(int userId, int jointType1, int jointType2) {
  PVector jointPos1 = new PVector();
  PVector jointPos2 = new PVector();
  float confidence;



  // draw the joint position
  confidence = context.getJointPositionSkeleton(userId, jointType1, jointPos1);
  confidence = context.getJointPositionSkeleton(userId, jointType2, jointPos2);

  //pass the positions to our cubes' PVectors


  if (jointType1 == SimpleOpenNI.SKEL_LEFT_SHOULDER) {
    Shoulder_left_jointPos = jointPos1;
  }

  if (jointType1 == SimpleOpenNI.SKEL_RIGHT_SHOULDER) {
    Shoulder_right_jointPos = jointPos1;
  }

  if (jointType1 == SimpleOpenNI.SKEL_HEAD) {
    head_position = jointPos1;
  }


  stroke(255, 0, 0, confidence * 200 + 55);
  stroke(0, 0);
  line(jointPos1.x, jointPos1.y, jointPos1.z, 
    jointPos2.x, jointPos2.y, jointPos2.z);

  drawJointOrientation(userId, jointType1, jointPos1, 50);
}



void drawJointOrientation(int userId, int jointType, PVector pos, float length) {
  // draw the joint orientation  
  PMatrix3D orientation = new PMatrix3D();
  float confidence = context.getJointOrientationSkeleton(userId, jointType, orientation);
  if (confidence < 0.001f)
    // nothing to draw, orientation data is useless
    return;

  pushMatrix();
  translate(pos.x, pos.y, pos.z);

  // set the local coordsys
  applyMatrix(orientation);

  // coordsys lines are 100mm long
  // x - r


  stroke(255, 0, 0, confidence * 200 + 55);
  stroke(0, 0);
  line(0, 0, 0, 
    length, 0, 0);
  // y - g


  stroke(0, 255, 0, confidence * 200 + 55);
  stroke(0, 0);
  line(0, 0, 0, 
    0, length, 0);
  // z - b    

  stroke(0, 0, 255, confidence * 200 + 55);
  stroke(0, 0);
  line(0, 0, 0, 
    0, 0, length);
  popMatrix();
}

// -----------------------------------------------------------------
// SimpleOpenNI user events




void onNewUser(SimpleOpenNI curContext, int userId) {
  println("onNewUser - userId: " + userId);
  println("\tstart tracking skeleton");
  kusers.add(new KinectUser(userId, floor(random(0, emojis.size()))));
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

void movieEvent(Movie m) {
  m.read();
}
