import * as PIXI from '../../libs/pixi.js';
import config from '../config.js';
import { createBtn } from '../common/ui.js';
import databus from '../databus.js';
import { showTip } from '../common/util.js';

const emptyUser = {
    nickname: '点击邀请好友',
    headimg: "images/avatar_default.png",
    isEmpty: true,
    isReady: false,
    index: 0,
}

export default class Room extends PIXI.Container {
    constructor() {
        super();

        this.gameServer = null;

    }

    initUI() {
        let title = new PIXI.Text('想成为呆子吗？请就座。', { fontSize: 56, align: 'center', fill: "#515151" });
        title.x = config.GAME_WIDTH / 2 - title.width / 2;
        title.y = 96;
        this.addChild(title);
    }

    appendBackBtn() {
        const back = createBtn({
            img: 'images/goBack.png',
            x: 104,
            y: 68,
            onclick: () => {
                wx.showModal({
                    title: '温馨提示',
                    content: '是否离开房间？',
                    success: (res) => {
                        if (res.confirm) {
                            if (databus.isOwner) {
                                this.gameServer.ownerLeaveRoom();
                            } else {
                                this.gameServer.memberLeaveRoom();
                            }
                        }
                    }
                })
            }
        });

        this.addChild(back);
    }

    appendOpBtn() {
        let isOwner = databus.isOwner;
        if (isOwner) {
            let start = createBtn({
                img: 'images/start.png',
                x: config.GAME_WIDTH / 2,
                y: config.GAME_HEIGHT / 2,
                onclick: () => {
                    if (!this.allReady) {
                        showTip('全部玩家准备后方可开始');
                    } else {
                        this.gameServer.broadcast({
                            action: "START"
                        });
                    }
                }
            });

            if (!this.allReady) {
                start.alpha = 0.5;
            }

            this.addChild(start);
        }

        let invite = createBtn({
            img: 'images/default_user.png',
            width: 100,
            height: 100,
            x: config.GAME_WIDTH - 100,
            y: config.GAME_HEIGHT - 100,
            onclick: () => {
                wx.shareAppMessage({
                    title: '邀请好友',
                    query: 'accessInfo=' + this.gameServer.accessInfo,
                    imageUrl: 'https://res.wx.qq.com/wechatgame/product/luban/assets/img/sprites/bk.jpg',
                });
            }
        });

        this.addChild(invite);
    }

    clearUI() {
        this.removeChildren();
    }

    clickSeat(index) {
        var member = this.seats[index];
        if (member) {
            if (databus.selfClientId === member.clientId) {
                // stand up
                console.log("stand up at " + index);
                this.gameServer.updateReadyStatus(false);
                this.gameServer.changeSeat(- member.clientId);
            } else {
                // kick out
            }
        } else {
            // sit down
            console.log("sit down at " + index);
            this.gameServer.changeSeat(index);
            this.gameServer.updateReadyStatus(true);
        }
    }

    createOneUser(index, member) {
        let imageWidth = 100;
        let container = new PIXI.Container();
        container.width = imageWidth;
        container.height = imageWidth;
        if (index === 0) {
            container.x = (config.GAME_WIDTH - imageWidth) / 2;
            container.y = config.GAME_HEIGHT - imageWidth - 100;
        } else if (index === 1) {
            container.x = config.GAME_WIDTH - imageWidth - 100;
            container.y = 300;
        } else if (index === 2) {
            container.x = config.GAME_WIDTH - imageWidth - 100;
            container.y = 100;
        } else if (index === 3) {
            container.x = 100;
            container.y = 100;
        } else {
            container.x = 100;
            container.y = 300;
        }
        this.addChild(container);

        var nickname = '(空位)'
        var headimg = "images/avatar_default.png";
        var role = null;
        if (member) {
            nickname = member.nickname;
            headimg = member.headimg;
            role = member.role;
        }

        let avatar = new PIXI.Sprite.from(headimg);
        avatar.x = 0;
        avatar.y = 0;
        avatar.width = imageWidth;
        avatar.height = imageWidth;
        container.addChild(avatar);

        let name = new PIXI.Text(nickname, { fontSize: 30, align: 'center', fill: "#515151" });
        name.x = 0;
        name.y = imageWidth + 5;
        container.addChild(name);

        container.interactive = true;
        container.on('pointerdown', () => {
            this.clickSeat(index);
        });

        if (role === config.roleMap.owner) {
            const host = new PIXI.Sprite.from("images/hosticon.png");
            host.scale.set(.8);
            host.y = -30;
            container.addChild(host);
        }
    }

    handleRoomInfo(res) {
        this.clearUI();

        this.initUI();

        const data = res.data || {};
        const roomInfo = data.roomInfo || {};
        const memberList = roomInfo.memberList || [];

        const max_players_count = databus.max_players_count;
        var seats = [];
        for (let i = 0; i < max_players_count; i++) {
            seats.push(null);
        }

        for (let i = 0; i < memberList.length; i++) {
            var member = memberList[i];
            if (member.posNum >= 0 && member.posNum < max_players_count) {
                seats[member.posNum] = member;
            }
        }

        this.seats = seats;

        seats.forEach((member, index) => {
            this.createOneUser(index, member);
        });

        this.appendBackBtn();
        this.allReady = (memberList.length == max_players_count) && !memberList.find(member => !member.isReady);

        if (databus.testMode) {
            this.allReady = (memberList.length == 1) && !memberList.find(member => !member.isReady);
        }

        this.appendOpBtn()
    }

    handleRoomInfoForTheFirstTime(res) {
        const data = res.data || {};
        const roomInfo = data.roomInfo || {};
        const memberList = roomInfo.memberList || [];

        const max_players_count = databus.max_players_count;

        for (let i = 0; i < memberList.length; i++) {
            var member = memberList[i];
            if (databus.selfClientId === member.clientId) {
                if (member.posNum >= 0 && member.posNum < max_players_count && !member.isReady) {
                    // sit down
                    this.gameServer.updateReadyStatus(true);
                    return;
                }
                break;
            }
        }
        self.handleRoomInfo(res);
    }

    _destroy() {
        this.gameServer.event.off('onRoomInfoChange');
    }

    onRoomInfoChange(roomInfo) {
        this.handleRoomInfo({ data: { roomInfo } });
    }

    launch(gameServer) {
        this.gameServer = gameServer;
        this.onRoomInfoChangeHandler = this.onRoomInfoChange.bind(this);

        // 每次房间信息更新重刷UI
        gameServer.event.on('onRoomInfoChange', this.onRoomInfoChangeHandler);

        gameServer.getRoomInfo(this.accessInfo).then((res) => {
            this.handleRoomInfoForTheFirstTime(res);
        });
    }
}

