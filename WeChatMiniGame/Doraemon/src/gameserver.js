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

        this.hasGameStart = false;

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
        this.onLockStepErrorHandler = this.onLockStepError.bind(this);

        this.server.onBroadcast(this.onBroadcastHandler);
        this.server.onSyncFrame(this.onSyncFrameHandler);
        this.server.onRoomInfoChange(this.onRoomInfoChangeHandler);
        this.server.onGameStart(this.onGameStartHandler);
        this.server.onGameEnd(this.onGameEndHandler);
        this.server.onLockStepError(this.onLockStepErrorHandler);

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
            res.type !== 'game' && wx.showToast({
                title: '游戏已掉线...',
                icon: 'none',
                duration: 2e3
            });
            res.type === 'game' && function (that) {
                function relink() {
                    that.server.reconnect().then(function (res) {
                        console.log('relink', res);
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
        if (this.timer != null) {
            clearInterval(this.timer);
            this.timer = null;
        }

        // 当前收到的最新帧帧号
        this.svrFrameIndex = 0;
        this.hasGameStart = false;
        wx.setKeepScreenOn({ keepScreenOn: false });

        this.isDisconnect = false;
        this.isLogout = false;
    }

    onBroadcast(message) {
        let { msg } = message;
        let frame = JSON.parse(msg);
        console.log('onBroadcast: ', frame);
        if (frame.action == 'START') {
            this.startGame();
        } else {
            if (databus.gameInstance) {
                databus.gameInstance.logicUpdate(frame, this.svrFrameIndex);
            }
        }
    }

    onGameStart(options) {
        if (this.hasGameStart) {
            return;
        }

        wx.setKeepScreenOn({ keepScreenOn: true });
        this.hasGameStart = true;
        console.log('onGameStart');
        this.event.emit('onGameStart', options);

        // this.timer = setInterval(() => {
        //     this.uploadFrame(['']);
        // }, 5000);
    }

    onGameEnd() {
        this.settle();
        this.reset();
        this.event.emit('onGameEnd');
    }

    onLockStepError(res) {
        console.log('onLockStepError', res);
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
        if (res.frameId % 60 === 0) {
            console.log('heart');
        }
        this.svrFrameIndex = res.frameId;
        // this.frames.push(res);

        (res.actionList || []).forEach(action => {
            if (action.length > 0) {
                const frame = JSON.parse(action);
                if (databus.gameInstance) {
                    databus.gameInstance.logicUpdate(frame, res.frameId);
                } else {
                    databus.halt('no gameInstance!');
                }
            }
        });
    }

    onReconnect(res) {
        console.log('onReconnect', res);
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
        this.updateRoomInfo(roomInfo);
    }

    updateRoomInfo(roomInfo) {
        console.log('updateRoomInfo', roomInfo);
        this.roomInfo = roomInfo;
        const memberList = roomInfo.memberList || [];
        for (let i = 0; i < memberList.length; i++) {
            var member = memberList[i];
            if (member.role == config.roleMap.owner) {
                databus.ownerPosNum = member.posNum;
            }
            if (databus.selfClientId === member.clientId) {
                databus.isOwner = member.role == config.roleMap.owner;
                databus.selfPosNum = member.posNum;
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
                                databus.currentAccessInfo = res.data.accessInfo;

                                wx.showLoading({
                                    title: '重连中...',
                                });

                                this.server.reconnect({
                                    accessInfo: res.data.accessInfo
                                }).then(connectRes => {
                                    console.log('未结束的游戏断线重连结果', connectRes);
                                    if (connectRes.errCode == null || connectRes.errCode == 0) {
                                        this.onReconnect(res)
                                        this.onRoomInfoChange(res.data.roomInfo);
                                        this.reconnectMaxFrameId = connectRes.maxFrameId || 0;
                                        this.reconnecting = true;
                                        this.onGameStart({ isFromReconnection: true });
                                    } else {
                                        databus.currentAccessInfo = '';
                                    }
                                    wx.hideLoading();
                                }).catch((e) => {
                                    wx.hideLoading();
                                    databus.currentAccessInfo = '';
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
                databus.currentAccessInfo = this.accessInfo = data.accessInfo || '';
                databus.selfClientId = data.clientId;
                callback && callback(null);
                console.log('createRoom:', data.accessInfo);
                this.event.emit('createRoom');
            },
            fail: (res) => {
                callback && callback(res);
            }
        });
    }

    joinRoom(accessInfo, callback) {
        this.server.joinRoom({
            accessInfo,
            success: (res) => {
                console.log('joinRoom:', res);
                let data = res.data || {};
                databus.currentAccessInfo = this.accessInfo = data.accessInfo || '';
                databus.selfClientId = data.clientId;
                this.event.emit('joinRoom');
                callback && callback(null)
            },
            fail: (res) => {
                console.log('joinRoom ' + data.accessInfo + ' failed:' + res.errCode);
                callback && callback(res.errCode)
            }
        });
    }

    uploadFrame(frame) {
        if (!this.hasGameStart) {
            console.log('uploadFrame game not stared');
            return;
        }

        const action = JSON.stringify(frame);
        const actionList = [action];

        this.server.uploadFrame({
            actionList: actionList,
            success: (res) => {
                console.log('uploadFrame success:', actionList);
            },
            fail: (res) => {
                console.log('uploadFrame fail:', res, actionList);
            }
        });
    }

    broadcast(msg) {
        console.log('broadcast');
        const toPosNumList = msg.recevers;
        let string = JSON.stringify(msg);
        let report = {msg: string};
        if (toPosNumList != undefined) {
            report.toPosNumList = toPosNumList;
        }
        this.server.broadcastInRoom(report);
    }

    getRoomInfo() {
        return this.server.getRoomInfo();
    }

    startGame() {
        this.server.startGame({
            success: (res) => {
                console.log('startGame success', res);
                this.onGameStart();
            },
            fail: (res) => {
                console.log('startGame fail', res);
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

    settle() {
        databus.gameover = true;
    }
}

export default new GameServer();

