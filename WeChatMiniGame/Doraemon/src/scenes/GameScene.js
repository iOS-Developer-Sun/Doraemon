import * as PIXI from '../../libs/pixi.js';
import config from '../config.js';
import databus from '../databus.js';
import { createBtn } from '../common/ui.js';
import { isGreaterThan, pokerCardImage, getJokersCount, getPokerCards, PokerCards, PokerCardsType } from '../../js/poker'
import { arrayByRemovingObjectsFromArray, arrayContainsObjectsFromArray, createArray } from '../common/util.js'

// https://www.flaticon.com/search?author_id=890&style_id=1373&type=standard&word=joker

import {
    createText
} from '../common/ui.js';

import GameSet, { Game, PlayingGame } from '../../js/gameset.js';

export default class GameScene extends PIXI.Container {
    /** @type {number[]} */
    selectedCards = [];

    /** @type {GameServer} */
    gameServer = undefined

    /** @type {number[]} */
    cardList = [];

    /** @type {PIXI.Sprite[]} */
    cardImageViews = [];

    /** @type {PIXI.Sprite} */
    cardsContainerView;

    /** @type {PIXI.Sprite[]} */
    playerViews;

    constructor() {
        super();

        this.playerViews = createArray(databus.max_players_count);
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
            x: 104,
            y: 68,
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
        const w = 465;
        const font = 22;
        const h = 108;

        let box = new PIXI.Container();
        this.box = box;
        this.addChild(box);
        box.x = (config.GAME_WIDTH - w) / 2;
        box.y = 52;
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
        const y = config.GAME_HEIGHT - 350;

        this.newGameButton = createBtn({
            img: 'images/btn_bg.png',
            text: '开始',
            x: config.GAME_WIDTH / 2 - 50,
            y: y,
            width: 178,
            height: 70,
            onclick: () => {
                this.newGame();
            }
        });
        this.addChild(this.newGameButton);
        this.newGameButton.visible = false;

        this.playButton = createBtn({
            img: 'images/btn_bg.png',
            text: '出牌',
            x: config.GAME_WIDTH / 2 - 50,
            y: y,
            width: 178,
            height: 70,
            onclick: () => {
                this.playButtonDidClick();
            }
        });
        this.addChild(this.playButton);
        this.playButton.visible = false;

        this.announceButton = createBtn({
            img: 'images/btn_bg.png',
            text: '宣',
            x: config.GAME_WIDTH / 2 - 50,
            y: y,
            width: 178,
            height: 70,
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
            x: config.GAME_WIDTH / 2 - 50 - 200,
            y: y,
            width: 178,
            height: 70,
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
            x: config.GAME_WIDTH / 2 - 50 + 200,
            y: y,
            width: 178,
            height: 70,
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
        const cardHeight = 200;
        const selectedOffset = cardHeight * 0.2;

        const cardsContainerViewHeight = cardHeight + safeAreaBottom + selectedOffset;
        const cardsContainerViewWidth = config.GAME_WIDTH - 400;
        cardsContainerView.width = cardsContainerViewWidth;
        cardsContainerView.height = cardsContainerViewHeight;

        cardsContainerView.x = 200;
        cardsContainerView.y = config.GAME_HEIGHT - cardsContainerViewHeight;
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
            isDragging: false,
            startCardImageView: null,
            startPoint: null,
            currentPoint: null,
            action: config.panAction.notDetermined,
            cardImageViewsInRange: [],
        }

        cardsContainerView.drmPan = pan;

        cardsContainerView.on("pointerdown", (event) => {
            this.cardsContainerViewPointerDown(event);
        });

        cardsContainerView.on("pointermove", (event) => {
            this.cardsContainerViewPointerMove(event);
        });

        cardsContainerView.on("pointerup", (event) => {
            this.cardsContainerViewPointerUp(event);
        });

        cardsContainerView.on("pointerupoutside", (event) => {
            this.cardsContainerViewPointerUp(event);
        });
    }

    initPlayer() {
        console.log('initPlayer');

        let memberList = this.gameServer.roomInfo.memberList || [];

        var players = createArray(databus.max_players_count);

        if (databus.testMode) {
            memberList.forEach((member, index) => {
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
        var nickname = member.nickname;
        var headimg = member.headimg;

        let imageWidth = 100;
        let playerView = new PIXI.Container();
        playerView.width = imageWidth;
        playerView.height = imageWidth;
        if (index === 0) {
            playerView.x = 100;
            playerView.y = config.GAME_HEIGHT - imageWidth - 100;
        } else if (index === 1) {
            playerView.x = config.GAME_WIDTH - imageWidth - 100;
            playerView.y = 300;
        } else if (index === 2) {
            playerView.x = config.GAME_WIDTH - imageWidth - 100;
            playerView.y = 100;
        } else if (index === 3) {
            playerView.x = 100;
            playerView.y = 100;
        } else {
            playerView.x = 100;
            playerView.y = 300;
        }
        this.addChild(playerView);
        this.playerViews[index] = playerView;

        let avatar = new PIXI.Sprite.from(headimg);
        avatar.x = 0;
        avatar.y = 0;
        avatar.width = imageWidth;
        avatar.height = imageWidth;
        avatar.interactive = false;
        playerView.addChild(avatar);
        playerView.drmAvatar = avatar;

        let name = new PIXI.Text(nickname, { fontSize: 30, align: 'center', fill: 0x515151 });
        name.x = 0;
        name.y = imageWidth + 5;
        playerView.addChild(name);
        playerView.drmName = name;

        let jokerSign = new PIXI.Sprite.from('images/cards/red_joker.png');
        jokerSign.width = 40;
        jokerSign.height = 70;
        jokerSign.x = 0;
        jokerSign.y = - 100;
        jokerSign.visible = false;
        playerView.addChild(jokerSign);
        playerView.drmJokerSign = jokerSign;

        let jokerSign2 = new PIXI.Sprite.from('images/cards/red_joker.png');
        jokerSign2.width = 40;
        jokerSign2.height = 70;
        jokerSign2.x = 50;
        jokerSign2.y = - 100;
        jokerSign2.visible = false;
        playerView.addChild(jokerSign2);
        playerView.drmJokerSign2 = jokerSign2;

        let winnerIndexView = createText({
            str: '',
            style: { fontSize: 28, align: "center", fill: "#FFFF00" },
            left: true,
            x: 0,
            y: 0,
            width: imageWidth,
            height: imageWidth
        });
        winnerIndexView.visible = false;
        playerView.addChild(winnerIndexView);
        playerView.drmWinnerIndexView = winnerIndexView;

        let scoreLabel = createText({
            str: '',
            style: { fontSize: 28, align: "center", fill: "#FFFF00" },
            left: true,
            x: 0,
            y: imageWidth + 50,
            width: imageWidth
        });
        scoreLabel.visible = false;
        playerView.addChild(scoreLabel);
        playerView.drmScoreLabel = scoreLabel;

        let cardBack = new PIXI.Sprite.from('images/cards/back.png');
        cardBack.width = 90;
        cardBack.height = 120;
        if (index === 1) {
            cardBack.x = - 100;
            cardBack.y = 0;
        } else if (index === 2) {
            cardBack.x = - 100;
            cardBack.y = 0;
        } else if (index === 3) {
            cardBack.x = 100;
            cardBack.y = 0;
        } else {
            cardBack.x = 100;
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

    createPlayerInformation(hp, nickname, isName, fn) {
        let name, value;
        isName &&
            (name = createText({
                str: nickname,
                style: { fontSize: 28, align: "center", fill: "#1D1D1D" },
                left: true,
                x: hp.graphics.x,
                y: 96
            }));
        value = createText({
            str: "生命值：",
            style: {
                fontSize: 24,
                fill: "#383838"
            },
            y: hp.graphics.y + hp.graphics.height / 2
        });

        fn(name, value);
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
            this.gameServer.uploadGameSet();
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
        this.gameServer.uploadGameSet();
    }

    playCards(cards) {
        databus.gameSet.playCards(cards);
        this.gameServer.uploadGameSet();
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

    findCardImageViewsInRange() {
        let cardImageViewsInRange = [];
        const pan = this.cardsContainerView.drmPan;
        let startX = pan.startPoint.x;
        let currentX = pan.currentPoint.x;
        const left = Math.min(startX, currentX);
        const right = Math.max(startX, currentX);

        for (let index = this.cardImageViews.length - 1; index >= 0; index--) {
            const cardImageView = this.cardImageViews[index];
            let cardImageViewLeft = cardImageView.x;
            let cardImageViewRight = cardImageView.x + cardImageView.width;
            if (index != this.cardImageViews.length - 1) {
                cardImageViewRight = this.cardImageViews[index + 1].x;
            }
            if (!(left > cardImageViewRight || right < cardImageViewLeft)) {
                cardImageViewsInRange.push(cardImageView);
            }
        }
        return cardImageViewsInRange;
    }

    cardsContainerViewPointerDown(event) {
        const pan = this.cardsContainerView.drmPan;
        pan.isDragging = true;
        pan.startPoint = this.cardsContainerView.toLocal(event.data.global);
        pan.currentPoint = this.cardsContainerView.toLocal(event.data.global);
        pan.cardImageViewLists = this.findCardImageViewsInRange();
        console.log('pointerDown', pan.cardImageViewLists.length);
        if (pan.cardImageViewLists.length > 0) {
            pan.startCardImageView = pan.cardImageViewLists[0];
        }
        this.refreshCardsInRange(pan.cardImageViewLists);
    }

    cardsContainerViewPointerMove(event) {
        const pan = this.cardsContainerView.drmPan;
        pan.currentPoint = this.cardsContainerView.toLocal(event.data.global);
        if (pan.action == config.panAction.notDetermined) {
            pan.cardImageViewLists = this.findCardImageViewsInRange();
            console.log('pointerMove notDetermined', pan.cardImageViewLists.length);
            if (pan.cardImageViewLists.length >= 2) {
                pan.action = config.panAction.selecting;
                this.refreshCardsInRange(pan.cardImageViewLists);
            } else if (pan.currentPoint.y - pan.startPoint.y < -100) {
                if (pan.startCardImageView || this.selectedCards.length > 0) {
                    pan.action = config.panAction.repositioning;
                    this.refreshCardsInRange([]);
                    if (this.selectedCards.length > 0) {
                        pan.cardImageViewLists = this.cardImageViews.filter(cardImageView => this.selectedCards.includes(cardImageView.drmCard));
                    } else {
                        pan.cardImageViewLists = [pan.startCardImageView];
                    }
                    this.refreshRepositioningCardImageViews(pan.cardImageViewLists);
                } else {
                    this.refreshCardsInRange(pan.cardImageViewLists);
                }
            }
        } else if (pan.action == config.panAction.selecting) {
            pan.cardImageViewLists = this.findCardImageViewsInRange();
            console.log('pointerMove selecting', pan.cardImageViewLists.length);
            this.refreshCardsInRange(pan.cardImageViewLists);
        } else if (pan.action == config.panAction.repositioning) {
            console.log('pointerMove repositioning', pan.cardImageViewLists.length);
            this.refreshRepositioningCardImageViews(pan.cardImageViewLists);
        }
    }

    refreshCardsInRange(cardImageViewLists) {
        console.log('refreshCardsInRange', cardImageViewLists.length);
        this.cardImageViews.forEach(cardImageView => {
            if (cardImageViewLists.includes(cardImageView)) {
                cardImageView.tint = 0xAAAAAA;
            } else {
                cardImageView.tint = 0xFFFFFF;
            }
        });
    }

    refreshRepositioningCardImageViews(cardImageViewLists) {
        const pan = this.cardsContainerView.drmPan;
        const xOffset = pan.currentPoint.x - pan.startPoint.x;
        const yOffset = pan.currentPoint.y - pan.startPoint.y;
        cardImageViewLists.forEach((cardImageView, index) => {
            cardImageView.x = pan.currentPoint.x + index * 40;
            cardImageView.y = pan.currentPoint.y;
        });

        this.cardImageViews.forEach(cardImageView => {
            if (cardImageViewLists.includes(cardImageView)) {
                cardImageView.alpha = 0.8;
            } else {
                cardImageView.alpha = 1;
            }
        });
    }

    cardsContainerViewPointerUp(event) {
        const pan = this.cardsContainerView.drmPan;

        if (pan.action == config.panAction.repositioning) {
            pan.cardImageViewLists.forEach(cardImageView => {
                cardImageView.alpha = 1;
            });
        } else {
            pan.cardImageViewLists.forEach(cardImageView => {
                const cardIndex = cardImageView.drmCard;
                let index = this.selectedCards.indexOf(cardIndex);
                if (index !== -1) {
                    this.selectedCards.splice(index, 1);
                } else {
                    this.selectedCards.push(cardIndex);
                }
            });
        }

        pan.isDragging = false;
        pan.startCardImageView = null;
        pan.startPoint = null;
        pan.currentPoint = null;
        pan.action = config.panAction.notDetermined;
        pan.cardImageViewLists = [];

        this.refreshCardsInRange([]);
        this.refreshCards();
        this.refreshSelectAllButton();
        this.refreshState();
    }

    passButtonDidClick() {
        this.gameServer.pass();
    }

    selectAllButtonDidClick() {
        let cardList = this.cardList;
        if (cardList.length == this.selectedCards.length) {
            this.selectedCards = [];
        } else {
            this.selectedCards = cardList.slice();
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

    /**
     * @param {number} cardIndex
     */
    clickCard(cardIndex) {
        let index = this.selectedCards.indexOf(cardIndex);
        if (index !== -1) {
            this.selectedCards.splice(index, 1);
        } else {
            this.selectedCards.push(cardIndex);
        }
        this.refreshSelectAllButton();
        this.refreshCards();
        this.refreshState();
    }

    refreshPlayers() {
        let currentGame = databus.gameSet.currentGame;
        let cardLists = currentGame.cardLists;
        let currentPlayer = databus.gameSet.currentGame.currentPlayer;
        for (let i = 0; i < databus.max_players_count; i++) {
            let localIndex = this.localIndex(i);
            let playerView = this.playerViews[localIndex];

            let label = playerView.drmName;
            label.tint = (i == currentPlayer) ? 0x000000 : 0xFFFFFF;
            label.fill = (i == currentPlayer) ? 0x000000 : 0xFFFFFF;

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
        let cardList = databus.gameSet.currentGame.cardLists[databus.selfPosNum];
        let toAdd = arrayByRemovingObjectsFromArray(cardList, this.cardList);
        let toRemove = arrayByRemovingObjectsFromArray(this.cardList, cardList);
        if (toAdd.length == 0) {
            if (toRemove.length == 0) {
                this.refreshSelectedCards();
                return;
            }

            cardList = arrayByRemovingObjectsFromArray(this.cardList, toRemove);
            this.cardList = cardList;
            this.refreshCardImageViews();
            return;
        }

        this.cardList = cardList.slice().sort((a, b) => b - a);
        this.refreshCardImageViews();
    }

    refreshCardImageViews() {
        this.cardImageViews.forEach(cardImageView => {
            this.cardsContainerView.removeChild(cardImageView);
        });
        this.cardImageViews = [];

        const offset = 40;
        const cardHeight = 200;
        const cardWidth = cardHeight * 250 / 363;
        const selectedOffset = cardHeight * 0.2;
        let width = 0;
        let cardList = this.cardList;
        if (cardList.length > 0) {
            width = (cardList.length - 1) * 40 + cardWidth;
        }

        cardList.forEach((card, index) => {
            let image = pokerCardImage(card);
            let cardImageView = new PIXI.Sprite.from(image);
            cardImageView.x = (this.cardsContainerView.width - width) / 2 + index * offset;
            cardImageView.y = selectedOffset;
            if (this.selectedCards.includes(card)) {
                cardImageView.y = 0;
            }
            cardImageView.width = cardWidth;
            cardImageView.height = cardHeight;
            cardImageView.drmCard = card;
            this.cardsContainerView.addChild(cardImageView);
            this.cardImageViews.push(cardImageView);
        });
    }

    refreshSelectedCards() {
        this.cardImageViews.forEach((cardImageView) => {
            const cardHeight = 200;
            const cardWidth = cardHeight * 250 / 363;
            const selectedOffset = cardHeight * 0.2;
            if (this.selectedCards.includes(cardImageView.drmCard)) {
                cardImageView.y = 0;
            } else {
                cardImageView.y = selectedOffset;
            }
        });
    }

    refreshPlayedCards() {
        this.scrollContainer.removeChildren();
        let hands = databus.gameSet.currentGame.currentRoundHands;
        for (let i = 0; i < hands.length; i++) {
            let hand = hands[i];
            let cards = hand.cards;
            for (let j = 0; j < cards.length; j++) {
                let card = cards[j];
                let image = pokerCardImage(card);
                let cardImageView = new PIXI.Sprite.from(image);
                const cardHeight = 200;
                const cardWidth = cardHeight * 250 / 363;
                cardImageView.x = (this.scrollContainer._width / 2) - (((cards.length / 2) - j) * 40);
                cardImageView.y = i * 60;
                cardImageView.width = cardWidth;
                cardImageView.height = cardHeight;
                this.scrollContainer.addChild(cardImageView);
                this.scrollContainer.y = -this.scrollContainer.height + 200;
            }
        }
    }

    initPlayedCardListScrollView() {
        const scrollContainer = new PIXI.Container();
        scrollContainer.width = config.GAME_WIDTH - 400;
        scrollContainer.height = 300;
        this.scrollContainer = scrollContainer;

        const mask = new PIXI.Graphics();
        mask.beginFill(0x000000);
        mask.drawRect(0, 0, config.GAME_WIDTH, 200);
        mask.endFill();
        scrollContainer.mask = mask;

        const scrollView = new PIXI.Container();
        scrollView.addChild(scrollContainer);
        scrollView.addChild(mask);
        scrollView.mask = mask;
        scrollView.x = 200;
        scrollView.y = 200;
        scrollView.width = config.GAME_WIDTH - 400;
        scrollView.height = 300;
        this.addChild(scrollView);

        scrollView.interactive = true;
        scrollView.on("wheel", (event) => {
            const delta = event.deltaY * 0.5;
            scrollContainer.y = Math.min(0, Math.max(scrollContainer.y - delta, -scrollContainer.height + 200));
        });

        let isDragging = false;
        let startY = 0;
        let startContainerY = 0;

        scrollView.on("pointerdown", (event) => {
            isDragging = true;
            startY = event.data.global.y;
            startContainerY = scrollContainer.y;
        });

        scrollView.on("pointermove", (event) => {
            if (!isDragging) {
                return;
            }
            const newY = startContainerY + (event.data.global.y - startY);
            scrollContainer.y = Math.min(0, Math.max(newY, -scrollContainer.height + 200));
        });

        scrollView.on("pointerup", () => { isDragging = false; });
        scrollView.on("pointerupoutside", () => { isDragging = false; });
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
        this.gameServer.uploadGameSet();

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
            this.gameServer.uploadGameSet();
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

        this.gameServer.uploadGameSet();
    }

    newGame() {
        databus.gameSet.newGame();
        this.gameServer.uploadGameSet();
        setTimeout(() => {
            this.distribute();
        }, 1000);
    }

    refreshSelectAllButton() {
        let cardList = this.cardList;
        if (cardList.length == this.selectedCards.length) {
            this.selectAllButton.titleLabel.text = "全不选";
        } else {
            this.selectAllButton.titleLabel.text = "全选";
        }
        this.selectAllButton.visible = this.cardList.length > 0;
    }

    refresh() {
        this.refreshState();
        this.refreshCards();
        this.refreshPlayedCards();
        this.refreshPlayers();
        this.refreshSelectAllButton();
    }

    refreshState() {
        let msgLabelText = '';
        let announceButtonVisible = false;
        let passButtonVisible = false;
        let playButtonVisible = false;
        let newGameButtonVisible = false;

        const cardList = this.cardList;
        var currentGame = databus.gameSet.currentGame;
        var state = currentGame.state;
        if (state == config.gameState.init) {
            msgLabelText = '即将开始第' + (databus.gameSet.games.length + 1) + '局';
            this.selectedCards = [];
        } else if (state == config.gameState.distributing) {
            msgLabelText = '正在发牌...';
            if (currentGame.announcer == -1) {
                let canAnnounce = getJokersCount(cardList) > 0;
                if (canAnnounce) {
                    announceButtonVisible = true;
                }
            }
        } else if (state == config.gameState.announcing) {
            var announcingCountdown = currentGame.announcingCountdown;
            msgLabelText = '请等待玩家宣(' + announcingCountdown + ')...';
            if (currentGame.announcer == -1) {
                let canAnnounce = getJokersCount(cardList) > 0;
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
                    && cardList.length == 4
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
        this.gameServer.uploadGameSet();
    }

    _destroy() {
        this.gameServer.event.off('onRoomInfoChange');
    }
}

