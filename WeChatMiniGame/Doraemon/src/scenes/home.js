import * as PIXI from '../../libs/pixi.js';
import config from '../config.js';
import databus from '../databus.js';
import { createBtn, createText } from '../common/ui.js';
import * as GameServer from '../gameserver.js'

import Debug from '../base/debug.js';

export default class Home extends PIXI.Container {
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
        this.addChild(
            createText({
                str: ' 打懵' + databus.version,
                x: config.GAME_WIDTH / 2,
                y: 287,
                style: {
                    fontSize: 64,
                    fill: "#FFFFFF"
                }
            }),

            createBtn({
                text: '创建房间',
                img: 'images/btn_bg.png',
                x: config.GAME_WIDTH / 2 - 100,
                y: 582,
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
            }),

            createBtn({
                text: '加入房间',
                img: 'images/btn_bg.png',
                x: config.GAME_WIDTH / 2 + 100,
                y: 582,
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
            })
        );
    }

    joinRoom(accessInfo) {
        wx.showLoading({ title: '加入房间中' });
        this.gameServer.joinRoom(accessInfo, (errCode) => {
            wx.hideLoading();
            this.handling = false
            console.log('join' + errCode);
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

