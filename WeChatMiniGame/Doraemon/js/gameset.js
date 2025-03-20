import config from "../src/config";
import databus from "../src/databus";
import { getCardsScore } from "./poker";

export class Game {
    /** @type {number[]} */
    scores = [0, 0, 0, 0, 0];

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

    /** @type {number[][]} */
    cardLists = [];

    /** @type {number[]} */
    jokerPlayers = [];

    state = config.gameState.init;
    currentPlayer = -1;
    announcer = -1;
    announcingCountdown = 0;

    /** @type {Hand[]} */
    currentRoundHands = [];

    /** @type {number[]} */
    scores = [0, 0];

    /** @type {number[]} */
    winners = [];

    constructor() {
        this.cardLists = [];
        for (let index = 0; index < databus.max_players_count; index++) {
            this.cardLists.push([]);
        }
    }

    static shuffle() {
        var cards = [];
        if (databus.onePair) {
            const cards_count = 54;
            for (let i = cards_count - 1; i >= 0; i--) {
                cards.push(i * 2);
            }
        } else {
            const cards_count = 108;
            for (let i = cards_count - 1; i >= 0; i--) {
                cards.push(i);
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

        if (databus.max_cards_count > 0) {
            return cards.slice(0, databus.max_cards_count);
        }
        return cards;
    }

    static randomPlayerIndex() {
        return Math.floor(Math.random() * databus.max_players_count);
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

    turnToNextPlayingPlayer() {
        let nextPlayer = this.currentPlayer;
        let count = databus.max_players_count;
        for (let index = 0; index < count; index++) {
            nextPlayer = (nextPlayer + 1) % count;
            if (this.winners.indexOf(nextPlayer) == -1) {
                break;
            }
        }
        if (nextPlayer == this.currentPlayer) {
            // bad routine;
            this.halt();
            return;
        }
        this.currentPlayer = nextPlayer;
    }

    nextCallingPlayer() {
        let lastHandPlayer = this.lastHandPlayer();
        let nextPlayer = this.currentPlayer;
        let count = databus.max_players_count;
        for (let index = 0; index < count; index++) {
            nextPlayer = (nextPlayer + 1) % count;
            if (this.winners.indexOf(nextPlayer) == -1) {
                break;
            }
            if (nextPlayer == lastHandPlayer) {
                break;
            }
        }
        return nextPlayer;
    }

    lastHandPlayer() {
        let hands = this.currentRoundHands;
        let lastHand = hands.at(-1);
        return lastHand.player;
    }
}

export default class GameSet {
    version = 0;

    /** @type {Game[]} */
    games = []

    /** @type {PlayingGame} */
    currentGame = null;

    /** @param {GameSet} gameSet */
    static getFirstPlayerIndex(gameSet) {
        if (gameSet.currentGame) {
            if (gameSet.currentGame.announcer >= 0) {
                return gameSet.currentGame.announcer;
            }
        }

        if (gameSet.games.length === 0) {
            if (databus.testMode) {
                return databus.ownerPosNum;
            }
            return PlayingGame.randomPlayerIndex();
        }

        return gameSet.games[gameSet.games.length - 1].winner;
    }
}
