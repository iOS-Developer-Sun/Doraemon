import * as PIXI from '../../libs/pixi.js';
import config from '../config.js';
import databus from '../databus.js';
import { createBtn } from '../common/ui.js';
import { pokerCard, pokerCardCharacter, pokerCardImage, hasRedJoker, getPokerCards, PokerCards, PokerCardsType, getCardsScore } from '../../js/poker'

import Debug from '../base/debug.js';

import {
    createText
} from '../common/ui.js';

import GameSet, { PlayingGame } from '../../js/gameset.js';

export default class GameScene extends PIXI.Container {
    /** @type {number[]} */
    selectedCards = [];

    /** @type {GameServer} */
    gameServer = undefined

    /** @type {number[]} */
    deck = [];

    /** @type {PIXI.Sprite[]} */
    cardsView;

    /** @type {PIXI.Sprite[]} */
    containers;

    constructor() {
        super();

        this.cardsView = this.nullsArray();
        this.containers = this.nullsArray();
    }

    launch(gameServer) {
        this.gameServer = gameServer;

        this.initViews();
        this.onRoomInfoChange();
        this.refresh();
        if (databus.isOwner) {
            this.act();
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
                res.memberList.length < 2 && this.showModal('对方已离开房间，无法继续进行PK！', true);
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
            str: 'Hello',
            style: { fontSize: font, fill: "#576B95" },
            left: true,
            x: 215,
            y: 40,
        });
        this.msgLabel.wordWrap = true;
        this.msgLabel.wordWrapWidth = w;

        box.addChild(this.msgLabel);

        this.initOpartions();
        this.initPlayer();

        this.appendBackBtn();
    }

    initOpartions() {
        const y = config.GAME_HEIGHT - 300;
        this.playButton = createBtn({
            img: 'images/btn_bg.png',
            text: '出牌',
            x: config.GAME_WIDTH / 2 - 50,
            y: y,
            width: 100,
            height: 40,
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
            width: 100,
            height: 40,
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
            x: config.GAME_WIDTH / 2 - 50 + 200,
            y: y,
            width: 100,
            height: 40,
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
            width: 100,
            height: 40,
            onclick: () => {
                this.passButtonDidClick();
            }
        });
        this.addChild(this.passButton);
        this.passButton.visible = false;
    }

    initPlayer() {
        console.log('initPlayer');

        let memberList = this.gameServer.roomInfo.memberList || [];

        var shift = databus.selfPosNum;

        var players = this.nullsArray();

        if (databus.testMode) {
            memberList.forEach((member, index) => {
                players[member.posNum] = member;
            });

            let headimgs = [
                'https://images-cdn.ubuy.qa/651d0932c432ec4330139106-zhenaly-yxinly-sexy-lingerie-for-women.jpg',
                'https://m.media-amazon.com/images/I/61Wu+3WQv8L._AC_SL1500_.jpg',
                'https://image.made-in-china.com/2f0j00RcfVJQjKbhUM/Best-Quality-Lingerie-Femme-Sexy-Lingerie-Black-Sexy-for-Plus-Size-Lingerie-Women.webp',
                'https://st3.depositphotos.com/1074930/18713/i/1600/depositphotos_187135684-stock-photo-sexy-woman-in-bikini-on.jpg',
                'https://st2.depositphotos.com/6444412/10731/i/950/depositphotos_107313254-stock-photo-perfect-sexy-women.jpg',
            ]
            players.forEach((member, index) => {
                if (member == null) {
                    let fake = {
                        clientId: 100 + index,
                        headimg: headimgs[index],
                        isReady: true,
                        nickname: 'AI机器人' + index,
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
    }

    createOneUser(index, member) {
        var nickname = member.nickname;
        var headimg = member.headimg;
        var role = member.role;

        let imageWidth = 100;
        let container = new PIXI.Container();
        container.width = imageWidth;
        container.height = imageWidth;
        if (index === 0) {
            container.x = 100;
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
        this.containers[index] = container;

        let avatar = new PIXI.Sprite.from(headimg);
        avatar.x = 0;
        avatar.y = 0;
        avatar.width = imageWidth;
        avatar.height = imageWidth;
        container.addChild(avatar);

        let name = new PIXI.Text(nickname, { fontSize: 30, align: 'center', fill: 0x515151 });
        name.x = 0;
        name.y = imageWidth + 5;
        container.addChild(name);
        console.log('player: ' + name.text);

        if (databus.testMode) {
            container.interactive = true;
            container.on('pointerdown', () => {
                this.test();
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

    logicUpdate(sender, action, data) {
        if (databus.gameover) {
            return;
        }

        if (action == 'GAMESET') {
            if (sender != databus.selfPosNum) {
                databus.gameSet = data;
            }

            this.refresh();
            return;
        }

        if (databus.ownerPosNum != databus.selfPosNum) {
            // bad routine
            this.halt();
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
                this.halt();
                return;
            }

            let cards = data;
            currentGame.cardLists[currentGame.currentPlayer] = currentGame.cardLists[currentGame.currentPlayer].filter(card => cards.indexOf(card) == -1);
            currentGame.currentRoundPlayedCards.push([currentGame.currentPlayer, cards]);
            currentGame.currentPlayer = (currentGame.currentPlayer + 1) % databus.max_players_count;
            this.gameServer.uploadGameSet();
            return;
        }

        if (action == 'PASS') {
            if (sender != currentGame.currentPlayer) {
                // bad routine
                this.halt();
                return;
            }

            currentGame.currentPlayer = (sender + 1) % databus.max_players_count;
            let lastPokerCards = currentGame.currentRoundPlayedCards;
            if (lastPokerCards.length != 0) {
                let lastHand = lastPokerCards.at(-1);
                let lastHandPlayer = lastHand[0];
                if (lastHandPlayer == sender) {
                    this.settleHand();
                }
            }

            this.gameServer.uploadGameSet();
        }
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

    nullsArray() {
        var array = [];
        for (let i = 0; i < databus.max_players_count; i++) {
            array.push(null);
        }
        return array;
    }

    clearCards() {
        for (const key in this.cardsView) {
            const value = this.cardsView[key];
            this.removeChild(value);
            this.cardsView[key] = null;
        }
    }

    createCardList(cardList, index) {
        /** @type {PIXI.Container} */
        let deckView = new PIXI.Container({ fill: 0xFF0000 })
        if (index == 0) {
            const safeAreaBottom = 34;
            const cardHeight = 200;
            const cardWidth = cardHeight * 250 / 363;
            const selectedOffset = cardHeight * 0.2;

            const deckViewHeight = cardHeight + safeAreaBottom + selectedOffset;

            deckView.width = config.GAME_WIDTH;
            deckView.height = deckViewHeight;

            deckView.x = 0;
            deckView.y = config.GAME_HEIGHT - deckViewHeight;
            this.deck = cardList.sort((a, b) => b - a);
            this.deck.forEach((card, index) => {
                let image = pokerCardImage(card);
                let cardImageView = new PIXI.Sprite.from(image);
                cardImageView.x = (config.GAME_WIDTH / 2) - (((cardList.length / 2) - index) * 40);
                cardImageView.y = selectedOffset;
                if (this.selectedCards.indexOf(card) != -1) {
                    cardImageView.y = 0;
                }
                cardImageView.width = cardWidth;
                cardImageView.height = cardHeight;
                deckView.addChild(cardImageView);

                cardImageView.interactive = true;
                cardImageView.on('pointerdown', () => {
                    this.clickCard(card);
                    console.log('pointerdown');
                });
                // cardImageView.on('pointerup', () => {
                //     console.log('pointerup');
                // });
                // cardImageView.on('pointermove', () => {
                //     console.log('pointermove');
                // });
                // cardImageView.on('pointerover', () => {
                //     console.log('pointerover');
                // });
                // cardImageView.on('pointerleave', () => {
                //     console.log('pointerleave');
                // });
                // cardImageView.on('pointercancel', () => {
                //     console.log('pointercancel');
                // });
            });
        } else if (index == 1) {
            deckView.width = 200;
            deckView.height = 200;
            deckView.x = config.GAME_WIDTH - 100 - 200;
            deckView.y = 300;
        } else if (index === 2) {
            deckView.width = 200;
            deckView.height = 200;
            deckView.x = config.GAME_WIDTH - 100 - 200;
            deckView.y = 100;
        } else if (index === 3) {
            deckView.width = 200;
            deckView.height = 200;
            deckView.x = 200;
            deckView.y = 100;
        } else {
            deckView.width = 200;
            deckView.height = 200;
            deckView.x = 200;
            deckView.y = 300;
        }
        this.cardsView[index] = deckView;
        this.addChild(deckView);
    }

    passButtonDidClick() {
        this.gameServer.pass();
    }

    selectAllButtonDidClick() {
        let cardList = databus.gameSet.currentGame.cardLists[databus.selfPosNum];
        if (cardList.length == this.selectedCards.length) {
            this.selectedCards = [];
        } else {
            this.selectedCards = cardList.slice();
        }
        this.refreshSelectAllButton();
        this.refreshCards();
    }

    announceButtonDidClick() {
        this.gameServer.announce();
    }

    playButtonDidClick() {
        this.gameServer.playCards(this.selectedCards);
        this.selectedCards = [];
        this.refreshCards();
    }

    halt() {
        undefined();
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
        this.refresh();
    }

    refreshPlayers() {
        let currentPlayer = databus.gameSet.currentGame.currentPlayer;
        let index = this.localIndex(currentPlayer);
        for (let i = 0; i < databus.max_players_count; i++) {
            let container = this.containers[i];
            let label = container.children[1];
            label.tint = (i == index) ? 0x000000 : 0xFFFFFF;
            label.fill = (i == index) ? 0x000000 : 0xFFFFFF;
        }
    }

    refreshCards() {
        let cardLists = databus.gameSet.currentGame.cardLists;
        this.clearCards();

        cardLists.forEach((cardList, index) => {
            this.createCardList(cardList, this.localIndex(index));
        });
    }

    localIndex(index) {
        var shift = databus.selfPosNum;
        const max_players_count = databus.max_players_count;
        var shifted = (max_players_count + index - shift) % max_players_count;
        return shifted;
    }

    currentRoundScore() {
        let currentGame = databus.gameSet.currentGame;
        let currentRoundPlayedCards = currentGame.currentRoundPlayedCards;
        let totalScore = 0;
        for (let i = 0; i < currentRoundPlayedCards.length; i++) {
            let hand = currentRoundPlayedCards[i];
            let cards = hand[1];
            let score = getCardsScore(cards);
            totalScore += score;
        }
        return totalScore;
    }

    settleHand() {
        let score = this.currentRoundScore();
        let currentGame = databus.gameSet.currentGame;
        currentGame.currentRoundPlayedCards = [];
        let teamIndex = 0;
        if (currentGame.jokerPlayers.indexOf(currentGame.currentPlayer) != -1) {
            teamIndex = 1;
        }
        let originalScore = currentGame.scores[teamIndex];
        currentGame.scores[teamIndex] += score;
        console.log('Team' + teamIndex + ': ' + originalScore + ' + ' + score + ' = ' + currentGame.scores[teamIndex]);
    }

    distribute() {
        let currentGame = databus.gameSet.currentGame;
        currentGame.state = config.gameState.distributing;
        currentGame.deck = PlayingGame.shuffle();
        let playerIndex = GameSet.getFirstPlayerIndex(databus.gameSet);
        currentGame.currentPlayer = playerIndex;

        console.log("deck: " + "[" + playerIndex + "]" + currentGame.deck);

        this.gameServer.uploadGameSet();

        setTimeout(() => {
            this.distributeCard();
        }, 500);
    }

    distributeCard() {
        let currentGame = databus.gameSet.currentGame;
        if (currentGame.state != config.gameState.distributing) {
            // bad routine
            this.halt();
            return;
        }

        let currentPlayer = currentGame.currentPlayer;
        if (currentGame.deck.length > 0) {
            for (let index = 0; index < currentGame.cardLists.length; index++) {
                if (currentGame.deck.length == 0) {
                    break;
                }

                let card = currentGame.deck.pop()
                currentGame.cardLists[currentPlayer].push(card);
                currentPlayer = (currentPlayer + 1) % databus.max_players_count;
                currentGame.currentPlayer = currentPlayer;
            }
            this.gameServer.uploadGameSet();
            setTimeout(() => {
                this.distributeCard();
            }, 1000);
            return;
        }

        currentGame.jokerPlayers = currentGame.cardLists.filter(cardList => hasRedJoker(cardList));
        if (currentGame.announcer != -1) {
            currentGame.currentPlayer = currentGame.announcer;
            currentGame.state = config.gameState.playing;
        } else {
            currentGame.currentPlayer = databus.ownerPosNum;
            currentGame.state = config.gameState.announcing;
            currentGame.announcingCountdown = databus.announcingCountdown;
            this.countdownAnnouncing();
        }
        this.gameServer.uploadGameSet();
    }

    countdownAnnouncing() {
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
            currentGame.currentPlayer = GameSet.getFirstPlayerIndex(databus.gameSet);
        }

        this.gameServer.uploadGameSet();
    }

    act() {
        var gameSet = databus.gameSet;
        if (!gameSet) {
            gameSet = new GameSet();
            databus.gameSet = gameSet;
        }

        var currentGame = gameSet.currentGame;
        if (!currentGame) {
            currentGame = new PlayingGame();
            gameSet.currentGame = currentGame;
        }

        var state = currentGame.state;
        if (state == config.gameState.init) {
            this.gameServer.uploadGameSet();
            setTimeout(() => {
                this.distribute();
            }, 1000);
        }
    }

    refreshSelectAllButton() {
        let cardList = databus.gameSet.currentGame.cardLists[databus.selfPosNum];
        if (cardList.length == this.selectedCards.length) {
            this.selectAllButton.titleLabel.text = "全不选";
        } else {
            this.selectAllButton.titleLabel.text = "全选";
        }
    }

    refresh() {
        let msgLabelText = '';
        let announceButtonVisible = false;
        let passButtonVisible = false;
        let playButtonVisible = false;
        let selectAllButtonVisible = false;

        var gameSet = databus.gameSet;
        if (!gameSet) {
            return;
        }

        var currentGame = gameSet.currentGame;
        if (!currentGame) {
            return;
        }

        this.refreshCards();
        this.refreshPlayers();

        var state = currentGame.state;
        if (state == config.gameState.init) {
            msgLabelText = '即将开始新的一局';
        } else if (state == config.gameState.distributing) {
            msgLabelText = '正在发牌...';
            if (currentGame.announcer == -1) {
                let canAnnounce = hasRedJoker(currentGame.cardLists[databus.selfPosNum]);
                if (canAnnounce) {
                    announceButtonVisible = true;
                }
            }
        } else if (state == config.gameState.announcing) {
            var announcingCountdown = currentGame.announcingCountdown;
            msgLabelText = '请等待玩家宣(' + announcingCountdown + ')...';
            if (currentGame.announcer == -1) {
                let canAnnounce = hasRedJoker(currentGame.cardLists[databus.selfPosNum]);
                if (canAnnounce) {
                    announceButtonVisible = true;
                }
            }
        } else if (state == config.gameState.playing) {
            let score = this.currentRoundScore();
            msgLabelText = '请(' + currentGame.currentPlayer + ')出牌...\n' + '本轮累计分值：' + score;
            if (currentGame.currentPlayer == databus.selfPosNum) {
                let lastPokerCards = currentGame.currentRoundPlayedCards;
                let lastHandPokerCards = null;
                if (lastPokerCards.length != 0) {
                    passButtonVisible = true;

                    let lastHand = lastPokerCards.at(-1);
                    let lastHandPlayer = lastHand[0];
                    if (lastHandPlayer == databus.selfPosNum) {
                    } else {
                        lastHandPokerCards = getPokerCards(lastPokerCards);
                    }
                }

                let cardList = currentGame.cardLists[currentGame.currentPlayer];
                let canPlayThreeWithOne = (this.selectedCards.length == 4
                    && cardList.length == 4
                    && lastHandPokerCards == null);

                if (cardList.length > 0) {
                    selectAllButtonVisible = true;
                }

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
        }

        this.msgLabel.text = msgLabelText;
        this.announceButton.visible = announceButtonVisible;
        this.passButton.visible = passButtonVisible;
        this.selectAllButton.visible = selectAllButtonVisible;
        this.playButton.visible = playButtonVisible;
    }

    test() {
        var gameSet = databus.gameSet;
        if (!gameSet) {
            return;
        }

        var currentGame = gameSet.currentGame;
        if (!currentGame) {
            return;
        }

        var state = currentGame.state;
        if (state != config.gameState.playing) {
            return;
        }

        if (currentGame.currentPlayer == databus.ownerPosNum) {
            return;
        }

        // help pass;
        currentGame.currentPlayer = (currentGame.currentPlayer + 1) % databus.max_players_count;
        let lastPokerCards = currentGame.currentRoundPlayedCards;
        if (lastPokerCards.length != 0) {
            let lastHand = lastPokerCards.at(-1);
            let lastHandPlayer = lastHand[0];
            if (lastHandPlayer == currentGame.currentPlayer) {
                this.settleHand();
            }
        }

        this.gameServer.uploadGameSet();
    }

    _destroy() {
        this.gameServer.event.off('onRoomInfoChange');
    }
}

