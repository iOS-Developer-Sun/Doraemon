import * as PIXI from '../../libs/pixi.js';
import config from '../config.js';

export default class BackGround extends PIXI.Sprite {
    constructor() {
        let texture = PIXI.Texture.from('images/bg.jpg');
        super(texture);

        this.fill();
    }

    fill() {
        this.width = config.windowWidth;
        this.height = config.windowHeight;
    }
}
