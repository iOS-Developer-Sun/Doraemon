import * as PIXI from '../../libs/pixi.js';
import config from '../config.js';
import databus from '../databus.js';
import { createBtn } from '../common/ui.js';
import { pokerCard, isGreaterThan, pokerCardImage, hasRedJoker, hasRedJokers, getPokerCards, PokerCards, PokerCardsType } from '../../js/poker'

import Debug from '../base/debug.js';

// https://www.flaticon.com/search?author_id=890&style_id=1373&type=standard&word=joker

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

    /** @type {PIXI.Sprite} */
    cardsView;

    /** @type {PIXI.Sprite[]} */
    playerViews;

    constructor() {
        super();

        this.playerViews = this.nullsArray();
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
        this.initPlayedCardListScrollView();
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
                'https://www.flaticon.com/download/icon/5839743?icon_id=5839743&author=449&team=449&keyword=Clown&pack=5839645&style=Flat&style_id=1222&format=png&color=%23000000&colored=2&size=512&selection=1&type=standard&token=03AFcWeA4pdbbxnpawER9WdHKUNmowd63sX4q9YhvH_COPmeAj-QezHKuglKi-OaYfaGmktverv2gptrvJX0Za-lwzgJ2CxdkGGVR2HcOOEA8Y4MT8h7_I7jR06Que_V33x3shZ3CMQkUI7_x4Nsgf3fjte323fgaCIxCpA3nqpQcM-XoIh1wB2nLKX55dJUfNFwEH1bItjfLHpd7efprffE4w1b73NnOOwVVyti_FnyZ9OQDpathInL7_TxStYWB2b8PcTB2S7DgzqQn5F32bvzT-SNJJvuxjmEmKUkWI9iEpsspy1ceiyCFCOgCtE-vQc3te6srAr9Ih_wAQ-mUw7nv4KqBwgzAWJ-qNXlQJlpYVmXvDRO98-HhX0Ey1X5Oj3A4vELvlnkNWUI8vXtcqZkeLWHIWZnmGCTQgw8T-nWPK7FN3G_DsG-MH8cUD9_fAN_gQbdfcvCOzfbXn4hZfTNs6p88Hqzm5luoAewbTzgqBssf4P7HyzoTkNXiy9hUSlGLUnc96yBlfhvStlXtLvphawUJmz6Dixhno6OwlQfR1rieg4ip8n3cRKCRpbAy83IVtZb13FcGVwuW0YP80a3vrzwsBqUZgUFw7ebtROUXIQzm6RJSBripMgXpqOiB35cCC6AuMLo_bvtl7Dq-UK-QOZQT-e9uFMmvZen3_5_hSo00nVzK3k7_exR7prcRnJKl92L3bn-IH92CdOx9Ny1Cy9qxXhrRhxAv8IzZ7blYSHfpeREGwQ2L9b-_Gpjy5xHyWPWMaMVmum2eUhW1vG5vJJT8zZX3veX7w_34nVrQwLzVMoF8NqhztSsjdsnZQ8XKIVJpMwqxGbk12wKH7OggetIWfN-RBy1Ckofr3PTcA4ueYVuMDNXpxX6yJdkLQK6sz6L2hApKRW-o7b0paEYJXAvsxmsnMD73VFIUWqlJ8ieQjixFIWIkHoVpBPba1RavM_wyXlMqVz76C2lehXKW-IMP3m5XCzs3JITlnI2lJZhsErBX4pnZgtQs50ylB7YbulYTbb2WcsUWjAQH_6MNkc33p23UGa6HVnzOAIExrwn6BotOzo9Uc6wvoDrS1uNLLnFBi8_UjAAgLmi4CkYhdMpUlH4iWiYEZAjBZwtGXPuTe2cHtOuoZH0mDAnUn4_E-yPAQBzruqW3dUuVdPyufuYg4oxqY86-DMTkaoQpXSKJ2DI-_BA47nCfcc0jMKN3sXGqP7z0PL4LFUgOi8rtiuBh7QfUKdN7lBOhtJAibUcYQD0BmpzNInZzMMG1eRKq0O8r58yQJhjIvg75XJEfaeEwuiBu_vKpTDsUXX7vBS_opUBCZnJmWIuV4kPCG9n4ec5vqSgIximQ-Oc49T7LHEQz2IP1Dc3QBMwiShc_ppCEJyRvUZrV0TGHe-mOQCybvI0m0dm_bfKub-NAGkALfUYkhFa41AjN1NDeIAEWPV_CFfSbZcHEUmuS0WcmTEnXMNnwdpjeS0iPLhtfNSZHo8Rz_Zj_v9QhhFs61F4PXKExZAM9AINo6ttOygL5OfDcRiyEsa7xZseZSAjqAq6MXJ-5q6zhVWzuHCiJ0RkR48VpMhZxt8RS5LUVvpISw9tIBVyHv230Lo5f-T-SxOMYWZwcswe-PwTUPpGj46IdhQH5neRNOWKNHwYPU5Ti4KzIPRY8cExCAYbX1J0Wg1nICzQ8kjcWk0a0p_LZGBUEUYbw9l8cCg6hdV1ydE9jfidSVXHTd7AUPn7CiUn9NbOXpOUtM6vG_s0hqTACH0eBQ7jv2HIbGJ0_IzqEigcDAjR89iVBCFzOfZ9OnHEdabtkLtkRTLVRV_toxBKS-_v5ZEoWhlyqPpbmLMAP3FTUolzNtOiB-wX_Y5Gmq6q4bbDsGHwsnX5DWIfGPdzAF-o__z39x_jRHp_bbyRiCgm51300K5WN5d76mORX1jyWPEaLFFYlXVKecpzw-yKxLKZ0O0e1LWS2sJs0JwWsw5ugbemAFiuhBVHc6b1FApqxJyNUiluM5TYA_IA&search=joker',
                'https://www.flaticon.com/download/icon/12418493?icon_id=12418493&author=1039&team=1039&keyword=Joker&pack=12418298&style=color+fill&style_id=1373&format=png&color=%23000000&colored=2&size=512&selection=1&type=standard&token=03AFcWeA7mxiEP9gC2hJhTwv3vi-c6v8rFJHvSKzT0O-4Pj7ky4UaGxpIPduTs6195qPG_sB8Jhj2zufyMa2RtuRzppaXk2jfLjVbOiuzxGuH5_wFD7NtNFQR9eM9CQXMyBWudwcRd0xKS4mdtxKRJDlWrCaqi4Akc8jWIds9o1TdYTnjdtD6Tf-bF_LdnKwlKwZ-AxAEUVkViEYYRhawvHb9A9keuPMAM0UvooT3mjOmOE371U_vyeAXtybXmOBKDXoEbup8wYSjV4AIVL6rNQNjfdhCCH3K-oRXZuKmWKqNtkxUx2Z5P7HLwt9U7NvGEjERbiPIh9cNasts3_oEweiofsObfkiufqt46_CAUT6MQd6Wf-auLJGialdimHPBx8gXThwVNnYC4_bUC87ZMtRf5fQnSN7jaNAoyrolLuV5asMm0N-vEO_5arGQm-VwnJBDympRMZAGQasjzslhDyBCWtwHlKS9HH5iwsps0Fc1Y6m2hq5e56nkmrhh02nEoUniznYRIzDsYM0uk1_5MXK04pzCwsoEvupgb-zSH64o9QPMgJYCWJ4HgatuUwDwQcaQK-WhaHHxo9ywTSqUPJC5INiMOAXdDJ7es6LTdQDgdsgIGthRMkmuw50fagWU7vwV_QkP5q6L3zHfyaJx2BgkhYsyWWjLRJiTypO8qSEtm0QAAjWaWXGARKqVGHAtXInvyMm6rYner9u5AtpKgElAEbi0BxHPRRi8VtkfgxNE5bbtUN6CEO4v3nEWQ6nAWec9IYkbzgew-_pOz76MYECSFt3jsG51oQvgic1gVdCT7nN29jSeZBfL6uvWQn3xs6OLN1W5qQ_oItfWH9xhN50pQXrzX7kCOfaldqEUHNz7wYEnEqyEFd0V9OBSP3K4wRND3QRL_IXQRwl6kgEuvTQ6aRghc6R7aUBqzjefDvXtasBZq1NhSVMFyh-_Z0e7RW4UnbGvsSWhwWkLMpYxSkPuJqjhnfH4FjUngq0RCDdMW9FLUbzhbtNjkQ-ux1qeaQaXXdkCysCu1WEZvpmxUePpQxm0xG-R3bkNA3O1ftHG1LohzR7_oL4h8TtUkslpc213x6H_AdZ64hC-4Vdq6WKt_Ewvs96kZU5oQtoHC6houjeoyDx1LO-KRVHLryQ9-BLiCg4PF8wDQEq3l6GSkGhBPMuJ84SNOCa-0k1KUMwjmhOsNdnbMWCznrBiGBHTsXRfosndZq-XmalDym_Tlipc8H3BtMXvje1BwUIIAOfmXmK8KwjqnHNWcBjY_f-rKIv-MclHglFQlymbc-vkF5cAM0xa7KFewWDz70P8_QDrWcU3pMxTDhOH9t7ANGVaN0L_Sd1MjciFobz5Zj4FkEEh7BwW0eqa73nXr2sDIhAvvuQWNCskm5auxNZfED7jH71lQklElKz_rb2VCGJ4iL1t8bx08xS7Q2A8A24dBqPsUDkfL30A4VfH7Ic0ko64rSDg6idARmw_CM3pQOX8QXGWXMGlPfAn5MURl1JY-QqjI-hPrET-SIQF1cv2JzN96R8hTi4Qpgc6_uzkgwrOpsOXwZmG14crL-DglRlNK5sL06_sbbDgjv0fXhw2XDfAEY7rCaKPJmBfAgKRmOrZ1nNYPgJX5hyp4-wxUp0V5RcGe5ygZ07fJPJ77rHrBYgkYYp02nuYWKJg4--bVW8n0imh5K3YGpb4sRlzmWvm3jJrHU1qHesPTsXRz2-gkDiIKTnYIq6Wb6k-uaLzEpPIVUvOtFJ09vpMBK4YwMfBfoIZxxkEXnPgmOG3m2HTRyTVNMWcrvS73EtJni_Gwg_Y0czj4R5ciWBVaClFKicd6aWp2-wj7x42BMv22LnchWK7X-xT8D3p8uUEkmJZLoGFSEnRzaZVU5olg_Ju8BYHhm6Nzme5SqTZM6uTJhVvfTocA9WW_p9WVOc87BGZWakk12JThQqiQq-bYlJ3LWTAAsy8HZBjEr7lE3muP-7qHdYnuvQUQ1givfVRZaWKfEm7FvSpsddvPsrnVGQ&search=joker',
                'https://www.flaticon.com/download/icon/12418312?icon_id=12418312&author=1039&team=1039&keyword=Joker&pack=packs%2Fplaying-card-10&style=1373&format=png&color=%23000000&colored=1&size=512&selection=1&premium=0&type=standard&search=joker',
                'https://www.flaticon.com/download/icon/1624750?icon_id=1624750&author=315&team=315&keyword=Joker&pack=1624731&style=Lineal+Color&style_id=698&format=png&color=%23000000&colored=2&size=512&selection=1&type=standard&search=joker',
                'https://www.flaticon.com/download/icon/2316787?icon_id=2316787&author=270&team=339&keyword=Joker&pack=2316691&style=Lineal&style_id=211&format=png&color=%23000000&colored=1&size=512&selection=1&type=standard&search=joker'
            ]
            players.forEach((member, index) => {
                if (member == null) {
                    let fake = {
                        clientId: 100 + index,
                        headimg: 'images/joker.png', //headimgs[index],
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
        playerView.addChild(avatar);

        let name = new PIXI.Text(nickname, { fontSize: 30, align: 'center', fill: 0x515151 });
        name.x = 0;
        name.y = imageWidth + 5;
        playerView.addChild(name);
        console.log('player: ' + name.text);

        if (databus.testMode) {
            playerView.interactive = true;
            playerView.on('pointerdown', () => {
                this.test();
            });
        }

        let jokerSign = new PIXI.Sprite.from('images/cards/red_joker.png');
        jokerSign.width = 40;
        jokerSign.height = 70;
        jokerSign.x = 0;
        jokerSign.y = - 100;
        jokerSign.visible = false;
        playerView.addChild(jokerSign);

        let jokerSign2 = new PIXI.Sprite.from('images/cards/red_joker.png');
        jokerSign2.width = 40;
        jokerSign2.height = 70;
        jokerSign2.x = 50;
        jokerSign2.y = - 100;
        jokerSign2.visible = false;
        playerView.addChild(jokerSign2);

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

        if (index != 0) {
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
            cardBack.visible = false;
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
                databus.gameSet = Object.assign(new GameSet(), data);
                databus.gameSet.currentGame = Object.assign(new PlayingGame, data.currentGame);
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
            currentGame.currentRoundHands.push({ player: currentGame.currentPlayer, cards: cards });
            if (currentGame.cardLists[currentGame.currentPlayer].length == 0) {
                currentGame.winners.push(currentGame.currentPlayer);
                let winners = currentGame.winners.slice().sort((a, b) => a - b);
                let jokerPlayers = currentGame.jokerPlayers.slice().sort((a, b) => a - b);
                let nonJokerPlayers = [];
                for (let i = 0; i <= databus.max_cards_count; i++) {
                    if (jokerPlayers.indexOf(i) == -1) {
                        nonJokerPlayers.push(i);
                    }
                }
                if (winners == jokerPlayers || winners == nonJokerPlayers) {
                    currentGame.state = config.gameState.finished;
                }
            }

            if (currentGame.state != config.gameState.finished) {
                // next playing player to call
                currentGame.turnToNextPlayingPlayer();
            }

            this.gameServer.uploadGameSet();
            return;
        }

        if (action == 'PASS') {
            if (sender != currentGame.currentPlayer) {
                // bad routine
                this.halt();
                return;
            }

            let nextPlayer = currentGame.nextCallingPlayer();
            currentGame.currentPlayer = nextPlayer;
            if (currentGame.lastHandPlayer() == nextPlayer) {
                this.settleHand();
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

    createCardList(cardList) {
        /** @type {PIXI.Container} */
        let deckView = new PIXI.Container({ fill: 0xFF0000 })
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
        this.cardsView = deckView;
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
        let currentGame = databus.gameSet.currentGame;
        let cardLists = currentGame.cardLists;
        let currentPlayer = databus.gameSet.currentGame.currentPlayer;
        for (let i = 0; i < databus.max_players_count; i++) {
            let localIndex = this.localIndex(i);
            let playerView = this.playerViews[localIndex];

            let label = playerView.children[1];
            label.tint = (i == currentPlayer) ? 0x000000 : 0xFFFFFF;
            label.fill = (i == currentPlayer) ? 0x000000 : 0xFFFFFF;

            let jokerSign = playerView.children[2];
            let jokerSign2 = playerView.children[3];
            let announcedJokersCount = 0;
            if (currentGame.announcer != -1 && hasRedJokers(cardLists[i])) {
                announcedJokersCount = 2;
                jokerSign.visible = true;
                jokerSign2.visible = true;
            } else if (currentGame.announcer != -1 && hasRedJoker(cardLists[i])) {
                announcedJokersCount = 1;
                jokerSign.visible = true;
                jokerSign2.visible = false;
            } else {
                jokerSign.visible = false;
                jokerSign2.visible = false;
            }

            let winnerIndexView = playerView.children[4];
            let winnerIndex = currentGame.winners.indexOf(i);
            winnerIndexView.text = winnerIndex == -1 ? '' : (winnerIndex + 1)

            if (i != 0) {
                let cardBack = playerView.children[5];
                let remaining = cardLists[i].length - announcedJokersCount;
                // cardBack.visible = remaining > 0;
            }
        }
    }

    refreshCards() {
        this.removeChild(this.cardsView);
        this.cardsView = null;

        let cardLists = databus.gameSet.currentGame.cardLists;
        cardLists.forEach((cardList, index) => {
            if (this.localIndex(index) == 0) {
                this.createCardList(cardList);
            }
        });
    }

    refreshPlayedCards() {
        this.lastHandCardsContainer.removeChildren()
        this.scrollContainer.removeChildren();
        let hands = databus.gameSet.currentGame.currentRoundHands;
        for (let i = 0; i < hands.length; i++) {
            let hand = hands[i];
            let cards = hand.cards;
            let isLast = i == hands.length - 1;
            for (let j = 0; j < cards.length; j++) {
                let card = cards[j];
                let image = pokerCardImage(card);
                let cardImageView = new PIXI.Sprite.from(image);
                if (isLast) {
                    const cardHeight = 200;
                    const cardWidth = cardHeight * 250 / 363;            
                    cardImageView.x = (config.GAME_WIDTH / 2) - (((cards.length / 2) - j) * 40);
                    cardImageView.y = 0;
                    cardImageView.width = cardWidth;
                    cardImageView.height = cardHeight;
                    this.lastHandCardsContainer.addChild(cardImageView);
                } else {
                    cardImageView.x = j * 20;
                    cardImageView.y = i * 40;
                    cardImageView.width = 40;
                    cardImageView.height = 60;
                    this.scrollContainer.addChild(cardImageView);
                }
            }
        }
    }

    initPlayedCardListScrollView() {
        const lastHandCardsContainer = new PIXI.Container();
        lastHandCardsContainer.width = config.GAME_WIDTH;
        lastHandCardsContainer.height = 300;
        lastHandCardsContainer.x = 0;
        lastHandCardsContainer.y = (config.GAME_HEIGHT - 300) / 2;
        this.addChild(lastHandCardsContainer);
        this.lastHandCardsContainer = lastHandCardsContainer;

        const scrollContainer = new PIXI.Container();
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

        // scrollable
        scrollView.interactive = true;
        scrollView.on("wheel", (event) => {
            const delta = event.deltaY * 0.5;
            scrollContainer.y = Math.min(0, Math.max(scrollContainer.y - delta, -scrollContainer.height + 200));
        });

        let isDragging = false;
        let startY = 0;
        let startContainerY = 0;

        scrollView.interactive = true;
        scrollView.on("pointerdown", (event) => {
            isDragging = true;
            startY = event.data.global.y;
            startContainerY = scrollContainer.y;
        });

        scrollView.on("pointermove", (event) => {
            if (!isDragging) return;
            const newY = startContainerY + (event.data.global.y - startY);
            scrollContainer.y = Math.min(0, Math.max(newY, -scrollContainer.height + 200));
        });

        scrollView.on("pointerup", () => { isDragging = false; });
        scrollView.on("pointerupoutside", () => { isDragging = false; });
    }

    localIndex(index) {
        var shift = databus.selfPosNum;
        const max_players_count = databus.max_players_count;
        var shifted = (max_players_count + index - shift) % max_players_count;
        return shifted;
    }

    currentRoundScore() {
        let currentGame = databus.gameSet.currentGame;
        return currentGame.currentRoundScore();
    }

    settleHand() {
        let score = this.currentRoundScore();
        let currentGame = databus.gameSet.currentGame;
        currentGame.currentRoundHands = [];
        let teamIndex = 0;
        if (currentGame.jokerPlayers.indexOf(currentGame.currentPlayer) != -1) {
            teamIndex = 1;
        }
        let originalScore = currentGame.scores[teamIndex];
        currentGame.scores[teamIndex] += score;
        console.log('Team' + teamIndex + ': ' + originalScore + ' + ' + score + ' = ' + currentGame.scores[teamIndex]);

        if (currentGame.winners.indexOf(currentGame.currentPlayer) != -1) {
            currentGame.turnToNextPlayingPlayer();
        }
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
        this.refreshPlayedCards();
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
                let hands = currentGame.currentRoundHands;
                let lastHandPokerCards = null;
                if (hands.length > 0) {
                    passButtonVisible = true;

                    let lastHand = hands.at(-1);
                    let lastHandPlayer = lastHand.player;
                    if (lastHandPlayer != databus.selfPosNum) {
                        lastHandPokerCards = getPokerCards(lastHand.cards);
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
        let lastPokerCards = currentGame.currentRoundHands;
        if (lastPokerCards.length != 0) {
            let lastHand = lastPokerCards.at(-1);
            let lastHandPlayer = lastHand.player;
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

