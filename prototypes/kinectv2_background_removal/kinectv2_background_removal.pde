import controlP5.*;
import SimpleOpenNI.*;
import processing.video.*;

SimpleOpenNI context;
int[] userMap;

ControlP5 cp5;


void setup() {
  size(1280, 720, P3D);
  context = new SimpleOpenNI(this);
  if (context.isInit() == false) {
    println("Can't init SimpleOpenNI, maybe the camera is not connected!");
    exit();
    return;
  }
  context.enableDepth();
  context.enableRGB();
  context.enableUser();

  cp5 = new ControlP5(this);

  cp5.addSlider("color_scaler").linebreak().setRange(0, 2).setSize(500, 10);
  cp5.addSlider("depth_scaler").linebreak().setRange(0, 2).setSize(500, 10);
  cp5.addSlider("depth_offset_x").linebreak().setRange(-100, 200).setSize(500, 10);
  cp5.addSlider("depth_offset_y").linebreak().setRange(-100, 100).setSize(500, 10);
}


void draw() {
  context.update();
  background(0, 255, 0);
  PImage noBgImg =  backgroundRemoval(context.userMap(), context.rgbImage().get());
  image(noBgImg, 0, 0);
}


PImage backgroundRemoval(int[] userMap, PImage rgb) {
  float color_scaler = 0.67;
  float depth_scaler = 1.88;
  float depth_offset_x = 195.8;
  float depth_offset_y = -31;
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
  //image(rgb, 0, 0, rgb.width, rgb.height);
}


PImage resize(PImage input, int w, int h) {
  PGraphics pg = createGraphics(w, h, P2D);
  pg.beginDraw();
  pg.image(input, 0, 0, w, h);
  pg.endDraw();
  return pg.get();
}
