import Global from './global'
import Lobby from './lobby'
import Room from './room'

export default class Doraemon {
  static _sharedInstance;
  static sharedInstance() {
    if (!this._sharedInstance) {
      this._sharedInstance = new Doraemon();
    }
    return this._sharedInstance;
  }
  startButton = wx.createUserInfoButton({
    type: 'text',
    text: '开始游戏',
    style: {
      left: Global.screenWidth / 2 - 50,
      top: Global.screenHeight / 2,
      width: 100,
      height: 40,
      lineHeight: 40,
      backgroundColor: '#007AFF',
      color: '#ffffff',
      textAlign: 'center',
      fontSize: 16,
      borderRadius: 8
    }
  });
  bgImage = wx.createImage();
  constructor() {
    this.bgImage.src = 'images/bg.jpg';
    this.bgImage.onload = () => {
      Global.context.drawImage(this.bgImage, 0, 0, Global.screenWidth, Global.screenHeight);
    };
  
    this.start();
  }

  start() {
    var doraemon = this;
    this.startButton.onTap(() => {
      wx.getSetting({
        success (res) {
          if (res.authSetting['scope.userInfo']) {
            wx.getUserInfo({
              success: function(res) {
                Global.userInfo = res.userInfo
                doraemon.didStartGame();
              }
            })
          }
        }
      })
    });    
  }

  didStartGame () {
    this.startButton.hide();
    this.lobby = new Lobby();
    this.lobby.roomDidCreate = function(res) {
      console.log(res)
      if (res["errCode"] == 0) {
        Doraemon.sharedInstance().room = new Room(res["data"]);
      } else {
        wx.showToast({
          title: res["errMsg"],
        })
      }
    };
    Global.gsm.login();
  }
}