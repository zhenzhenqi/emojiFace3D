PImage backgroundRemoval(int[] userMap, PImage rgb) {

  rgb = resize(rgb, (int)(rgb.width*color_scaler), (int)(rgb.height*color_scaler));
  userMap = context.userMap();
  PImage userMapImg = createImage(640, 480, RGB);
  userMapImg.loadPixels();
  for (int i=0; i < userMap.length; i++) {
    userMapImg.pixels[i] = color(userMap[i]*255, 100);
  }
  userMapImg.updatePixels();
  PGraphics bigUserMapPG = createGraphics(rgb.width, rgb.height, P2D);
  bigUserMapPG.beginDraw();
  bigUserMapPG.background(0);
  bigUserMapPG.image(userMapImg, depth_offset_x, depth_offset_y, userMapImg.width * depth_scaler, userMapImg.height * depth_scaler);
  bigUserMapPG.endDraw();
  PImage bigUserMap = bigUserMapPG.get();
  rgb.mask(bigUserMap);
  return rgb;
}


PImage resize(PImage input, int w, int h) {
  PGraphics pg = createGraphics(w, h, P2D);
  pg.beginDraw();
  pg.image(input, 0, 0, w, h);
  pg.endDraw();
  return pg.get();
}


////////////SIMPLEOPENNI'S AUTHOR'S FUNCTIONS////////


void drawLimb(int userId, int jointType1, int jointType2) {
  PVector jointPos1 = new PVector();
  PVector jointPos2 = new PVector();
  float confidence;
  // draw the joint position
  confidence = context.getJointPositionSkeleton(userId, jointType1, jointPos1);
  confidence = context.getJointPositionSkeleton(userId, jointType2, jointPos2);
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
