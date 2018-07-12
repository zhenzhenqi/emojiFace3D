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
