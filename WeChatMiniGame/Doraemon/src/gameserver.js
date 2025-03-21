import * as PIXI from '../libs/pixi.js';
import compareVersion from '../libs/compareVersion.js';
import config from './config.js';
import databus from './databus.js'
import {
    showTip,
} from './common/util.js';

class GameServer {
    constructor() {
        if (!wx.getGameServerManager) {
            return showTip('当前微信版本不支持帧同步框架');
        }

        this.server = wx.getGameServerManager();
        this.event = new PIXI.utils.EventEmitter();

        // 检测当前版本
        this.isVersionLow = compareVersion(wx.getSystemInfoSync().SDKVersion, '2.14.4') < 0;

        // 用于存房间信息
        this.roomInfo = {};

        // 用于标记帧同步房间是否真正开始，如果没有开始，不能发送指令，玩家不能操作
        this.hasGameStart = false;
        // 帧同步帧率
        this.fps = 30;
        // 逻辑帧的时间间隔
        this.frameInterval = parseInt(1000 / this.fps);
        // 为了防止网络抖动设置的帧缓冲数，类似于放视频
        this.frameJitLenght = 2;

        this.gameResult = [];

        // 用于标识是否重连中
        this.reconnecting = false;
        // 重连回包后，用于标识重连完成的帧号
        this.reconnectMaxFrameId = 0;
        // 重连成功次数
        this.reconnectSuccess = 0;
        // 重连失败次数
        this.reconnectFail = 0;

        this.reset();
        this.bindEvents();

        this.isConnected = true;
        // 记录网路状态
        wx.getNetworkType({
            success: (res) => {
                this.isConnected = !!(res.networkType !== 'none');
            }
        });
    }

    bindEvents() {
        this.onBroadcastHandler = this.onBroadcast.bind(this);
        this.onSyncFrameHandler = this.onSyncFrame.bind(this);
        this.onRoomInfoChangeHandler = this.onRoomInfoChange.bind(this);
        this.onGameStartHandler = this.onGameStart.bind(this);
        this.onGameEndHandler = this.onGameEnd.bind(this);

        this.server.onBroadcast(this.onBroadcastHandler);
        this.server.onSyncFrame(this.onSyncFrameHandler);
        this.server.onRoomInfoChange(this.onRoomInfoChangeHandler);
        this.server.onGameStart(this.onGameStartHandler);
        this.server.onGameEnd(this.onGameEndHandler);

        this.server.onGameStart((res) => {
            console.log('来自系统的onStart')
        });

        const reconnect = () => {
            // 如果logout了，需要先logout再connect
            if (this.isLogout && this.isDisconnect) {
                this.server.login().then(res => {
                    console.log('networkType change or onShow -> login', res)
                    this.server.reconnect().then(res => {
                        console.log('networkType change or onShow -> reconnect', res)
                        ++this.reconnectSuccess;
                        wx.showToast({
                            title: '游戏已连接',
                            icon: 'none',
                            duration: 2000
                        });
                    });
                }).catch(e => ++reconnectFail);
            } else {
                // 否则只需要处理对应的掉线事件
                if (this.isLogout) {
                    this.server.login().then(res => console.log('networkType change or onShow -> login', res));
                }

                if (this.isDisconnect) {
                    this.server.reconnect().then(res => {
                        ++this.reconnectSuccess;
                        console.log('networkType change or onShow -> reconnect', res)
                        wx.showToast({
                            title: '游戏已连接',
                            icon: 'none',
                            duration: 2000
                        })
                    }).catch(e => ++reconnectFail);
                }
            }
        };

        wx.onNetworkStatusChange((res) => {
            console.log('当前是否有网路连接', res.isConnected);
            let isConnected = res.isConnected;

            console.log('当前状态', this.isLogout, this.isDisconnect, this.isConnected);

            // 网络从无到有
            if (!this.isConnected && isConnected) {
                reconnect();
            }

            this.isConnected = isConnected;
        })

        this.server.onLogout(() => {
            console.log('onLogout');
            this.isLogout = true;
        });

        this.server.onDisconnect((res) => {
            console.log('onDisconnect', res);
            this.isDisconnect = true;
            res.type !== "game" && wx.showToast({
                title: "游戏已掉线...",
                icon: "none",
                duration: 2e3
            });
            res.type === "game" && function (that) {
                function relink() {
                    that.server.reconnect().then(function (res) {
                        console.log("networkType change or onShow -> reconnect", res);
                        ++that.reconnectSuccess;
                    }).catch(relink);
                }
                relink();
            }(this);
        });

        wx.onShow(() => {
            reconnect();
        });
    }

    offEvents() {
        this.server.offBroadcast(this.onBroadcastHandler);
        this.server.offSyncFrame(this.onSyncFrameHandler);
        this.server.offRoomInfoChange(this.onRoomInfoChangeHandler);
        this.server.offGameStart(this.onGameStartHandler);
        this.server.offGameEnd(this.onGameEndHandler);
    }

    reset() {
        // 本地缓冲帧队列
        this.frames = [];
        // 用于标记帧同步房间是否真正开始，如果没有开始，不能发送指令，玩家不能操作
        this.frameStart = false;
        // 游戏开始的时间
        this.startTime = new Date();
        // 当前游戏运行的帧位
        this.currFrameIndex = 0;
        // 当前收到的最新帧帧号
        this.svrFrameIndex = 0;
        this.hasSetStart = false;
        this.hasGameStart = false;

        this.statCount = 0;
        this.avgDelay = 0;
        this.delay = 0;

        this.isDisconnect = false;
        this.isLogout = false;
    }

    onBroadcast(message) {
        let { msg } = message;
        let object = JSON.parse(msg);
        let { action, data } = object;
        console.log('onBroadcast: ' + action);
        if (action == 'START') {
            this.startGame();
        } else {
            databus.gameInstance.logicUpdate(message.senderPosNum, action, data);
        }
    }

    onGameStart() {
        if (this.hasGameStart) {
            return;
        }

        this.hasGameStart = true;
        console.log('onGameStart');
        this.event.emit('onGameStart');

        this.debugTime = setInterval(() => {
            // this.uploadFrame([
            //     JSON.stringify({
            //         c: ++this.statCount,
            //         t: +new Date(),
            //         e: config.msg.STAT,
            //         id: databus.selfClientId,
            //     })
            // ]);

            let time = new Date() - this.startTime;

            databus.debugMsg = [
                `游戏时间: ${parseInt(time / 1000) + 's'}`,
                // `期望帧数: ${Math.floor(time / this.frameInterval)}帧`,
                // `实收帧数: ${this.svrFrameIndex}帧`,
                // `指令延迟: ${this.avgDelay.toFixed(1) + '(' + this.delay + ')'}ms`,
                `databus.selfPosNum: ${databus.selfPosNum}`,
                `databus.selfClientId: ${databus.selfClientId}`,
            ];
            this.reconnectSuccess && databus.debugMsg.push(`重连成功: ${this.reconnectSuccess}`);
            this.reconnectFail && databus.debugMsg.push(`重连失败: ${this.reconnectFail}`);

            // databus.gameInstance.debug.updateDebugMsg(databus.debugMsg);
        }, 10000);
    }

    onGameEnd() {
        this.settle();
        this.reset();
        this.event.emit('onGameEnd');

        clearInterval(this.debugTime);
    }

    endGame() {
        return this.server.endGame();
    }

    clear() {
        this.reset();
        databus.reset();
        this.event.emit('backHome');
    }

    onSyncFrame(res) {
        if (res.frameId % 300 === 0) {
            console.log('heart');
        }
        this.svrFrameIndex = res.frameId;
        this.frames.push(res);

        if (!this.reconnecting) {
            (res.actionList || []).forEach(oneFrame => {
                let obj = JSON.parse(oneFrame);
                console.log('onSyncFrame: ' + oneFrame);
                if (obj.e === config.msg.STAT && obj.id === databus.selfClientId) {
                    this.delay = new Date() - obj.t;
                    this.avgDelay = ((this.avgDelay * (obj.c - 1)) + this.delay) / obj.c;
                }
            });
        }

        if (this.frames.length > this.frameJitLenght) {
            this.frameStart = true;
        }

        if (!this.hasSetStart) {
            console.log('get first frame');
            this.startTime = new Date() - this.frameInterval;
            this.hasSetStart = true;
        }

        if (this.reconnecting && res.frameId >= this.reconnectMaxFrameId) {
            this.reconnecting = false;
            this.startTime = new Date() - this.frameInterval * this.reconnectMaxFrameId;
        }
    }

    onReconnect(res) {
        let roomInfo = res.data.roomInfo;
        const memberList = roomInfo.memberList || [];
        for (let i = 0; i < memberList.length; i++) {
            var member = memberList[i];
            var myNickName = databus.userInfo.nickName;
            if (myNickName === member.nickname) {
                databus.selfClientId = member.clientId;
                break;
            }
        }
        this.updateRoomInfo(roomInfo);
    }

    onRoomInfoChange(roomInfo) {
        console.log('onRoomInfoChange');
        this.updateRoomInfo(roomInfo);
    }

    updateRoomInfo(roomInfo) {
        this.roomInfo = roomInfo;
        const memberList = roomInfo.memberList || [];
        for (let i = 0; i < memberList.length; i++) {
            var member = memberList[i];
            if (databus.selfClientId === member.clientId) {
                databus.isOwner = member.role == config.roleMap.owner;
                databus.selfPosNum = member.posNum;
                break;
            }
        }
        this.event.emit('onRoomInfoChange', roomInfo);
    }

    login() {
        return this.server.login().then(() => {
            this.server.getLastRoomInfo().then((res) => {
                if (res.data && res.data.roomInfo && res.data.roomInfo.roomState === config.roomState.gameStart) {
                    console.log('查询到还有没结束的游戏', res.data);
                    wx.showModal({
                        title: '温馨提示',
                        content: '查询到之前还有尚未结束的游戏，是否重连继续游戏？',
                        success: (modalRes) => {
                            if (modalRes.confirm) {
                                databus.currAccessInfo = res.data.accessInfo;

                                wx.showLoading({
                                    title: '重连中...',
                                });

                                this.server.reconnect({
                                    accessInfo: res.data.accessInfo
                                }).then(connectRes => {
                                    console.log('未结束的游戏断线重连结果', connectRes);
                                    if (connectRes.errCode === 0) {
                                        this.onReconnect(res)
                                        this.onRoomInfoChange(res.data.roomInfo);
                                        this.reconnectMaxFrameId = connectRes.maxFrameId || 0;
                                        this.reconnecting = true;

                                        // 手动调用onGameStart模拟正常开局
                                        this.onGameStart('人工');
                                    }
                                    wx.hideLoading();
                                }).catch((e) => {
                                    wx.hideLoading();
                                    console.log(e);
                                    wx.showToast({
                                        title: '重连失败',
                                        icon: 'error',
                                        duration: 2000
                                    });
                                });
                            }
                        }
                    });
                }
            });
        });
    }

    createRoom(options = {}, callback) {
        this.server.createRoom({
            maxMemberNum: options.maxMemberNum || 2,
            startPercent: options.startPercent || 0,
            gameLastTime: 3600,    
            needUserInfo: true,
            success: (res) => {
                const data = res.data || {};
                databus.currAccessInfo = this.accessInfo = data.accessInfo || '';
                databus.selfClientId = data.clientId;
                this.event.emit('createRoom');
                console.log('createRoom:' + data.accessInfo);
                callback && callback(null);
            },
            fail: (res) => {
                callback && callback(res);
            }
        });
    }

    joinRoom(accessInfo, callback) {
        this.server.joinRoom({
            accessInfo, success: (res) => {
                let data = res.data || {};
                databus.currAccessInfo = this.accessInfo = data.accessInfo || '';
                databus.selfClientId = data.clientId;
                this.event.emit('joinRoom');
                console.log('joinRoom:' + data.accessInfo);
                callback && callback(null)
            },
            fail: (res) => {
                console.log('joinRoom ' + data.accessInfo + ' failed:' + res.errCode);
                callback && callback(res.errCode)
            }
        });
    }

    uploadFrame(actionList) {
        this.hasGameStart && this.server.uploadFrame({ actionList });
    }

    broadcast(msg, toPosNumList) {
        let string = JSON.stringify(msg);
        let report;
        if (toPosNumList != undefined) {
            report = {
                msg: string,
                toPosNumList: toPosNumList
            };
        } else {
            report = {
                msg: string,
            };
        }
        // console.log('broadcast: ' + string);
        this.server.broadcastInRoom(report);
    }

    uploadGameSet() {
        this.broadcast({
            action: "GAMESET",
            data: databus.gameSet
        })
    }

    requestGameSet() {
        this.broadcast({
            action: "ASKGAMESET",
        })
    }

    respondGameSet(receiver) {
        this.broadcast({
            action: "ANSWERGAMESET",
            data: databus.gameSet
        }, [receiver]);
    }

    announce() {
        this.broadcast({
            action: "ANNOUNCE",
        }, [databus.ownerPosNum])
    }

    playCards(cards) {
        this.broadcast({
            action: "PLAYCARDS",
            data: cards
        }, [databus.ownerPosNum])
    }

    pass() {
        this.broadcast({
            action: "PASS",
        }, [databus.ownerPosNum])
    }

    getRoomInfo() {
        return this.server.getRoomInfo();
    }

    startGame() {
        return this.server.startGame({
            success: (res) => {
                console.log('startGame success');
            },
            fail: (res) => {
                console.log('startGame fail:' + res);
            }
        });
    }

    memberLeaveRoom(callback) {
        this.server.memberLeaveRoom({
            accessInfo: this.accessInfo
        }).then((res) => {
            if (res.errCode === 0) this.clear();

            callback && callback(res);
        });
    }

    ownerLeaveRoom(callback) {
        this.server.ownerLeaveRoom({
            accessInfo: this.accessInfo,
            assignToMinPosNum: true
        }).then((res) => {
            if (res.errCode === 0) this.clear();

            callback && callback(res);
        });
    }

    cancelMatch(res) {
        this.server.cancelMatch(res);
    }

    changeSeat(posNum) {
        this.server.changeSeat({
            posNum,
        }).then(res => {
            console.log(res);
        });
    }

    updateReadyStatus(isReady) {
        return this.server.updateReadyStatus({ accessInfo: this.accessInfo, isReady });
    }

    update(dt) {
        if (!this.frameStart) {
            return;
        }

        // 重连中不执行渲染
        if (!this.reconnecting) {
            databus.gameInstance.renderUpdate(dt);
        }

        // 本地从游戏开始到现在的运行时间
        const nowFrameTick = new Date() - this.startTime;
        const preFrameTick = this.currFrameIndex * this.frameInterval;

        let currTimeDelta = nowFrameTick - preFrameTick;

        if (currTimeDelta >= this.frameInterval) {
            if (this.frames.length) {
                this.execFrame();
                this.currFrameIndex++;
            }
        }

        // 可能是断线重连的场景，本地有大量的帧，快进
        if (this.frames.length > this.frameJitLenght) {
            while (this.frames.length) {
                this.execFrame();
                this.currFrameIndex++;
            }
        }
    }

    execFrame() {
        let frame = this.frames.shift();

        // 每次执行逻辑帧，将指令同步后，演算游戏状态
        // databus.gameInstance.logicUpdate(this.frameInterval, frame.frameId);

        (frame.actionList || []).forEach(oneFrame => {
            let obj = JSON.parse(oneFrame);

            switch (obj.e) {
                case config.msg.SHOOT:
                    databus.playerMap[obj.n].shoot();
                    break;

                case config.msg.MOVE_DIRECTION:
                    databus.playerMap[obj.n].setDestDegree(obj.d);
                    break;

                case config.msg.MOVE_STOP:
                    databus.playerMap[obj.n].setSpeed(0);
                    databus.playerMap[obj.n].desDegree = databus.playerMap[obj.n].frameDegree;
                    break;
            }
        });

        // databus.gameInstance.preditUpdate(this.frameInterval);
    }

    settle() {
        databus.gameover = true;
    }
}

export default new GameServer();

