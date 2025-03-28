import * as PIXI from '../../libs/pixi.js';
import config from '../config.js';
import databus from '../databus.js';
import { createBtn, createText, addCornerRadius } from '../common/ui.js';
import { isGreaterThan, pokerCardImage, getJokersCount, getPokerCards, PokerCards, PokerCardsType } from '../../js/poker'
import { isPointNearPoint, arrayByRemovingObjectsFromArray, arrayIsEqualToArray, createArray } from '../common/util.js'

// https://www.flaticon.com/search?author_id=890&style_id=1373&type=standard&word=joker

import GameSet, { Game, PlayingGame } from '../../js/gameset.js';

export default class GameScene extends PIXI.Container {
    static drmName = 'GameScene';

    /** @type {number[]} */
    selectedCards = [];

    /** @type {GameServer} */
    gameServer = undefined

    reconnecting = false;

    /** @type {number[]} */
    cards = [];

    /** @type {PIXI.Sprite[]} */
    cardViews = [];

    /** @type {PIXI.Sprite[]} */
    finalRoundCardViews = [];

    /** @type {Record<number, PIXI.Sprite>} */
    cardViewsMap = {};

    /** @type {PIXI.Sprite} */
    cardsContainerView;

    /** @type {PIXI.Sprite[]} */
    playerViews = createArray(databus.max_players_count);

    /** @type {string[]} */
    uploadingFrames = [];

    constructor() {
        super();
    }

    selectedCardViews() {
        const selectedCardViews = this.selectedCards.map((selectedCard) => {
            return this.cardViewsMap[selectedCard];
        }).sort((a, b) => {
            return a.x - b.x;
        });
        return selectedCardViews;
    }

    launch(gameServer, options) {
        this.gameServer = gameServer;
        this.initViews();
        this.onRoomInfoChange();
        if (options && options.isFromReconnection) {
            console.log('launch isFromReconnection');
            this.reconnecting = true;
            this.gameServer.requestGameSet();
        } else {
            if (databus.isOwner) {
                setTimeout(() => {
                    this.newGame();
                }, 1000);
            }
        }
    }

    appendBackBtn() {
        const back = createBtn({
            img: 'images/back.png',
            x: 22 + config.safeArea.left,
            y: 42,
            width: 44,
            height: 44,
            onclick: () => {
                this.showModal('离开房间会游戏结束！你确定吗？')
            }
        });

        this.addChild(back);
    }

    onRoomInfoChange() {
        this.gameServer.event.on(
            'onRoomInfoChange',
            (res => {
                this.refreshPlayersInfo();
                res.memberList.length < databus.max_players_count && this.showModal('对方已离开房间', true);
            }).bind(this)
        );
    }

    initViews() {
        const w = 300;
        const font = 14;
        const h = 60;

        let box = new PIXI.Container();
        this.box = box;
        this.addChild(box);
        box.x = (config.windowWidth - w) / 2;
        box.y = 20;
        box.width = w;
        box.height = h + 4;

        let g = new PIXI.Graphics();
        g.lineStyle(2, 5729173, 1);
        g.beginFill(14211288, .7);
        g.drawRoundedRect(0, 0, w, h, 18);
        g.endFill();
        box.addChild(g);

        this.msgLabel = createText({
            str: '正在初始化...',
            align: 'center',
            style: { fontSize: font, fill: '#576B95' },
            left: false,
            x: w / 2,
            y: h / 2,
        });
        this.msgLabel.wordWrap = true;
        this.msgLabel.wordWrapWidth = w;

        box.addChild(this.msgLabel);

        this.initPlayedCardListScrollView();
        this.initCardsContainerView();
        this.initPlayers();
        this.initOpartions();
        this.appendBackBtn();
    }

    initOpartions() {
        const y = config.windowHeight - 180;

        this.newGameButton = createBtn({
            img: 'images/btn_bg.png',
            text: '开始',
            x: config.windowWidth / 2,
            y: y,
            width: 122,
            height: 44,
            onclick: () => {
                this.newGame();
            }
        });
        this.addChild(this.newGameButton);
        this.newGameButton.visible = false;

        this.playButton = createBtn({
            img: 'images/btn_bg.png',
            text: '出牌',
            x: config.windowWidth / 2 + 200,
            y: y,
            width: 122,
            height: 44,
            onclick: () => {
                this.playButtonDidClick();
            }
        });
        this.addChild(this.playButton);
        this.playButton.visible = false;

        this.announceButton = createBtn({
            img: 'images/btn_bg.png',
            text: '宣',
            x: config.windowWidth / 2 - 200,
            y: y,
            width: 122,
            height: 44,
            onclick: () => {
                this.announceButtonDidClick();
            }
        });
        this.addChild(this.announceButton);
        this.announceButton.visible = false;

        this.giveUpAnnouncingButton = createBtn({
            img: 'images/btn_bg.png',
            text: '不宣',
            x: config.windowWidth / 2 + 200,
            y: y,
            width: 122,
            height: 44,
            onclick: () => {
                this.giveUpAnnouncingButtonDidClick();
            }
        });
        this.addChild(this.giveUpAnnouncingButton);
        this.giveUpAnnouncingButton.visible = false;

        this.passButton = createBtn({
            img: 'images/btn_bg.png',
            text: '不要',
            x: config.windowWidth / 2 - 200,
            y: y,
            width: 122,
            height: 44,
            onclick: () => {
                this.passButtonDidClick();
            }
        });
        this.addChild(this.passButton);
        this.passButton.visible = false;
    }

    initCardsContainerView() {
        /** @type {PIXI.Container} */
        let cardsContainerView = new PIXI.Container({ fill: 0xFF0000 })
        const safeAreaBottom = 34;
        const cardHeight = 100;
        const selectedOffset = cardHeight * 0.2;
        const containerLeftMargin = 100;
        const containerRightMargin = 100;

        const cardsContainerViewHeight = cardHeight + safeAreaBottom + selectedOffset;
        const cardsContainerViewWidth = config.windowWidth - containerLeftMargin - containerRightMargin;
        cardsContainerView.width = cardsContainerViewWidth;
        cardsContainerView.height = cardsContainerViewHeight;
        cardsContainerView.x = containerLeftMargin;
        cardsContainerView.y = config.windowHeight - cardsContainerViewHeight;
        cardsContainerView.interactive = true;
        this.cardsContainerView = cardsContainerView;
        this.addChild(cardsContainerView);

        let backgroundColor = new PIXI.Graphics();
        backgroundColor.lineStyle(2, 5729173, 1);
        backgroundColor.beginFill(14211288, .7);
        backgroundColor.drawRoundedRect(0, 0, cardsContainerViewWidth, cardsContainerViewHeight, 18);
        backgroundColor.endFill();
        cardsContainerView.addChild(backgroundColor);

        const pan = {
            containerWidth: cardsContainerView.width,
            containerHeight: cardsContainerView.height,
            isDragging: false,
            startCardView: null,
            startCardViewPosition: null,
            startPoint: null,
            currentPoint: null,
            action: config.panAction.notDetermined,
            cardViewsInAction: [],
            longPressTimer: null,
        }

        cardsContainerView.drmPan = pan;

        cardsContainerView.on('pointerdown', (event) => {
            this.cardsContainerViewPointerDown(event);
        });

        cardsContainerView.on('pointermove', (event) => {
            this.cardsContainerViewPointerMove(event);
        });

        cardsContainerView.on('pointerup', (event) => {
            this.cardsContainerViewPointerUp(event);
        });

        cardsContainerView.on('pointerupoutside', (event) => {
            this.cardsContainerViewPointerUp(event);
        });
    }

    initPlayers() {
        console.log('initPlayers', this.gameServer.roomInfo);
        let memberList = this.gameServer.roomInfo.memberList || [];
        var players = createArray(databus.max_players_count);
        if (databus.testMode) {
            memberList.forEach((member) => {
                players[member.posNum] = member;
            });

            players.forEach((member, index) => {
                if (member == null) {
                    let fake = {
                        clientId: 100 + index,
                        headimg: 'images/joker_ai.png',
                        isReady: true,
                        nickname: '机器人' + index + '(什么都不会)',
                        posNum: index,
                        role: 0
                    };
                    players[index] = fake;
                }
            });
        }

        players.forEach((member, index) => {
            this.createOneUser(this.localIndex(index), member);
        });
        this.players = players;
    }

    createOneUser(index, member) {
        let length = 44;
        let x = 0;
        let y = 0;
        if (index == 0) {
            x = config.safeArea.left;
            y = config.windowHeight - length - 100;
        } else if (index == 1) {
            x = config.windowWidth - length - config.safeArea.right;
            y = config.windowHeight / 5 * 2;
        } else if (index == 2) {
            x = config.windowWidth - length - config.safeArea.right;
            y = 64;
        } else if (index == 3) {
            x = config.safeArea.left;
            y = 64;
        } else {
            x = config.safeArea.left;
            y = config.windowHeight / 5 * 2;
        }

        const playerView = new PIXI.Container();
        playerView.x = x;
        playerView.y = y;
        playerView.width = length;
        playerView.height = length;
        this.addChild(playerView);
        this.playerViews[index] = playerView;

        const avatarContainer = new PIXI.Container();
        avatarContainer.x = 0;
        avatarContainer.y = 0;
        avatarContainer.width = length;
        avatarContainer.height = length;
        playerView.addChild(avatarContainer);
        addCornerRadius(avatarContainer, 8);

        const avatar = new PIXI.Sprite.from(member.headimg);
        avatar.x = 0;
        avatar.y = 0;
        avatar.width = length;
        avatar.height = length;
        avatar.interactive = false;
        avatarContainer.addChild(avatar);
        playerView.drmAvatar = avatar;

        const nameLabel = new PIXI.Text(member.nickname, { fontSize: 14, align: 'center', fill: '#FFFFFF' });
        nameLabel.x = length / 2;
        nameLabel.y = length + 10;
        nameLabel.width = length;
        nameLabel.anchor.set(0.5);
        playerView.addChild(nameLabel);
        playerView.drmNameLabel = nameLabel;

        const winnerIndexView = createText({
            str: '',
            style: {
                fontSize: 14,
                align: 'center',
                fill: '#FFFF00'
            },
            left: true,
            x: 0,
            y: 0,
            width: length,
            height: length
        });
        winnerIndexView.visible = false;
        playerView.addChild(winnerIndexView);
        playerView.drmWinnerIndexView = winnerIndexView;

        const scoreLabel = createText({
            str: '',
            style: { fontSize: 14, align: 'center', fill: '#00FFFF' },
            left: true,
            x: 0,
            y: length + 20,
            width: length
        });
        scoreLabel.visible = false;
        playerView.addChild(scoreLabel);
        playerView.drmScoreLabel = scoreLabel;

        const cardBack = new PIXI.Sprite.from('images/cards/back.png');
        cardBack.width = 40;
        cardBack.height = 60;
        cardBack.visible = false;
        playerView.addChild(cardBack);
        playerView.drmCardBack = cardBack;

        const jokerCard = new PIXI.Sprite.from('images/cards/54.png');
        jokerCard.width = 40;
        jokerCard.height = 60;
        jokerCard.visible = false;
        playerView.addChild(jokerCard);
        playerView.drmJokerCard = jokerCard;

        const jokerCard2 = new PIXI.Sprite.from('images/cards/54.png');
        jokerCard2.width = 40;
        jokerCard2.height = 60;
        jokerCard2.visible = false;
        playerView.addChild(jokerCard2);
        playerView.drmJokerCard2 = jokerCard2;

        const jokerSign = new PIXI.Sprite.from('images/joker.png');
        jokerSign.x = -10;
        jokerSign.y = -30;
        jokerSign.width = 64;
        jokerSign.height = 44;
        jokerSign.visible = false;
        playerView.addChild(jokerSign);
        playerView.drmJokerSign = jokerSign;

        // if (databus.testMode) {
        //     playerView.interactive = true;
        //     playerView.on('pointerdown', () => {
        //         this.test(index);
        //     });
        // }
    }

    updateGameSet(data) {
        databus.gameSet = new GameSet();
        if (data) {
            const gameSet = Object.assign(databus.gameSet, data);
            gameSet.newGame();
            databus.gameSet = gameSet;
            databus.gameSet.currentGame = Object.assign(gameSet.currentGame, data.currentGame);
        }
    }

    senderFromClientId(clientId) {
        const memberList = this.gameServer.roomInfo.memberList;
        for (let index = 0; index < memberList.length; index++) {
            const member = memberList[index];
            if (member.clientId == clientId) {
                return member.posNum;
            }
        }
        return -1;
    }

    clientIdFromSender(sender) {
        const memberList = this.gameServer.roomInfo.memberList;
        for (let index = 0; index < memberList.length; index++) {
            if (member.posNum == sender) {
                return member.clientId;
            }
        }
        return -1;
    }

    handleNewGame(data, sender) {
        const currentPlayer = data.currentPlayer;
        const deck = data.deck;

        databus.gameSet.newGame(currentPlayer);
        databus.gameSet.distribute(deck);
        this.refresh();
    }

    handleAnnouce(data, sender) {
        const currentGame = databus.gameSet.currentGame;
        if (currentGame.state != config.gameState.announcing) {
            return;
        }

        if (data) {
            currentGame.currentPlayer = sender;
            currentGame.announcer = sender;
            currentGame.jokerPlayersPendingAnnouncing = [];
            currentGame.state = config.gameState.playing;
            console.log('currentPlayer', currentGame.currentPlayer);
        } else {
            currentGame.jokerPlayersPendingAnnouncing = currentGame.jokerPlayersPendingAnnouncing.filter(player => player != sender);
            if (currentGame.jokerPlayersPendingAnnouncing.length == 0) {
                currentGame.state = config.gameState.playing;
            }
        }
        this.refresh();
    }

    handlePlayCards(data, sender) {
        const currentGame = databus.gameSet.currentGame;
        if (sender != currentGame.currentPlayer) {
            // bad routine
            databus.halt('logicUpdate PLAYCARDS: sender ' + sender + ' != currentGame.currentPlayer ' + currentGame.currentPlayer);
            return;
        }

        databus.gameSet.playCards(data);
        this.refresh();
    }

    handlePass(data, sender) {
        const currentGame = databus.gameSet.currentGame;
        if (sender != currentGame.currentPlayer) {
            // bad routine
            databus.halt('logicUpdate PASS: sender ' + sender + ' != currentGame.currentPlayer ' + currentGame.currentPlayer);
            return;
        }

        databus.gameSet.pass();
        this.refresh();
    }

    handleReset(data, sender) {
        databus.gameSet = null;
    }

    logicUpdate(frame, frameId) {
        if (databus.gameover) {
            return;
        }

        if (frameId >= 0) {
            if (this.uploadingFrames.length > 0) {
                if (frame === this.uploadingFrames[0]) {
                    console.log('verified frame:', frame);
                    if (!this.uploadFrameVerificationTimer) {
                        databus.halt('No timer?');
                    }
                    this.uploadingFrames.splice(0, 1);
                    this.createReuploadFramesTimerIfNeeded();
                    return;
                }
                console.log('Wrong frame!', frameId);
            }
        }

        const frameObject = JSON.parse(frame);
        if (frameId >= 0) {
            console.log('onSyncFrame action: ', frameObject);
        } else {
            console.log('local action: ', frameObject);
        }

        const version = frameObject.version;
        const action = frameObject.action;
        const data = frameObject.data;
        const clientId = frameObject.from;
        const sender = this.senderFromClientId(clientId);

        if (!databus.gameSet) {
            databus.gameSet = new GameSet();
        }

        if (version != databus.gameSet.version + 1) {
            console.log('Wrong version');
            return;
        }

        databus.gameSet.version = version;

        if (action == 'NEWGAME') {
            this.handleNewGame(data, sender);
            return;
        }

        if (action == 'ANNOUNCE') {
            this.handleAnnouce(data, sender);
            return;
        }

        if (action == 'PLAYCARDS') {
            this.handlePlayCards(data, sender);
            return;
        }

        if (action == 'PASS') {
            this.handlePass(data, sender);
            return;
        }

        if (action == 'RESET') {
            this.handleReset(data, sender);
            return;
        }
    }

    addUploadingFrame(frame) {
        this.uploadingFrames.push(frame);
        this.createReuploadFramesTimerIfNeeded();
    }

    createReuploadFramesTimerIfNeeded() {
        if (this.uploadFrameVerificationTimer != null) {
            clearInterval(this.uploadFrameVerificationTimer);
            this.uploadFrameVerificationTimer = null;
        }

        if (this.uploadingFrames.length == 0) {
            return;
        }

        this.uploadFrameVerificationTimer = setTimeout(() => {
            this.reuploadFrames();
        }, 1000);
    }

    reuploadFrames() {
        this.gameServer.uploadFrame(this.uploadingFrames);
        this.uploadFrameVerificationTimer = setTimeout(() => {
            this.reuploadFrames();
        }, 1000);
    }

    uploadFrame(frameObject) {
        if (frameObject.version == undefined) {
            frameObject.version = databus.gameSet.version + 1;
        }
        if (frameObject.from == undefined) {
            frameObject.from = databus.selfClientId;
        }

        const frame = JSON.stringify(frameObject);
        this.addUploadingFrame(frame);
        this.logicUpdate(frame, -1);

        this.gameServer.uploadFrame([frame]);
    }

    announce(result) {
        this.uploadFrame({
            action: 'ANNOUNCE',
            data: result
        });
    }

    pass() {
        // databus.gameSet.pass();
        this.uploadFrame({
            action: 'PASS'
        });
    }

    playCards(cards) {
        this.uploadFrame({
            action: 'PLAYCARDS',
            data: cards,
        });
    }

    uploadGameSet() {
        this.uploadFrame({
            action: 'GAMESET',
            data: databus.gameSet
        });
        wx.triggerGC();
    }

    preditUpdate(dt) {
        console.log('preditUpdate');
    }

    showModal(content, isCancel) {
        wx.showModal({
            title: '温馨提示',
            content,
            showCancel: !isCancel,
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

    refreshPanSelectingCards(cardViews) {
        this.cardViews.forEach(cardView => {
            if (cardViews.includes(cardView)) {
                cardView.tint = 0xAAAAAA;
            } else {
                cardView.tint = 0xFFFFFF;
            }
        });
    }

    refreshRepositioningCardViews(cardViews) {
        const pan = this.cardsContainerView.drmPan;
        const offset = 25;
        const cardHeight = 100;
        const cardWidth = cardHeight * 225 / 300;

        const startPoint = pan.startPoint;
        const currentPoint = pan.currentPoint;
        const startCardViewPosition = pan.startCardViewPosition;
        if (startPoint != undefined && currentPoint != undefined && startCardViewPosition != undefined) {
            cardViews.forEach((cardView, index) => {
                cardView.x = (currentPoint.x - startPoint.x) + startCardViewPosition.x - (cardViews.length - 1 - index) * offset;
                cardView.y = (currentPoint.y - startPoint.y) + startCardViewPosition.y;
                // cardView.y = 0;
            });
        }

        this.cardViews.forEach(cardView => {
            if (cardViews.includes(cardView)) {
                cardView.alpha = 0.8;
            } else {
                cardView.alpha = 1;
            }
        });
    }

    updateCardsByPosition() {
        const cards = this.cards.slice().sort((a, b) => {
            const x1 = this.cardViewsMap[a].x;
            const x2 = this.cardViewsMap[b].x;
            return x1 - x2;
        });

        if (!arrayIsEqualToArray(this.cards, cards)) {
            this.cards = cards;
        }

        // Sort the cards so that the card on the right appears above the card on the left.
        this.cardsContainerView.children.sort((a, b) => a.x - b.x);
        this.cardViews.sort((a, b) => a.x - b.x);

        this.updateCardViewsByPosition();
    }

    updateCardViewsByPosition() {
        const offset = 25;
        const cardHeight = 100;
        const cardWidth = cardHeight * 225 / 300;

        let width = 0;
        let cards = this.cards;
        if (cards.length > 0) {
            width = (cards.length - 1) * offset + cardWidth;
        }

        const pan = this.cardsContainerView.drmPan;
        const cardViewsInAction = pan.cardViewsInAction;
        const containerWidth = pan.containerWidth;

        cards.forEach((card, index) => {
            const cardView = this.cardViewsMap[card];
            if (!cardViewsInAction.includes(this.cardViewsMap[card])) {
                const containerWidth = this.cardsContainerView.drmPan.containerWidth;
                cardView.x = (containerWidth - width) / 2 + index * offset;
            }
        });
    }

    findCardViewsInAction() {
        let cardViewsInAction = [];
        const pan = this.cardsContainerView.drmPan;
        let startX = pan.startPoint.x;
        let currentX = pan.currentPoint.x;
        const left = Math.min(startX, currentX);
        const right = Math.max(startX, currentX);
        const cardViews = this.cardViews;
        for (let index = cardViews.length - 1; index >= 0; index--) {
            const cardView = cardViews[index];
            let cardViewLeft = cardView.x;
            let cardViewRight = cardView.x + cardView.width;
            if (index != cardViews.length - 1) {
                cardViewRight = cardViews[index + 1].x;
            }
            if (!(left > cardViewRight || right < cardViewLeft)) {
                cardViewsInAction.push(cardView);
            }
        }
        return cardViewsInAction;
    }

    cardsContainerViewPointerDown(event) {
        if (this.cards.length == 0 || databus.gameSet.currentGame.state == config.gameState.finished) {
            return;
        }

        const pan = this.cardsContainerView.drmPan;
        pan.isDragging = true;
        pan.startPoint = this.cardsContainerView.toLocal(event.data.global);
        pan.currentPoint = this.cardsContainerView.toLocal(event.data.global);
        pan.cardViewsInAction = this.findCardViewsInAction();
        console.log('pointerDown', pan.cardViewsInAction.length);
        if (pan.cardViewsInAction.length > 0) {
            pan.startCardView = pan.cardViewsInAction[0];
            pan.startCardViewPosition = { x: pan.startCardView.x, y: pan.startCardView.y };
        }

        if (this.selectedCards.length > 0 || pan.startCardView) {
            pan.longPressTimer = setTimeout(() => {
                if (pan.action != config.panAction.notDetermined) {
                    return;
                }

                pan.action = config.panAction.repositioning;
                wx.vibrateShort('medium');

                if (this.selectedCards.length > 0) {
                    pan.cardViewsInAction = this.selectedCardViews();
                    pan.startCardView = pan.cardViewsInAction[pan.cardViewsInAction.length - 1];
                    pan.startCardViewPosition = { x: pan.startCardView.x, y: pan.startCardView.y };
                } else {
                    pan.cardViewsInAction = [pan.startCardView];
                }
                this.refreshRepositioningCardViews(pan.cardViewsInAction);
                this.updateCardsByPosition();
            }, 500);
        }
    }

    cardsContainerViewPointerMove(event) {
        const pan = this.cardsContainerView.drmPan;
        if (!pan.isDragging) {
            return;
        }

        if (this.cards.length == 0 || databus.gameSet.currentGame.state == config.gameState.finished) {
            return;
        }

        pan.currentPoint = this.cardsContainerView.toLocal(event.data.global);
        if (pan.action == config.panAction.notDetermined) {
            const cardViewsInAction = this.findCardViewsInAction();
            if (cardViewsInAction.length != pan.cardViewsInAction || !isPointNearPoint(pan.startPoint, pan.currentPoint)) {
                if (pan.longPressTimer) {
                    clearTimeout(pan.longPressTimer);
                    pan.longPressTimer = null;
                }
                pan.action = config.panAction.selecting;
                this.refreshPanSelectingCards(pan.cardViewsInAction);
            }
        } else if (pan.action == config.panAction.selecting) {
            pan.cardViewsInAction = this.findCardViewsInAction();
            this.refreshPanSelectingCards(pan.cardViewsInAction);
        } else if (pan.action == config.panAction.repositioning) {
            this.refreshRepositioningCardViews(pan.cardViewsInAction);
            this.updateCardsByPosition();
        }
    }

    cardsContainerViewPointerUp(event) {
        if (this.cards.length == 0 || databus.gameSet.currentGame.state == config.gameState.finished) {
            return;
        }

        const pan = this.cardsContainerView.drmPan;
        if (pan.longPressTimer) {
            clearTimeout(pan.longPressTimer);
            pan.longPressTimer = null;
        }

        let needsToggleSelectAll = true;

        if (pan.action == config.panAction.repositioning) {
            pan.cardViewsInAction.forEach(cardView => {
                cardView.alpha = 1;
            });
        } else {
            needsToggleSelectAll = pan.cardViewsInAction.length == 0;
            pan.cardViewsInAction.forEach(cardView => {
                const cardIndex = cardView.drmCard;
                let index = this.selectedCards.indexOf(cardIndex);
                if (index !== -1) {
                    this.selectedCards.splice(index, 1);
                } else {
                    this.selectedCards.push(cardIndex);
                }
            });
        }

        if (needsToggleSelectAll) {
            let cards = this.cards;
            if (cards.length != 0) {
                this.selectedCards = [];
            } else {
                this.selectedCards = cards.slice();
            }
        }

        pan.isDragging = false;
        pan.startCardView = null;
        pan.startPoint = null;
        pan.currentPoint = null;
        pan.action = config.panAction.notDetermined;
        pan.cardViewsInAction = [];

        this.updateCardsByPosition();

        this.refreshPanSelectingCards([]);
        this.refreshCards();
        this.refreshState();
    }

    passButtonDidClick() {
        this.pass();
    }

    announceButtonDidClick() {
        this.announce(true);
    }

    giveUpAnnouncingButtonDidClick() {
        this.announce(false);
    }

    playButtonDidClick() {
        let pokerCards = getPokerCards(this.selectedCards);
        if (pokerCards == undefined) {
            databus.halt('playButtonDidClick: undfined');
            return;
        }

        this.selectedCards = [];
        let cards = pokerCards.cards;
        this.playCards(cards);
    }

    refreshPlayersInfo() {
        let memberList = this.gameServer.roomInfo.memberList || [];
        for (let i = 0; i < memberList.length; i++) {
            const member = memberList[i];
            const localIndex = this.localIndex(member.posNum);
            const playerView = this.playerViews[localIndex];
            playerView.drmAvatar.texture = PIXI.Texture.from(member.headimg);
            const nameLabel = playerView.drmNameLabel;
            nameLabel.text = member.nickname;
        }
    }

    refreshPlayers() {
        let currentGame = databus.gameSet.currentGame;
        let cardLists = currentGame.cardLists;
        let currentPlayer = databus.gameSet.currentGame.currentPlayer;
        const isFinalRoundOrFinished = (databus.gameSet.currentGame.state == config.gameState.finished || databus.gameSet.currentGame.isFinalRound());

        this.finalRoundCardViews.forEach(cardView => {
            cardView.parent.removeChild(cardView);
        });
        this.finalRoundCardViews = [];

        for (let i = 0; i < databus.max_players_count; i++) {
            let localIndex = this.localIndex(i);
            let playerView = this.playerViews[localIndex];

            const cardBack = playerView.drmCardBack;
            const jokerCard = playerView.drmJokerCard;
            const jokerCard2 = playerView.drmJokerCard2;
            let announcedJokersCount = 0;
            const playerCards = cardLists[i].slice().sort((a, b) => b - a);
            const jokersCount = getJokersCount(playerCards);
            if (currentGame.announcer != -1 && jokersCount == 2) {
                announcedJokersCount = 2;
                jokerCard.visible = true;
                jokerCard2.visible = true;
            } else if (currentGame.announcer != -1 && jokersCount == 1) {
                announcedJokersCount = 1;
                jokerCard.visible = true;
                jokerCard2.visible = false;
            } else {
                jokerCard.visible = false;
                jokerCard2.visible = false;
            }

            playerView.drmJokerSign.visible = currentGame.isObviousJokerPlayer(i);

            let finalRoundCardViewBaseX = 0;
            if (localIndex == 1 || localIndex == 2) {
                cardBack.x = -50 - announcedJokersCount * 10;
                cardBack.y = 0;
                jokerCard.x = cardBack.x + 10;
                jokerCard.y = 0;
                jokerCard2.x = cardBack.x + 20;
                jokerCard2.y = 0;
                finalRoundCardViewBaseX = -50 - playerCards.length * 8;
            } else if (localIndex == 3 || localIndex == 4) {
                cardBack.x = 50;
                cardBack.y = 0;
                jokerCard.x = cardBack.x + 10;
                jokerCard.y = 0;
                jokerCard2.x = cardBack.x + 20;
                jokerCard2.y = 0;
                finalRoundCardViewBaseX = 50;
            } else {
                jokerCard.visible = false;
                jokerCard2.visible = false;
            }

            let winnerIndexView = playerView.drmWinnerIndexView;
            const winnerIndex = currentGame.winners.indexOf(i);
            winnerIndexView.text = winnerIndex == -1 ? '' : (winnerIndex + 1);
            winnerIndexView.visible = winnerIndex != -1;

            const score = currentGame.scores[i];
            const totalScore = databus.gameSet.playerTotalScores[i];
            playerView.drmScoreLabel.text = '得分:' + score + '/' + totalScore;
            playerView.drmScoreLabel.visible = score > 0;
            playerView.drmScoreLabel.visible = true;

            if (i != databus.selfPosNum) {
                let remaining = playerCards.length - announcedJokersCount;
                cardBack.visible = remaining > 0;

                if (databus.testMode) {
                    winnerIndexView.text = remaining + '张';
                    winnerIndexView.visible = true;
                }

                if (isFinalRoundOrFinished) {
                    cardBack.visible = false;
                    jokerCard.visible = false;
                    jokerCard2.visible = false;

                    // show cards
                    for (let index = 0; index < playerCards.length; index++) {
                        const card = playerCards[index];
                        let image = pokerCardImage(card);
                        let cardView = new PIXI.Sprite.from(image);
                        cardView.width = 30;
                        cardView.height = 44;
                        cardView.x = finalRoundCardViewBaseX + index * 8;
                        cardView.y = 0;
                        playerView.addChild(cardView);
                        this.finalRoundCardViews.push(cardView);
                    }
                }
            }
        }
    }

    refreshCards() {
        let cardList = databus.gameSet.currentGame.cardLists[databus.selfPosNum].slice();
        let toAdd = arrayByRemovingObjectsFromArray(cardList, this.cards);
        let toRemove = arrayByRemovingObjectsFromArray(this.cards, cardList);
        if (toAdd.length == 0) {
            if (toRemove.length == 0) {
                this.refreshSelectedCards();
                return;
            }

            cardList = arrayByRemovingObjectsFromArray(this.cards, toRemove);
            this.cards = cardList;
            this.rebuildCardViews();
            return;
        }

        this.cards = cardList.sort((a, b) => b - a);
        this.rebuildCardViews();
    }

    rebuildCardViews() {
        this.cardViews.forEach(cardView => {
            this.cardsContainerView.removeChild(cardView);
        });
        this.cardViews = [];
        this.cardViewsMap = {};

        const offset = 25;
        const cardHeight = 100;
        const cardWidth = cardHeight * 225 / 300;
        const selectedOffset = cardHeight * 0.2;
        let width = 0;
        let cards = this.cards;
        if (cards.length > 0) {
            width = (cards.length - 1) * offset + cardWidth;
        }

        cards.forEach((card, index) => {
            let image = pokerCardImage(card);
            let cardView = new PIXI.Sprite.from(image);
            cardView.x = (this.cardsContainerView.width - width) / 2 + index * offset;
            cardView.y = selectedOffset;
            if (this.selectedCards.includes(card)) {
                cardView.y = 0;
            }
            cardView.width = cardWidth;
            cardView.height = cardHeight;
            cardView.drmCard = card;
            this.cardsContainerView.addChild(cardView);
            this.cardViews.push(cardView);
            this.cardViewsMap[card] = cardView;
        });
    }

    refreshSelectedCards() {
        this.cardViews.forEach((cardView) => {
            const cardHeight = 100;
            const cardWidth = cardHeight * 225 / 300;
            const selectedOffset = cardHeight * 0.2;
            if (this.selectedCards.includes(cardView.drmCard)) {
                cardView.y = 0;
            } else {
                cardView.y = selectedOffset;
            }
        });
    }

    refreshPlayedCards() {
        this.scrollContainer.removeChildren();
        let hands = databus.gameSet.currentGame.currentRoundHands;
        const offset = 25;
        let memberList = this.gameServer.roomInfo.memberList;
        for (let i = 0; i < hands.length; i++) {
            let hand = hands[i];
            let cards = hand.cards;
            let lastCardView = null;
            for (let j = 0; j < cards.length; j++) {
                const card = cards[j];
                const image = pokerCardImage(card);
                const cardView = new PIXI.Sprite.from(image);
                const cardHeight = 100;
                const cardWidth = cardHeight * 225 / 300;
                cardView.x = (this.scrollContainer._width / 2) - (((cards.length / 2) - j) * offset);
                cardView.y = i * 60;
                cardView.width = cardWidth;
                cardView.height = cardHeight;
                lastCardView = cardView;
                this.scrollContainer.addChild(cardView);
                this.scrollContainer.y = -this.scrollContainer.height + this.scrollContainer.drmScrollViewHeight;
            }

            const avatarLength = 30;
            const avatarContainer = new PIXI.Container();
            avatarContainer.width = avatarLength;
            avatarContainer.height = avatarLength;
            avatarContainer.x = lastCardView.x + 35;
            avatarContainer.y = lastCardView.y + 10;
            addCornerRadius(avatarContainer, 5);
            this.scrollContainer.addChild(avatarContainer);            

            const headimg = memberList[hand.player].headimg;
            const avatar = new PIXI.Sprite.from(headimg);
            avatar.width = avatarLength;
            avatar.height = avatarLength;
            avatarContainer.addChild(avatar);
        }
    }

    initPlayedCardListScrollView() {
        const scrollViewHeight = 100;
        const marginX = 200;

        const scrollContainer = new PIXI.Container();
        scrollContainer.width = config.windowWidth - marginX * 2;
        scrollContainer.height = 0;
        this.scrollContainer = scrollContainer;
        this.scrollContainer.drmScrollViewHeight = scrollViewHeight;

        const mask = new PIXI.Graphics();
        mask.beginFill(0x000000);
        mask.drawRect(0, 0, config.windowWidth, 100);
        mask.endFill();
        scrollContainer.mask = mask;

        const scrollView = new PIXI.Container();
        scrollView.addChild(scrollContainer);
        scrollView.addChild(mask);
        scrollView.mask = mask;
        scrollView.x = marginX;
        scrollView.y = 100;
        scrollView.width = config.windowWidth - marginX * 2;
        scrollView.height = 100;
        this.addChild(scrollView);

        scrollView.interactive = true;
        scrollView.on('wheel', (event) => {
            const scrollContainer = this.scrollContainer;
            const delta = event.deltaY * 0.5;
            scrollContainer.y = Math.min(0, Math.max(scrollContainer.y - delta, -scrollContainer.height + scrollContainer.drmScrollViewHeight));
        });

        let isDragging = false;
        let startY = 0;
        let startContainerY = 0;

        scrollView.on('pointerdown', (event) => {
            isDragging = true;
            startY = event.data.global.y;
            startContainerY = scrollContainer.y;
        });

        scrollView.on('pointermove', (event) => {
            if (!isDragging) {
                return;
            }

            const scrollContainer = this.scrollContainer;
            const newY = startContainerY + (event.data.global.y - startY);
            scrollContainer.y = Math.min(0, Math.max(newY, -scrollContainer.height + scrollContainer.drmScrollViewHeight));
        });

        scrollView.on('pointerup', () => {
            isDragging = false;
        });
        scrollView.on('pointerupoutside', () => {
            isDragging = false;
        });
    }

    localIndex(index) {
        var shifted = databus.index(index - databus.selfPosNum);
        return shifted;
    }

    remoteIndex(index) {
        var shifted = databus.index(index + databus.selfPosNum);
        return shifted;
    }


    currentRoundScore() {
        let currentGame = databus.gameSet.currentGame;
        return currentGame.currentRoundScore();
    }

    reset() {
        this.uploadFrame({
            action: 'RESET'
        });
    }

    newGame() {
        let currentPlayer = null;
        if (!databus.gameSet) {
            databus.gameSet = new GameSet();
            currentPlayer = GameSet.randomPlayerIndex();
        }
        const deck = GameSet.shuffle();
        this.uploadFrame({
            action: 'NEWGAME',
            data: {
                deck: deck,
                currentPlayer: currentPlayer
            }
        });
    }

    refresh() {
        this.refreshState();
        this.refreshCards();
        this.refreshPlayedCards();
        this.refreshPlayers();
    }

    refreshState() {
        const currentGame = databus.gameSet.currentGame;
        if (!currentGame) {
            return;
        }

        let msgLabelText = '';
        let announceButtonVisible = false;
        let passButtonVisible = false;
        let playButtonVisible = false;
        let newGameButtonVisible = false;

        const cards = this.cards;
        const state = currentGame.state;
        const gameOrdinalString = '第' + (databus.gameSet.games.length + 1) + '局\n';
        if (state == config.gameState.init) {
            msgLabelText = gameOrdinalString + '即将开始';
            this.selectedCards = [];
        } else if (state == config.gameState.announcing) {
            msgLabelText = gameOrdinalString + '请等待玩家宣...';
            let canAnnounce = currentGame.jokerPlayersPendingAnnouncing.includes(databus.selfPosNum);
            if (canAnnounce) {
                announceButtonVisible = true;
            }
        } else if (state == config.gameState.playing) {
            let score = this.currentRoundScore();
            let player = this.players[currentGame.currentPlayer];
            let name = currentGame.currentPlayer;
            if (player != undefined) {
                name = player.nickname;
            }
            msgLabelText = gameOrdinalString + '请(' + name + ')出牌...\n' + '本轮累计分值：' + score;
            if (currentGame.currentPlayer == databus.selfPosNum) {
                let hands = currentGame.currentRoundHands;
                let lastHandPokerCards = null;
                if (hands.length > 0) {
                    passButtonVisible = true;

                    let lastHand = hands[hands.length - 1];
                    let lastHandPlayer = lastHand.player;
                    if (lastHandPlayer != databus.selfPosNum) {
                        lastHandPokerCards = getPokerCards(lastHand.cards);
                    }
                }

                let canPlayThreeWithOne = (this.selectedCards.length == 4
                    && cards.length == 4
                    && lastHandPokerCards == null);

                /** @type {PokerCards} */
                let pokerCards = getPokerCards(this.selectedCards);
                if (pokerCards != undefined) {
                    if (lastHandPokerCards) {
                        if (isGreaterThan(pokerCards, lastHandPokerCards)) {
                            playButtonVisible = true;
                        }
                    } else {
                        if (canPlayThreeWithOne || pokerCards.type != PokerCardsType.threeWithOne) {
                            playButtonVisible = true;
                        }
                    }
                }
            }
        } else if (state == config.gameState.finished) {
            msgLabelText = gameOrdinalString + '结束';
            newGameButtonVisible = databus.isOwner;
            this.selectedCards = [];
        }

        this.msgLabel.text = msgLabelText;
        this.announceButton.visible = announceButtonVisible;
        this.giveUpAnnouncingButton.visible = announceButtonVisible;
        this.passButton.visible = passButtonVisible;
        this.playButton.visible = playButtonVisible;
        this.newGameButton.visible = newGameButtonVisible;
    }

    test(index) {
        if (!databus.isOwner) {
            return;
        }

        if (index == 0) {
            this.reset();
            this.newGame();
        } else {
            this.uploadFrame({
                action: 'PASS',
                from: this.clientIdFromSender(this.remoteIndex(index))
            });
        }
    }

    _destroy() {
        this.gameServer.event.off('onRoomInfoChange');
    }
}

