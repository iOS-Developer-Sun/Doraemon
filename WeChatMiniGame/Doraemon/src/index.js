import * as PIXI from '../libs/pixi.js';
import config from './config.js';
import databus from './databus.js';
import BackGround from './base/bg.js';
import Tween from './base/tween.js';
import gameServer from './gameserver.js';
import login from './base/login.js';
import Room from './scenes/room.js';
import GameScene from './scenes/GameScene.js';
import Home from './scenes/home.js';

export default class App extends PIXI.Application {
    constructor() {
        super(config.windowWidth, config.windowHeight, config.pixiOptions);

        this.updateWindowInfo();
        wx.onDeviceOrientationChange((res) => {
            console.log('deviceOrientationChange', res);
            this.updateWindowInfo();
        });

        this.bindWxEvents();
        this.renderer.plugins.interaction.mapPositionToPoint = (point, x, y) => {
            point.x = x;
            point.y = y;
        };

        // this.aniId = null;
        // this.bindLoop = this.loop.bind(this);

        // config.resources.forEach(item => PIXI.loader.add(item));
        // PIXI.loader.load(this.init.bind(this));
        this.init();
    }

    updateWindowInfo() {
        const windowInfo = wx.getWindowInfo();
        config.safeArea = windowInfo.safeArea ? {
            left: windowInfo.safeArea.left,
            right: windowInfo.windowWidth - windowInfo.safeArea.right,
            top: windowInfo.safeArea.top,
            bottom: windowInfo.windowHeight - windowInfo.safeArea.bottom,
        } : {
            left: 0,
            right: 0,
            top: 0,
            bottom: 0
        };
        console.log(config.windowWidth, config.windowHeight, config.safeArea);
    }

    runScene(Scene, options) {
        let old = this.stage.getChildByName('scene');

        while (old) {
            if (old._destroy) {
                old._destroy();
            }
            old.destroy(true);
            this.stage.removeChild(old);
            old = this.stage.getChildByName('scene');
        }

        let scene = new Scene();
        scene.name = 'scene';
        scene.sceneName = Scene.name;
        console.log('runScene', Scene.drmName);
        scene.launch(gameServer, options);
        this.stage.addChild(scene);

        return scene;
    }

    joinToRoom() {
        wx.showLoading({ title: '加入房间中' });
        gameServer.joinRoom(databus.currentAccessInfo, (errCode) => {
            wx.hideLoading();
            if (errCode == null) {
                this.runScene(Room);
            }
        });
    }

    scenesInit() {
        // 从会话点进来的场景
        if (databus.currentAccessInfo) {
            this.joinToRoom();
        } else {
            this.runScene(Home);
        }

        gameServer.event.on('backHome', () => {
            this.runScene(Home);
        });

        gameServer.event.on('createRoom', () => {
            this.runScene(Room);
        });

        gameServer.event.on('joinRoom', () => {
            if (gameServer.roomInfo.roomState === config.roomState.gameStart) {
                this.runScene(GameScene);
            } else {
                this.runScene(Room);
            }
        })

        gameServer.event.on('onGameStart', (options) => {
            databus.gameInstance = this.runScene(GameScene, options);
        });

        gameServer.event.on('onGameEnd', () => {
            gameServer.gameResult.forEach((member) => {
                var isSelf = member.nickname === databus.userInfo.nickName;
                isSelf && wx.showModal({
                    content: member.win ? "你已获得胜利" : "你输了",
                    confirmText: "返回首页",
                    confirmColor: "#02BB00",
                    showCancel: false,
                    success: () => {
                        gameServer.clear();
                    }
                });
            });
        });
    }

    init() {
        this.stage.addChild(new BackGround());
        login.do(() => {
            gameServer.login().then(() => {
                this.scenesInit();
            });
        });
    }

    // scaleToScreen() {
    //     const x = window.innerWidth / 667;
    //     const y = window.innerHeight / 375;

    //     if (x > y) {
    //         this.stage.scale.x = y / x;
    //         this.stage.x = (1 - this.stage.scale.x) / 2 * config.windowWidth;
    //     } else {
    //         this.stage.scale.y = x / y;
    //         this.stage.y = (1 - this.stage.scale.y) / 2 * config.windowHeight;
    //     }
    // }

    // _update(dt) {
    //     gameServer.update(dt);
    //     Tween.update();
    // }

    // loop() {
    //     let time = +new Date();
    //     this._update(time - this.timer);
    //     this.timer = time;
    //     this.renderer.render(this.stage);
    //     this.aniId = window.requestAnimationFrame(this.bindLoop);
    // }

    bindWxEvents() {
        wx.onShow(res => {
            let accessInfo = res.query.accessInfo;

            if (!accessInfo) {
                return;
            }

            console.log("bindWxEvents accessInfo:" + accessInfo);

            if (!databus.currentAccessInfo) {
                databus.currentAccessInfo = accessInfo;

                this.joinToRoom();

                return;
            }

            if (accessInfo == databus.currentAccessInfo) {
                return;
            }

            wx.showModal({
                title: "温馨提示",
                content: "你要离开当前房间，接受对方的对战邀请吗？",
                success: res => {
                    if (!res.confirm) return;
                    let room =
                        databus.isOwner
                            ? "ownerLeaveRoom"
                            : "memberLeaveRoom";

                    gameServer[room](res => {
                        if (res.errCode)
                            return wx.showToast({
                                title: "离开房间失败！",
                                icon: "none",
                                duration: 2000
                            });

                        databus.currentAccessInfo = accessInfo;

                        this.joinToRoom();
                    });
                }
            });
        });
    }
}

