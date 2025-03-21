import GameSet from '../js/gameset'
import { build_time } from '../js/precompilation.js'

class DataBus {
    /** @type {GameSet} */
    gameSet = null;
    version = build_time;

    constructor() {
        this.testMode = false;
        this.noShuffle = false;
        this.cards_count = 0;
        this.max_players_count = 5;
        this.announcingCountdown = 10;
        this.punishmentScore = 40;
        this.springRule = true;

        // TODO test
        this.testMode = true;
        // this.noShuffle = true;
        this.onePair = true;
        this.punishmentScore = 20;
        this.springRule = false;
        this.cards_count = 20;
        // this.test_cards = [106, 105, 104, 107, 80, 81, 82, 83, 84, 85, 86, 87, 56, 57];
        this.max_players_count = 2;
        this.announcingCountdown = 3;

        this.reset();
    }

    reset() {
        this.gameover = false;
        this.currAccessInfo = '';
        this.playerMap = {};
        this.selfPosNum = 0;
        this.ownerPosNum = -1;
        this.selfClientId = 0;
        this.isOwner = false;
        this.debugMsg = [];
        this.gameSet = null;
        this.userInfo = {};
    }

    index(i) {
        return ((i % this.max_players_count) + this.max_players_count) % this.max_players_count;
    }

    halt(msg = '') {
        console.error(msg);
    }
}

export default new DataBus();

