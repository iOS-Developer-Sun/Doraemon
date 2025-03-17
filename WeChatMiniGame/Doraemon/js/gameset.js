import config from "../src/config";
import databus from "../src/databus";
import poker from "./poker";

export class Game {
    /** @type {number[]} */
    scores = [0, 0, 0, 0, 0];

    winner = -1;
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

    /** @type {object[]>[]} */
    currentRoundPlayedCards = []; // [ [0 : [3]], [1 : [5]], ...] 

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
        const cards_count = 108;
        var cards = [];
        for (let i = 0; i < cards_count; i++) {
            cards.push(i);
        }

        var currentIndex = cards_count;
        while (currentIndex != 0) {
            let randomIndex = Math.floor(Math.random() * currentIndex);
            currentIndex--;
            [cards[currentIndex], cards[randomIndex]] = [
                cards[randomIndex], cards[currentIndex]];
        }
        if (databus.max_cards_count) {
            return cards.slice(0, databus.max_cards_count);
        }
        return cards;
    }

    static randomPlayerIndex() {
        return Math.floor(Math.random() * databus.max_players_count);
    }
}

export default class GameSet {
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
