import * as PIXI from '../../libs/pixi.js';
import config from '../config.js';
import databus from '../databus.js';
import { createBtn, createText } from '../common/ui.js';
import { isGreaterThan, pokerCardImage, getJokersCount, getPokerCards, PokerCards, PokerCardsType } from '../../js/poker'
import { isPointNearPoint, arrayByRemovingObjectsFromArray, arrayIsEqualToArray, createArray } from '../common/util.js'

// https://www.flaticon.com/search?author_id=890&style_id=1373&type=standard&word=joker

import GameSet, { Game, PlayingGame } from '../../js/gameset.js';

export default class GameScene extends PIXI.Container {
    /** @type {number[]} */
    selectedCards = [];

    /** @type {GameServer} */
    gameServer = undefined

    /** @type {number[]} */
    cards = [];

    /** @type {PIXI.Sprite[]} */
    cardViews = [];

    /** @type {Record<number, PIXI.Sprite>} */
    cardViewsMap = {};

    /** @type {PIXI.Sprite} */
    cardsContainerView;

    /** @type {PIXI.Sprite[]} */
    playerViews;

    constructor() {
        super();

        this.playerViews = createArray(databus.max_players_count);
    }

    selectedCardViews() {
        const selectedCardViews = this.selectedCards.map((selectedCard) => {
            return this.cardViewsMap[selectedCard];
        }).sort((a, b) => {
            return a.x - b.x;
        });
        return selectedCardViews;
    }

    launch(gameServer) {
        this.gameServer = gameServer;

        this.initViews();
        this.onRoomInfoChange();
        if (databus.isFromReconnection && this.gameServer.roomInfo.memberList.length > 1) {
            this.gameServer.requestGameSet();
        } else {
            if (databus.isOwner) {
                this.updateGameSet();
                this.newGame();
                this.refresh();
            }
        }
    }

    appendBackBtn() {
        const back = createBtn({
            img: 'images/goBack.png',
            x: 60 + config.safeArea.left,
            y: 42,
            width: 120,
            height: 44,
            onclick: () => {
                this.showModal('离开房间会游戏结束！你确定吗？')
            }
        });

        this.addChild(back);
    }

    onRoomInfoChange() {
        this.gameServer.event.on(
            "onRoomInfoChange",
            (res => {
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
            style: { fontSize: font, fill: "#576B95" },
            left: false,
            x: w / 2,
            y: h / 2,
        });
        this.msgLabel.wordWrap = true;
        this.msgLabel.wordWrapWidth = w;

        box.addChild(this.msgLabel);

        this.initPlayedCardListScrollView();
        this.initCardsContainerView();
        this.initPlayer();
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
            x: config.windowWidth / 2,
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
            x: config.windowWidth / 2,
            y: y,
            width: 122,
            height: 44,
            onclick: () => {
                this.announceButtonDidClick();
            }
        });
        this.addChild(this.announceButton);
        this.announceButton.visible = false;

        // left
        this.selectAllButton = createBtn({
            img: 'images/btn_bg.png',
            text: '全选',
            x: config.windowWidth / 2 - 200,
            y: y,
            width: 122,
            height: 44,
            onclick: () => {
                this.selectAllButtonDidClick();
            }
        });
        this.addChild(this.selectAllButton);
        this.selectAllButton.visible = false;

        // right
        this.passButton = createBtn({
            img: 'images/btn_bg.png',
            text: '不要',
            x: config.windowWidth / 2 + 200,
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

    initPlayer() {
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
                        headimg: 'images/joker.png',
                        isReady: true,
                        nickname: '机器人' + index,
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

        let playerView = new PIXI.Container();
        playerView.x = x;
        playerView.y = y;
        playerView.width = length;
        playerView.height = length;
        this.addChild(playerView);
        this.playerViews[index] = playerView;

        let avatar = new PIXI.Sprite.from(member.headimg);
        avatar.x = 0;
        avatar.y = 0;
        avatar.width = length;
        avatar.height = length;
        avatar.interactive = false;
        playerView.addChild(avatar);
        playerView.drmAvatar = avatar;

        let nameLabel = new PIXI.Text(member.nickname, { fontSize: 14, align: 'center', fill: 0x515151 });
        nameLabel.x = 0;
        nameLabel.y = length + 2;
        playerView.addChild(nameLabel);
        playerView.drmNameLabel = nameLabel;

        let jokerSign = new PIXI.Sprite.from('images/cards/54.png');
        jokerSign.width = 22.5;
        jokerSign.height = 30;
        jokerSign.x = 0;
        jokerSign.y = - 32;
        jokerSign.visible = false;
        playerView.addChild(jokerSign);
        playerView.drmJokerSign = jokerSign;

        let jokerSign2 = new PIXI.Sprite.from('images/cards/54.png');
        jokerSign.width = 22.5;
        jokerSign.height = 30;
        jokerSign2.x = 22;
        jokerSign2.y = - 32;
        jokerSign2.visible = false;
        playerView.addChild(jokerSign2);
        playerView.drmJokerSign2 = jokerSign2;

        let winnerIndexView = createText({
            str: '',
            style: { fontSize: 14, align: "center", fill: "#FFFF00" },
            left: true,
            x: 0,
            y: 0,
            width: length,
            height: length
        });
        winnerIndexView.visible = false;
        playerView.addChild(winnerIndexView);
        playerView.drmWinnerIndexView = winnerIndexView;

        let scoreLabel = createText({
            str: '',
            style: { fontSize: 14, align: "center", fill: "#00FFFF" },
            left: true,
            x: 0,
            y: length + 20,
            width: length
        });
        scoreLabel.visible = false;
        playerView.addChild(scoreLabel);
        playerView.drmScoreLabel = scoreLabel;

        let cardBack = new PIXI.Sprite.from('images/cards/back.png');
        cardBack.width = 40;
        cardBack.height = 60;
        if (index == 1) {
            cardBack.x = - 50;
            cardBack.y = 0;
        } else if (index == 2) {
            cardBack.x = - 50;
            cardBack.y = 0;
        } else if (index == 3) {
            cardBack.x = 50;
            cardBack.y = 0;
        } else {
            cardBack.x = 50;
            cardBack.y = 0;
        }
        playerView.addChild(cardBack);
        playerView.drmCardBack = cardBack;
        cardBack.visible = false;

        if (databus.testMode) {
            playerView.interactive = true;
            playerView.on('pointerdown', () => {
                this.test(index);
            });
        }
    }

    renderUpdate(dt) {
        if (databus.gameover) {
            return;
        }
        console.log("renderUpdate");
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

    logicUpdate(sender, action, data) {
        if (databus.gameover) {
            return;
        }

        if (action == 'REQUESTGAMESET') {
            if (sender == databus.selfPosNum) {
                return;
            }

            if (this.gameServer.reconnecting) {
                return;
            }

            this.gameServer.respondGameSet(sender);
            return;
        }

        if (action == 'RESPONDGAMESET') {
            if (databus.isFromReconnection) {
                databus.isFromReconnection = false;
                this.updateGameSet(data);
                this.refresh();
            }
            return;
        }

        if (action == 'GAMESET') {
            if (sender != databus.selfPosNum) {
                this.updateGameSet(data);
            }

            this.refresh();
            return;
        }

        if (databus.ownerPosNum != databus.selfPosNum) {
            // bad routine
            databus.halt('logicUpdate GAMESET: databus.ownerPosNum ' + databus.ownerPosNum + ' != databus.selfPosNum ' + databus.selfPosNum);
            return;
        }

        console.log('ACTION: ' + action);

        let currentGame = databus.gameSet.currentGame;
        if (action == 'ANNOUNCE') {
            if (currentGame.announcer >= 0 || (currentGame.state != config.gameState.distributing && currentGame.state != config.gameState.announcing)) {
                return;
            }

            currentGame.announcer = sender;
            currentGame.announcingCountdown = 0;
            if (currentGame.state == config.gameState.announcing) {
                currentGame.state = config.gameState.playing;
                currentGame.currentPlayer = sender;
            }
            this.uploadGameSet();
            return;
        }

        if (action == 'PLAYCARDS') {
            if (sender != currentGame.currentPlayer) {
                // bad routine
                databus.halt('logicUpdate PLAYCARDS: sender ' + sender + ' != currentGame.currentPlayer ' + currentGame.currentPlayer);
                return;
            }

            this.playCards(data);
            return;
        }

        if (action == 'PASS') {
            if (sender != currentGame.currentPlayer) {
                // bad routine
                databus.halt('logicUpdate PASS: sender ' + sender + ' != currentGame.currentPlayer ' + currentGame.currentPlayer);
                return;
            }

            this.pass();
            return;
        }
    }

    pass() {
        databus.gameSet.pass();
        this.uploadGameSet();
    }

    playCards(cards) {
        databus.gameSet.playCards(cards);
        this.uploadGameSet();
    }

    uploadGameSet() {
        this.gameServer.uploadGameSet();
        wx.triggerGC();
    }

    preditUpdate(dt) {
        console.log("preditUpdate");
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

    renderUpdate(dt) {
        if (databus.gameover) {
            return;
        }
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

        cardViews.forEach((cardView, index) => {
            cardView.x = (pan.currentPoint.x - pan.startPoint.x) + pan.startCardViewPosition.x - (cardViews.length - 1 - index) * offset;
            cardView.y = (pan.currentPoint.y - pan.startPoint.y) + pan.startCardViewPosition.y;
            // cardView.y = 0;
        });

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
        if (this.cards.length == 0) {
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

        if (this.cards.length == 0) {
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
        if (this.cards.length == 0) {
            return;
        }

        const pan = this.cardsContainerView.drmPan;
        if (pan.longPressTimer) {
            clearTimeout(pan.longPressTimer);
            pan.longPressTimer = null;
        }

        let needDeselectAll = true;

        if (pan.action == config.panAction.repositioning) {
            pan.cardViewsInAction.forEach(cardView => {
                cardView.alpha = 1;
            });
        } else {
            needDeselectAll = pan.cardViewsInAction.length == 0;
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

        if (needDeselectAll) {
            this.selectedCards = [];
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
        this.refreshSelectAllButton();
        this.refreshState();
    }

    passButtonDidClick() {
        this.gameServer.pass();
    }

    selectAllButtonDidClick() {
        let cards = this.cards;
        if (cards.length == this.selectedCards.length) {
            this.selectedCards = [];
        } else {
            this.selectedCards = cards.slice();
        }
        this.refreshSelectAllButton();
        this.refreshCards();
        this.refreshState();
    }

    announceButtonDidClick() {
        this.gameServer.announce();
    }

    playButtonDidClick() {
        let pokerCards = getPokerCards(this.selectedCards);
        if (pokerCards == undefined) {
            databus.halt('playButtonDidClick: undfined');
            return;
        }

        let cards = pokerCards.cards;
        this.gameServer.playCards(cards);
        this.selectedCards = [];
        this.refreshCards();
    }

    refreshPlayers() {
        let currentGame = databus.gameSet.currentGame;
        let cardLists = currentGame.cardLists;
        let currentPlayer = databus.gameSet.currentGame.currentPlayer;
        for (let i = 0; i < databus.max_players_count; i++) {
            let localIndex = this.localIndex(i);
            let playerView = this.playerViews[localIndex];

            let nameLabel = playerView.drmNameLabel;
            nameLabel.tint = (i == currentPlayer) ? 0x000000 : 0xFFFFFF;
            nameLabel.fill = (i == currentPlayer) ? 0x000000 : 0xFFFFFF;

            let jokerSign = playerView.drmJokerSign;
            let jokerSign2 = playerView.drmJokerSign2;
            let announcedJokersCount = 0;
            const jokersCount = getJokersCount(cardLists[i]);
            if (currentGame.announcer != -1 && jokersCount == 2) {
                announcedJokersCount = 2;
                jokerSign.visible = true;
                jokerSign2.visible = true;
            } else if (currentGame.announcer != -1 && jokersCount == 1) {
                announcedJokersCount = 1;
                jokerSign.visible = true;
                jokerSign2.visible = false;
            } else {
                jokerSign.visible = false;
                jokerSign2.visible = false;
            }

            let winnerIndexView = playerView.drmWinnerIndexView;
            const winnerIndex = currentGame.winners.indexOf(i);
            winnerIndexView.text = winnerIndex == -1 ? '' : (winnerIndex + 1);
            winnerIndexView.visible = winnerIndex != -1;

            // TODO
            const score = currentGame.scores[i];
            const totalScore = databus.gameSet.playerTotalScores[i];
            playerView.drmScoreLabel.text = '得分:' + score + '/' + totalScore;
            playerView.drmScoreLabel.visible = score > 0;
            playerView.drmScoreLabel.visible = true;

            if (cardLists && i != databus.selfPosNum) {
                let cardBack = playerView.drmCardBack;
                let remaining = cardLists[i].length - announcedJokersCount;
                cardBack.visible = remaining > 0;

                if (databus.testMode) {
                    winnerIndexView.text = remaining + '张';
                    winnerIndexView.visible = true;
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
        for (let i = 0; i < hands.length; i++) {
            let hand = hands[i];
            let cards = hand.cards;
            for (let j = 0; j < cards.length; j++) {
                let card = cards[j];
                let image = pokerCardImage(card);
                let cardView = new PIXI.Sprite.from(image);
                const cardHeight = 100;
                const cardWidth = cardHeight * 225 / 300;
                cardView.x = (this.scrollContainer._width / 2) - (((cards.length / 2) - j) * offset);
                cardView.y = i * 60;
                cardView.width = cardWidth;
                cardView.height = cardHeight;
                this.scrollContainer.addChild(cardView);
                this.scrollContainer.y = -this.scrollContainer.height + this.scrollContainer.drmScrollViewHeight;
            }
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
        scrollView.on("wheel", (event) => {
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

    currentRoundScore() {
        let currentGame = databus.gameSet.currentGame;
        return currentGame.currentRoundScore();
    }

    distribute() {
        if (!databus.gameSet) {
            return;
        }

        databus.gameSet.shuffle();
        console.log("deck: " + "[" + databus.gameSet.currentGame.currentPlayer + "]" + databus.gameSet.currentGame.deck);
        this.uploadGameSet();

        setTimeout(() => {
            this.distributeCard();
        }, 500);
    }

    distributeCard() {
        if (!databus.gameSet) {
            return;
        }

        let currentGame = databus.gameSet.currentGame;
        if (currentGame.state != config.gameState.distributing) {
            // bad routine
            databus.halt('distributeCard: wrong state ' + currentGame.state);
            return;
        }

        databus.gameSet.distributeCard();
        if (currentGame.state == config.gameState.distributing) {
            setTimeout(() => {
                this.distributeCard();
            }, 1000);
            this.uploadGameSet();
            return;
        }

        if (currentGame.state = config.gameState.announcing) {
            this.countdownAnnouncing();
        }
    }

    countdownAnnouncing() {
        if (!databus.gameSet) {
            return;
        }

        let currentGame = databus.gameSet.currentGame;
        if (currentGame.state != config.gameState.announcing) {
            return;
        }

        if (currentGame.announcingCountdown > 0) {
            currentGame.announcingCountdown -= 1;
            setTimeout(() => {
                this.countdownAnnouncing()
            }, 1000);
        } else {
            currentGame.state = config.gameState.playing;
        }

        this.uploadGameSet();
    }

    newGame() {
        databus.gameSet.newGame();
        this.uploadGameSet();
        setTimeout(() => {
            this.distribute();
        }, 1000);
    }

    refreshSelectAllButton() {
        let cards = this.cards;
        if (cards.length == this.selectedCards.length) {
            this.selectAllButton.drmTitleLabel.text = "全不选";
        } else {
            this.selectAllButton.drmTitleLabel.text = "全选";
        }
        this.selectAllButton.visible = this.cards.length > 0;
    }

    refresh() {
        this.refreshState();
        this.refreshCards();
        this.refreshPlayedCards();
        this.refreshPlayers();
        this.refreshSelectAllButton();
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
        if (state == config.gameState.init) {
            msgLabelText = '即将开始第' + (databus.gameSet.games.length + 1) + '局';
            this.selectedCards = [];
        } else if (state == config.gameState.distributing) {
            msgLabelText = '正在发牌...';
            if (currentGame.announcer == -1) {
                let canAnnounce = getJokersCount(cards) > 0;
                if (canAnnounce) {
                    announceButtonVisible = true;
                }
            }
        } else if (state == config.gameState.announcing) {
            var announcingCountdown = currentGame.announcingCountdown;
            msgLabelText = '请等待玩家宣(' + announcingCountdown + ')...';
            if (currentGame.announcer == -1) {
                let canAnnounce = getJokersCount(cards) > 0;
                if (canAnnounce) {
                    announceButtonVisible = true;
                }
            }
        } else if (state == config.gameState.playing) {
            let score = this.currentRoundScore();
            let player = this.players[currentGame.currentPlayer];
            let name = currentGame.currentPlayer;
            if (player != undefined) {
                name = player.nickname;
            }
            msgLabelText = '请(' + name + ')出牌...\n' + '本轮累计分值：' + score;
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
            msgLabelText = '游戏结束';
            newGameButtonVisible = databus.isOwner;
            this.selectedCards = [];
        }

        this.msgLabel.text = msgLabelText;
        this.announceButton.visible = announceButtonVisible;
        this.passButton.visible = passButtonVisible;
        this.playButton.visible = playButtonVisible;
        this.newGameButton.visible = newGameButtonVisible;
    }

    test(index) {
        if (!databus.isOwner) {
            return;
        }

        if (index == 0) {
            this.updateGameSet();
            this.newGame();
        } else {
            this.pass();
        }
        this.uploadGameSet();
    }

    _destroy() {
        this.gameServer.event.off('onRoomInfoChange');
    }
}

