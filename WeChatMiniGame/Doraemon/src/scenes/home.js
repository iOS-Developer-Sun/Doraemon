import * as PIXI from '../../libs/pixi.js';
import config from '../config.js';
import databus from '../databus.js';
import { createBtn, createText } from '../common/ui.js';
import * as GameServer from '../gameserver.js'

import Debug from '../base/debug.js';
import { getAccessInfo } from '../common/api.js';

export default class Home extends PIXI.Container {
    static drmName = 'Home';

    /** @type {GameServer} */
    gameServer;
    constructor() {
        super();

        this.debug = new Debug();
        this.addChild(this.debug);

        this.keyboardConfirmListener = this.keyboardConfirm.bind(this);
    }

    keyboardConfirm(res) {
        wx.offKeyboardConfirm(this.keyboardConfirmListener);
        let string = res.value;
        if (string.length == 0) {
            this.handling = false;
            return;
        }

        this.joinRoom(string);
    }

    appendOpBtn() {
        const title = createText({
            str: '打懵',
            align: 'center',
            x: config.windowWidth / 2,
            y: config.windowHeight / 3,
            style: {
                fontSize: 44,
                fill: "#FFFFFF"
            }
        });
        this.addChild(title);

        const version = createText({
            str: databus.version,
            align: 'center',
            x: config.windowWidth / 2,
            y: config.windowHeight / 3 + 50,
            style: {
                fontSize: 10,
                fill: "#E5E5E5"
            }
        });
        this.addChild(version);

        const createRoomButton = createBtn({
            text: '创建房间',
            img: 'images/btn_bg.png',
            x: config.windowWidth / 2 - 100,
            y: config.windowHeight / 3 * 2,
            width: 112,
            height: 44,
            onclick: () => {
                if (this.handling) {
                    return;
                }
                this.handling = true
                wx.showLoading({
                    title: '房间创建中...',
                })
                this.gameServer.createRoom({
                    maxMemberNum: databus.max_players_count
                }, (errCode) => {
                    wx.hideLoading();
                    this.handling = false;
                });
            }
        });
        this.addChild(createRoomButton);

        const joinRoomButton = createBtn({
            text: '加入房间',
            img: 'images/btn_bg.png',
            x: config.windowWidth / 2 + 100,
            y: config.windowHeight / 3 * 2,
            width: 112,
            height: 44,
            onclick: () => {
                if (this.handling) {
                    return;
                }

                this.handling = true;

                wx.onKeyboardConfirm(this.keyboardConfirmListener);
                wx.showKeyboard({
                    defaultValue: '',
                    maxLength: 64,
                    multiple: false,
                    confirmHold: false,
                    confirmType: 'go'
                })
            }
        });
        this.addChild(joinRoomButton);
    }

    joinRoom(string) {
        wx.showLoading({ title: '加入房间中' });
        if (string.length == 4) {
            getAccessInfo(string, (accessInfo) => {
                if (accessInfo) {
                    this.joinRoomWithAccessInfo(accessInfo);
                } else {
                    wx.hideLoading();
                    this.handling = false
                    console.log('join room failed, invalid passcode ' + string);
                    wx.showToast({
                        title: '密码错误！',
                        icon: 'error',
                        duration: 2000
                    })
                }
            });
        } else {
            this.joinRoomWithAccessInfo(string);
        }
    }

    joinRoomWithAccessInfo(accessInfo) {
        this.gameServer.joinRoom(accessInfo, (errCode) => {
            wx.hideLoading();
            this.handling = false
            console.log('joinRoomWithAccessInfo', errCode);
            if (errCode) {
                wx.showToast({
                    title: '无法加入房间:' + errCode,
                    icon: 'error',
                    duration: 2000
                })
            }
        });
    }

    launch(gameServer) {
        this.gameServer = gameServer;
        this.appendOpBtn();
    }
}

