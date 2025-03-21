import * as PIXI from '../../libs/pixi.js';
import config from '../config.js';
import { createBtn, createText } from '../common/ui.js';
import databus from '../databus.js';
import { showTip, createArray } from '../common/util.js';
import { gsap } from "gsap";
import { getPasscode } from '../common/api.js';

export default class Room extends PIXI.Container {
    constructor() {
        super();

        this.passcode = null;
        this.selfPosNum = 0;
        this.gameServer = null;
        this.seats = createArray(databus.max_players_count);
        this.initUI();
    }

    initUI() {
        let titleLabel = createText({
            str: '请就座。',
            align: 'center',
            x: config.GAME_WIDTH / 2,
            y: config.GAME_HEIGHT / 3,
            style: {
                fontSize: 64,
                fill: "#FFFFFF"
            }
        });

        this.addChild(titleLabel);
        this.titleLabel = titleLabel;

        this.appendBackBtn();
        this.appendOpBtn()

        this.playerViews = [];
        for (let index = 0; index < this.seats.length; index++) {
            this.createOneUser(index);
        }

        if (this.passcode == null && databus.currAccessInfo) {
            getPasscode(databus.currAccessInfo, (passcode) => {
                this.passcode = passcode;
                if (passcode) {
                    this.titleLabel.text = '请就座。' + '密码:' + passcode;
                }
            });
        }
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
        let startButton = createBtn({
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
        this.addChild(startButton);
        this.startButton = startButton;

        this.startButton.visible = databus.isOwner;
        this.startButton.alpha = this.allReady ? 1.0 : 0.5;

        let invite = createBtn({
            img: 'images/default_user.png',
            width: 100,
            height: 100,
            x: config.GAME_WIDTH - 100,
            y: config.GAME_HEIGHT - 100,
            onclick: () => {
                console.log('invite:' + databus.currAccessInfo);
                wx.setClipboardData({ data: databus.currAccessInfo });
                // wx.shareAppMessage({
                //     title: '邀请好友',
                //     query: 'accessInfo=' + this.gameServer.accessInfo,
                //     imageUrl: 'https://res.wx.qq.com/wechatgame/product/luban/assets/img/sprites/bk.jpg',
                // });
            }
        });

        this.addChild(invite);
    }

    clickSeat(index) {
        const member = this.seats[index];
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

    createOneUser(index) {
        let imageWidth = 100;
        let playerView = new PIXI.Container();
        playerView.width = imageWidth;
        playerView.height = imageWidth;
        this.addChild(playerView);
        this.playerViews.push(playerView);

        let avatar = new PIXI.Sprite();
        avatar.x = 0;
        avatar.y = 0;
        avatar.width = imageWidth;
        avatar.height = imageWidth;
        playerView.addChild(avatar);
        playerView.drmAvatar = avatar;

        let name = new PIXI.Text('(空位)', { fontSize: 30, align: 'center', fill: "#FFFFFF" });
        name.x = 0;
        name.y = imageWidth + 5;
        playerView.addChild(name);
        playerView.drmName = name;

        const host = new PIXI.Sprite.from("images/hosticon.png");
        host.scale.set(.8);
        host.y = -30;
        host.visible = false;
        playerView.addChild(host);
        playerView.drmHost = host;

        this.refreshPlayerView(index + this.selfPosNum, playerView);

        playerView.interactive = true;
        playerView.on('pointerdown', () => {
            this.clickSeat(index);
        });
    }

    position(index) {
        const imageWidth = 100;
        let x;
        let y;
        if (index === 0) {
            x = (config.GAME_WIDTH - imageWidth) / 2;
            y = config.GAME_HEIGHT - imageWidth - 100;
        } else if (index === 1) {
            x = config.GAME_WIDTH - imageWidth - 100;
            y = 300;
        } else if (index === 2) {
            x = config.GAME_WIDTH - imageWidth - 100;
            y = 100;
        } else if (index === 3) {
            x = 100;
            y = 100;
        } else {
            x = 100;
            y = 300;
        }
        return { x, y };
    }

    refreshPlayerView(index, playerView, member, offset = 0) {
        var nickname = '(空位 ' + (index + 1) + ')'
        var headimg = "images/avatar_default.png";
        var role = config.roleMap.partner;
        if (member) {
            nickname = member.nickname;
            headimg = member.headimg;
            role = member.role;
        }

        playerView.drmAvatar.texture = PIXI.Texture.from(headimg);
        playerView.drmName.text = nickname;
        playerView.drmHost.visible = role == config.roleMap.owner;

        const localIndex = databus.index(index - this.selfPosNum);
        if (offset != 0) {
            this.animatePositionChange(playerView, databus.index(localIndex + offset), localIndex, offset > 0);
            playerView.drmLocalIndex = localIndex;
        } else {
            const { x, y } = this.position(localIndex);
            playerView.x = x;
            playerView.y = y;
            playerView.drmLocalIndex = localIndex;
        }
    }

    animatePositionChange(playerView, from, to, clockwise) {
        if (from == to) {
            return;
        }

        const next = databus.index(clockwise ? from - 1 : from + 1);
        const { x, y } = this.position(next);
        gsap.to(playerView, {
            x: x, y: y, duration: 0.25, onComplete: () => {
                this.animatePositionChange(playerView, next, to, clockwise);
            }
        });
    }

    handleRoomInfo(res) {
        let offset = 0;
        if (databus.selfPosNum >= 0 && databus.selfPosNum < databus.max_players_count) {
            offset = databus.selfPosNum - this.selfPosNum;
            if (offset < -databus.max_players_count / 2) {
                offset += databus.max_players_count;
            } else if (offset > databus.max_players_count / 2) {
                offset -= databus.max_players_count;
            }
            this.selfPosNum = databus.selfPosNum;
        }

        const data = res.data || {};
        const roomInfo = data.roomInfo || {};
        const memberList = roomInfo.memberList || [];
        this.seats = createArray(databus.max_players_count);
        for (let i = 0; i < memberList.length; i++) {
            var member = memberList[i];
            if (member.posNum >= 0 && member.posNum < this.seats.length) {
                this.seats[member.posNum] = member;
            }
        }

        for (let i = 0; i < this.seats.length; i++) {
            const playerView = this.playerViews[i];
            const member = this.seats[i];
            this.refreshPlayerView(i, playerView, member, offset);
        }

        this.allReady = (memberList.length == databus.max_players_count) && !memberList.find(member => !member.isReady);

        if (!this.allReady && databus.testMode) {
            this.allReady = true;
        }

        this.startButton.visible = databus.isOwner;
        this.startButton.alpha = this.allReady ? 1.0 : 0.5;

    }

    handleRoomInfoForTheFirstTime(res) {
        const data = res.data || {};
        const roomInfo = data.roomInfo || {};
        const memberList = roomInfo.memberList || [];
        for (let i = 0; i < memberList.length; i++) {
            var member = memberList[i];
            if (databus.selfClientId === member.clientId) {
                if (member.posNum >= 0 && member.posNum < databus.max_players_count && !member.isReady) {
                    // auto sit down
                    console.log('auto sit down at ' + member.posNum);
                    this.gameServer.updateReadyStatus(true);
                }
                break;
            }
        }
        this.handleRoomInfo(res);
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

