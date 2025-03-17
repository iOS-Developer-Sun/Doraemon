import config from './config';
import GameSet from '../js/gameset'

class DataBus {
    /** @type {GameSet} */
    gameSet = null;

    constructor() {
        this.testMode = false;
        this.max_cards_count = 0;
        this.max_players_count = 5;
        this.announcingCountdown = 10;

        // TODO test
        this.testMode = true;
        this.max_cards_count = 20;
        this.max_players_count = 2;
        this.announcingCountdown = 3;

        this.reset();
    }

    reset() {
        this.gameover = false;
        this.currAccessInfo = '';
        this.playerMap = {};
        this.playerList = [];
        this.selfPosNum = 0;
        this.ownerPosNum = 0;
        this.selfClientId = 0;
        this.isOwner = false;
        this.debugMsg = [];
        this.gameSet = null;
        this.userInfo = {};
    }
}

export default new DataBus();

