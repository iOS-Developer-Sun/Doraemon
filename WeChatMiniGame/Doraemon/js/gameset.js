import config from "../src/config";
import databus from "../src/databus";
import { getJokersCount, getCardsScore, isRedJoker } from "./poker";
import { arrayByRemovingObjectsFromArray, numbersArray, createArray, setWithArray, arrayContainsObjectsFromArray, removeObject } from "../src/common/util";
import * as PIXI from '../libs/pixi';

export class Game {
    /** @type {number[]} */
    scores = [];

    winner = -1;
}

export class Hand {
    player = -1;

    /** @type {number[]} */
    cards = [];
}

export class PlayingGame {
    /** @type {number[]} */
    deck = [];

    /** @type {number} */
    jokersCount = 0;

    /** @type {number} */
    totalScore = 0;

    /** @type {number[][]} */
    cardLists = [];

    /** @type {number[]} */
    jokerPlayers = [];
    jokerPlayersPendingAnnouncing = [];

    state = config.gameState.init;
    currentPlayer = -1;
    announcer = -1;

    /** @type {Hand[]} */
    currentRoundHands = [];

    /** @type {number[]} */
    scores = [];

    /** @type {number[]} */
    winners = [];

    constructor() {
        this.cardLists = createArray(databus.max_players_count, (index) => {
            return [];
        });
        this.scores = createArray(databus.max_players_count, 0);
    }

    jokersCountMap() {
        const jokersCountMap = this.jokerPlayers.reduce((map, obj) => {
            map[obj] = (map[obj] || 0) + 1;
            return map;
        }, {});
        return jokersCountMap;
    }

    nonJokerPlayers() {
        let allPlayers = numbersArray(databus.max_players_count);
        return arrayByRemovingObjectsFromArray(allPlayers, this.jokerPlayers);;
    }

    nonWinners() {
        let allPlayers = numbersArray(databus.max_players_count);
        return arrayByRemovingObjectsFromArray(allPlayers, this.winners);
    }

    jokerScore() {
        let score = 0;
        let jokerPlayers = setWithArray(this.jokerPlayers);
        for (let index = 0; index < jokerPlayers.length; index++) {
            score += this.scores[jokerPlayers[index]];
        }
        return score;
    }

    nonJokerScore() {
        let score = 0;
        let nonJokerPlayers = this.nonJokerPlayers();
        for (let index = 0; index < nonJokerPlayers.length; index++) {
            score += this.scores[nonJokerPlayers[index]];
        }
        return score;
    }

    isFinalRound() {
        return arrayContainsObjectsFromArray(this.winners, this.jokerPlayers) || arrayContainsObjectsFromArray(this.winners, this.nonJokerPlayers());
    }

    currentRoundScore() {
        let hands = this.currentRoundHands;
        let totalScore = 0;
        for (let i = 0; i < hands.length; i++) {
            let hand = hands[i];
            let cards = hand.cards;
            let score = getCardsScore(cards);
            totalScore += score;
        }
        return totalScore;
    }

    lastWinner() {
        return this.winners[this.winners.length - 1];
    }

    nonWinnersRemainingCardsScore() {
        let score = 0;
        let nonWinners = this.nonWinners();
        for (let i = 0; i < nonWinners.length; i++) {
            const nonWinner = nonWinners[i];
            const cardList = this.cardLists[nonWinner];
            score += getCardsScore(cardList);
        }
        return score;
    }

    nextPlayingPlayer(index) {
        let nextPlayingPlayer = databus.index(index + 1);
        while (true) {
            if (!this.winners.includes(nextPlayingPlayer)) {
                break;
            }
            nextPlayingPlayer = databus.index(nextPlayingPlayer + 1);
        }
        return nextPlayingPlayer;
    }

    isObviousJokerPlayer(index) {
        const count = this.jokersCountMap()[index];
        if (count == undefined || count == 0) {
            return false;
        }

        if (this.announcer != -1) {
            return true;
        }

        const cardList = this.cardLists[index];
        const jokerCardsCount = getJokersCount(cardList);
        return count > jokerCardsCount;
    }

    lastHandPlayer() {
        let hands = this.currentRoundHands;
        if (hands == undefined || hands.length == 0) {
            return undefined;
        }

        let lastHand = hands[hands.length - 1];
        return lastHand.player;
    }
}

export default class GameSet {
    version = 0;

    /** @type {number} */
    playersCount = databus.max_players_count;

    /** @type {Game[]} */
    games = [];

    /** @type {number[]} */
    playerTotalScores = createArray(this.playersCount, 0);

    /** @type {PlayingGame} */
    currentGame = null;

    /** @type {number[]} */
    playersPendingReady = numbersArray(this.playersCount, 0);

    constructor() {
        this.event = new PIXI.utils.EventEmitter();
    }

    newGame(currentPlayer) {
        this.currentGame = new PlayingGame();
        if (this.games.length > 0) {
            this.currentGame.currentPlayer = this.games[this.games.length - 1].winner;
        } else {
            this.currentGame.currentPlayer = currentPlayer;
        }
        console.log('currentPlayer', this.currentGame.currentPlayer);
    }

    getReady(player) {
        removeObject(this.playersPendingReady, player);
    }

    isAllReady() {
        return this.playersPendingReady.length == 0;
    }

    static shuffle() {
        let cards = [];
        if (databus.test_cards) {
            cards = databus.test_cards.slice();
        } else {
            if (databus.onePair) {
                const cards_count = 54;
                for (let i = cards_count - 1; i >= 0; i--) {
                    let card = i * 2;
                    cards.push(card);
                }
            } else {
                const cards_count = 108;
                for (let i = cards_count - 1; i >= 0; i--) {
                    let card = i;
                    cards.push(card);
                }
            }

            if (!databus.noShuffle) {
                var currentIndex = cards.length;
                while (currentIndex != 0) {
                    let randomIndex = Math.floor(Math.random() * currentIndex);
                    currentIndex--;
                    [cards[currentIndex], cards[randomIndex]] = [
                        cards[randomIndex], cards[currentIndex]];
                }
            }
        }

        let deck = cards;
        if (databus.cards_count > 0) {
            deck = cards.slice(0, databus.cards_count);
        }

        return deck;
    }

    static randomPlayerIndex() {
        return Math.floor(Math.random() * databus.max_players_count);
    }

    distribute(deck) {
        const currentGame = this.currentGame;
        currentGame.deck = deck.slice();
        currentGame.jokersCount = getJokersCount(deck);
        currentGame.totalScore = getCardsScore(deck);
        let currentPlayer = currentGame.currentPlayer;
        deck.forEach(card => {
            currentGame.cardLists[currentPlayer].push(card);
            if (isRedJoker(card)) {
                currentGame.jokerPlayers.push(currentPlayer);
                if (databus.announcing) {
                    currentGame.jokerPlayersPendingAnnouncing.push(currentPlayer);
                }
            }
            currentPlayer = databus.index(currentPlayer + 1);
        });

        if (currentGame.jokerPlayersPendingAnnouncing.length > 0) {
            currentGame.state = config.gameState.announcing;
        } else {
            currentGame.state = config.gameState.playing;
        }
    }

    playCards(cards) {
        const currentGame = this.currentGame;
        const currentPlayer = currentGame.currentPlayer;
        currentGame.cardLists[currentPlayer] = arrayByRemovingObjectsFromArray(currentGame.cardLists[currentPlayer], cards);
        currentGame.currentRoundHands.push({ player: currentPlayer, cards: cards });
        if (!currentGame.isFinalRound() && currentGame.cardLists[currentPlayer].length == 0) {
            currentGame.winners.push(currentPlayer);

            let sortedWinners = currentGame.winners.slice().sort((a, b) => a - b);
            let jokerPlayers = setWithArray(currentGame.jokerPlayers).sort((a, b) => a - b);
            let nonJokerPlayers = currentGame.nonJokerPlayers();

            const jokersWin = sortedWinners.toString() === jokerPlayers.toString();
            if ((jokersWin || sortedWinners.toString() === nonJokerPlayers.toString())) {
                if (databus.springRule) {
                    // TANLE!
                    for (let i = 0; i < currentGame.scores.length; i++) {
                        currentGame.scores[i] = 0;
                    }
                    currentGame.scores[currentGame.winners[0]] = currentGame.totalScore;
                    this.settleGame();
                }
            }
        }

        if (currentGame.state != config.gameState.finished) {
            this.turnToNextPlayingPlayer();
        }
    }

    pass() {
        this.turnToNextPlayingPlayer();
    }

    turnToNextPlayingPlayer() {
        const currentGame = this.currentGame;
        let nextPlayer = currentGame.currentPlayer;
        let isFinalRound = currentGame.isFinalRound();
        let lastHandPlayer = isFinalRound ? currentGame.winners[currentGame.winners.length - 1] : currentGame.lastHandPlayer();
        let settles = false;

        for (let index = 0; index < databus.max_players_count; index++) {
            nextPlayer = databus.index(nextPlayer + 1);
            if (nextPlayer === lastHandPlayer) {
                settles = true;
                break;
            }

            if (!currentGame.winners.includes(nextPlayer)) {
                break;
            }
        }

        if (nextPlayer == this.currentPlayer) {
            // bad routine;
            databus.halt('turnToNextPlayingPlayer nextPlayer == this.currentPlayer' + nextPlayer);
            return;
        }

        currentGame.currentPlayer = nextPlayer;
        if (settles) {
            this.settleHand();
        }
        console.log('currentPlayer', currentGame.currentPlayer);
    }

    turnToNextPlayingTeammate() {
        const currentGame = this.currentGame;
        let currentPlayer = currentGame.currentPlayer;
        let isJokerTeam = currentGame.jokerPlayers.includes(currentPlayer);
        if (isJokerTeam) {
            let teammate = arrayByRemovingObjectsFromArray(currentGame.jokerPlayers, [currentPlayer])[0];
            if (currentGame.isObviousJokerPlayer(teammate)) {
                currentGame.currentPlayer = teammate;
            } else {
                currentGame.currentPlayer = currentGame.nextPlayingPlayer(currentGame.currentPlayer);
            }
        } else {
            let nextPlayingPlayer = currentGame.nextPlayingPlayer(currentGame.currentPlayer);
            while (true) {
                if (!currentGame.isObviousJokerPlayer(nextPlayingPlayer)) {
                    break;
                }
                nextPlayingPlayer = currentGame.nextPlayingPlayer(nextPlayingPlayer);
            }
            currentGame.currentPlayer = nextPlayingPlayer;
        }
    }

    settleHand() {
        let currentGame = this.currentGame;
        let score = currentGame.currentRoundScore();
        let lastHandPlayer = currentGame.lastHandPlayer();
        currentGame.scores[lastHandPlayer] += score;
        if (score > 0) {
            this.event.emit('WINSCORE', { player: lastHandPlayer, score: score });
        }

        if (currentGame.isFinalRound()) {
            currentGame.scores[currentGame.lastWinner()] += currentGame.nonWinnersRemainingCardsScore();
            this.settleGame();
        } else {
            currentGame.currentRoundHands = []
            if (currentGame.winners.includes(currentGame.currentPlayer)) {
                this.turnToNextPlayingTeammate();
            }
        }
    }

    settleGame() {
        const currentGame = this.currentGame;
        let jokerScore = currentGame.jokerScore();
        let nonJokerScore = currentGame.nonJokerScore();
        let winners = currentGame.winners;
        const nonWinners = currentGame.nonWinners().sort((a, b) => {
            return (this.playerTotalScores[a] - this.playerTotalScores[b]) || a - b;
        });

        if (currentGame.jokerPlayers.includes(currentGame.winners[0]) && !currentGame.jokerPlayers.includes(nonWinners[0])) {
            jokerScore += databus.punishmentScore;
            nonJokerScore -= databus.punishmentScore;
        } else if (!currentGame.jokerPlayers.includes(currentGame.winners[0]) && currentGame.jokerPlayers.includes(nonWinners[0])) {
            nonJokerScore += databus.punishmentScore;
            jokerScore -= databus.punishmentScore;
        }

        let jokerCardsCount = currentGame.jokerPlayers.length;
        if (currentGame.announcer != -1) {
            jokerScore *= jokerCardsCount;
        }

        const jokersCountMap = currentGame.jokersCountMap();

        let nonJokerPlayersCount = currentGame.nonJokerPlayers().length;
        let sortedPlayers = winners.slice();
        sortedPlayers.push(...nonWinners);

        for (let i = 0; i < sortedPlayers.length; i++) {
            let index = sortedPlayers[i];
            const isJoker = currentGame.jokerPlayers.includes(index);
            let score = 0;
            if (isJoker) {
                let jokersCount = jokersCountMap[index];
                score = jokerScore * jokersCount / jokerCardsCount;
            } else {
                score = nonJokerScore / nonJokerPlayersCount;
            }
            currentGame.scores[index] = score;
        }
        this.finishGame();
    }

    finishGame() {
        this.games.push({
            scores: this.currentGame.scores,
            winner: this.currentGame.winners[0]
        });
        for (let i = 0; i < this.playerTotalScores.length; i++) {
            this.playerTotalScores[i] += this.currentGame.scores[i];
        }

        this.event.emit('FINISHGAME', this.currentGame.scores.slice());

        this.currentGame.state = config.gameState.finished;
        this.currentGame.currentPlayer = databus.ownerPosNum;
        console.log('currentPlayer', this.currentGame.currentPlayer);

        this.playersPendingReady = numbersArray(databus.max_players_count);
    }
}
