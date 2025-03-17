import Global from './global'

export default class Lobby {
  roomDidCreate;
  gameList = [];

  createGameButton = wx.createUserInfoButton({
    type: 'text',
    text: '创建房间',
    style: {
      left: Global.screenWidth / 2 - 60,
      top: Global.screenHeight - 100,
      width: 120,
      height: 40,
      lineHeight: 40,
      backgroundColor: '#28a745',
      color: '#ffffff',
      textAlign: 'center',
      fontSize: 16,
      borderRadius: 8
    }
  });

  renderGameList = function() {
    Global.context.fillStyle = "#fff";
    Global.context.font = "16px Arial";
    Global.context.clearRect(0, 0, Global.screenWidth, Global.screenHeight); // 清空画布
    this.gameList.forEach((game, index) => {
      Global.context.fillText(`${game.name} - Players: ${game.players}/4`, 50, 150 + index * 40);
    });
  };

  constructor () {
    var lobby = this;
    this.createGameButton.onTap(() => {
      Global.gsm.createRoom({
        maxMemberNum: 5,
        startPercent: 100,
        needUserInfo: true,
        gameLastTime: 3600,
        complete: this.roomDidCreate
      });
      // wx.request({
      //   url: 'https://www.baidu.com', // Replace with your actual backend API
      //   method: 'POST',
      //   success(res) {
      //     fetchGameList(lobby);
      //     wx.showToast({ title: 'Game Created', icon: 'success' });
      //   }
      // });
    });

    this.gameList = [
      { id: 1, name: Global.userInfo.nickName , players: 3 },
      { id: 2, name: "Table 2", players: 2 }
    ];
    setInterval(fetchGameList, 5000, lobby);
    this.renderGameList(); 
  }
}

function fetchGameList(lobby) {
  wx.request({
    url: 'https://www.baidu.com', // Replace with your server API
    method: 'GET',
    success(res) {
      lobby.gameList = res.data;
      lobby.gameList = [
        { id: 1, name: "Table 1", players: 3 },
        { id: 2, name: "Table 2", players: 2 }
      ]; // Update game list
      lobby.renderGameList();
    }
  });
}