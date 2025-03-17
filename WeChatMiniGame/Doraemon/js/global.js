const windowInfo = wx.getWindowInfo ? wx.getWindowInfo() : wx.getSystemInfoSync();
const canvas = wx.createCanvas();
canvas.width = windowInfo.screenWidth;
canvas.height = windowInfo.screenHeight;

export default class Global {
  static screenWidth = windowInfo.screenWidth;
  static screenHeight = windowInfo.screenHeight;
  static context = canvas.getContext('2d');;
  static userInfo;
  static gsm = wx.getGameServerManager();
}
