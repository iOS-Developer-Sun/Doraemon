// import { canvas } from '../js/global.js'
import {
    getDeviceInfo
} from './common/util.js';

const deviceinfo = getDeviceInfo();

export default {
    windowWidth: deviceinfo.windowWidth,
    windowHeight: deviceinfo.windowHeight,

    debug: true,

    pixiOptions: {
        backgroundColor: 0,
        antialias: false,
        sharedTicker: true,
        view: canvas,
        resolution: deviceinfo.devicePixelRatio || 1,
        autoDensity: true,
    },

    roomState: {
        inTeam: 1,
        gameStart: 2,
        gameEnd: 3,
        roomDestroy: 4,
    },

    deviceinfo,
    safeArea: {
        left: 0,
        right: 0,
        top: 0,
        bottom: 0
    },

    roleMap: {
        owner: 1,
        partner: 0,
    },

    gameState: {
        init: 0,
        distributing: 1,
        announcing: 2,
        playing: 3,
        finished: 4,
    },

    sortStyle: {
        byValue: 0,
        byCount: 1,
    },

    panAction: {
        notDetermined: 0,
        selecting: 1,
        repositioning: 2,
    },
}

