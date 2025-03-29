import * as PIXI from '../../libs/pixi.js';

export function createBtn(options) {
    let { img, text, x, y, onclick, width, height, style } = options;

    let btn = PIXI.Sprite.from(img);
    btn.anchor.set(0.5);
    btn.x = x;
    btn.y = y;

    if (width) {
        btn.width = width;
    }
    if (height) {
        btn.height = height;
    }

    if (onclick && typeof onclick === 'function') {
        btn.interactive = true;
        btn.on('pointerdown', onclick);
    }

    if (text) {
        let _text = new PIXI.Text(text, style || { fontSize: 32, align: 'center' });
        _text.anchor.set(0.5);

        btn.addChild(_text);
        btn.drmTitleLabel = _text;
    }

    return btn;
}

export function createText(options) {
    const { str, x, y } = options;
    const style = options.style || { fontSize: 36, align: 'center' };

    let text = new PIXI.Text(str, style);
    if (!options.left) {
        text.anchor.set(0.5);
    }
    text.x = x || 0;
    text.y = y || 0;

    return text;
}

export function createCircle(options) {
    const { x, y, radius, color = 0, alpha } = options;

    let circle = new PIXI.Graphics();
    circle.beginFill(color, alpha).drawCircle(0, 0, radius || 0).endFill();
    circle.x = x || 0;
    circle.y = y || 0;

    return circle;
}

export function addCornerRadius(sprite, cornerRadius) {
    const mask = new PIXI.Graphics();
    mask.width = sprite.width;
    mask.height = sprite.height;
    mask.beginFill(0xffffff);
    mask.drawRoundedRect(0, 0, sprite._width, sprite._height, cornerRadius);
    mask.endFill();
    sprite.mask = mask;
    sprite.addChild(mask);
}

export function createTextLabel(text, style) {
    if (!style.fontSize) { style.fontSize = 14; }
    if (!style.fontFamily) { style.fontFamily = 'Arial'; }
    if (!style.align) { style.align = 'center'; }
    if (!style.width) { style.width = 40; }
    if (!style.height) { style.height = 30; }
    if (!style.x) { style.x = 0; }
    if (!style.y) { style.y = 0; }
    if (!style.fill) { style.fill = '#FFFFFF'; }
    if (!style.borderColor) { style.borderColor = style.fill; }

    const width = style.width;
    const height = style.height;
    const x = style.x;
    const y = style.y;

    const container = new PIXI.Container();
    container.width = width;
    container.height = height;
    container.x = x;
    container.y = y;

    const background = new PIXI.Graphics();
    if (style.borderWidth && style.borderColor) {
        background.lineStyle(2, style.borderColor, style.borderWidth);
    }
    if (style.backgroundColor) {
        background.beginFill(style.backgroundColor);
    }
    background.drawRoundedRect(0, 0, width, height, height / 2);
    background.endFill();
    container.addChild(background);

    const label = new PIXI.Text(text, {
        fill: style.fill,
        fontSize: style.fontSize,
        fontFamily: style.fontFamily
    });
    label.x = width / 2;
    label.y = height / 2;
    if (!style.left) {
        label.anchor.set(0.5);
    }
    container.addChild(label);
    container.drmLabel = label;
    return container;
}