
export enum PokerCardSuit {
    club = 0,
    diamond = 1,
    spade = 2,
    heart = 3,
    blackJoker = 4,
    redJoker = 5,
}

export enum PokerCardValue {
    offset = 3,

    three = 0,
    four = 1,
    five = 2,
    six = 3,
    seven = 4,
    eight = 5,
    nine = 6,
    ten = 7,
    jack = 8,
    queen = 9,
    king = 10,
    ace = 11,
    two = 12,
    blackJoker = 13,
    redJoker = 14,
}

export enum PokerCardsType {
    threeWithOne,

    highcard,
    pair,
    threeOfAKind,

    strait,
    pairStrait,
    trioStrait,
    fullHouseStrait,

    bomb,
    fourOfAKind,
    fftk,
    fiveOfAKind,
    tftk,
    sixOfAKind,
    sevenOfAKind,
    eightOfAKind,
    redJokers,
}

export interface PokerCard {
    suit: PokerCardSuit,
    value: number,
}

export function pokerCard(index: number): PokerCard {
    // D3 C3 S3 H3 ... D2 C3 S2 H2 BJ RJ
    var suit = PokerCardSuit.redJoker;
    var value = 0;
    let i = Math.floor(index / 2);

    if (i == 53) { // the last
        return { suit: PokerCardSuit.redJoker, value: PokerCardValue.redJoker };
    }
    if (i == 52) { // second to the last
        return { suit: PokerCardSuit.blackJoker, value: PokerCardValue.blackJoker };
    }

    suit = i % 4;
    value = Math.floor(i / 4);
    return { suit, value };
}

export function pokerCardCharacter(pokerCard: PokerCard): string {
    let c = ['🃓', '🃔', '🃕', '🃖', '🃗', '🃘', '🃙', '🃚', '🃛', '🃝', '🃞', '🃑', '🃒'];
    let d = ['🃃', '🃄', '🃅', '🃆', '🃇', '🃈', '🃉', '🃊', '🃋', '🃍', '🃎', '🃁', '🃂'];
    let s = ['🂣', '🂤', '🂥', '🂦', '🂧', '🂨', '🂩', '🂪', '🂫', '🂭', '🂮', '🂡', '🂢'];
    let h = ['🂳', '🂴', '🂵', '🂶', '🂷', '🂸', '🂹', '🂺', '🂻', '🂽', '🂾', '🂱', '🂲'];
    let b = ['🂳', '🂴', '🂵', '🂶', '🂷', '🂸', '🂹', '🂺', '🂻', '🂽', '🂾', '🂱', '🂲', '🃟'];
    let r = ['🂳', '🂴', '🂵', '🂶', '🂷', '🂸', '🂹', '🂺', '🂻', '🂽', '🂾', '🂱', '🂲', '🃟', '🃏'];
    let deck = [c, d, s, h, b, r];
    let ret = deck[pokerCard.suit][pokerCard.value];
    return ret;
}

function pokerCardImageFilename(card: PokerCard): string {
    let suit = card.suit;
    let value = card.value;
    if (suit === PokerCardSuit.redJoker) {
        return 'red_joker';
    }

    if (suit === PokerCardSuit.blackJoker) {
        return 'black_joker';
    }

    let suitnames = [
        'clubs',
        'diamonds',
        'spades',
        'hearts',
    ];
    let valuenames = [
        '3', '4', '5', '6', '7', '8', '9', '10', 'jack', 'queen', 'king', 'ace', '2'
    ]
    let suitname = suitnames[suit];
    let valuename = valuenames[value];
    return valuename + '_of_' + suitname;
}

export function pokerCardImage(index: number): string {
    let card = pokerCard(index);
    let filename = pokerCardImageFilename(card);
    return 'images/cards/' + filename + '.png';
}

export function pokerCardsString(indices: number[]): string {
    var ret = '';
    for (let i = 0; i < indices.length; i++) {
        ret = ret + pokerCardCharacter(pokerCard(indices[i]));
    }
    return ret;
}

export function pokerCardSuitString(suit: PokerCardSuit) {
    return ['♣️', '♦️', '♠️', '♥️', '🃟', '🃏'][suit];
}

export function pokerCardValueString(value: number) {
    if (value >= PokerCardValue.blackJoker) {
        return '';
    }

    if (value === PokerCardValue.two) {
        return '2';
    }

    if (value === PokerCardValue.ace) {
        return 'A';
    }

    if (value >= PokerCardValue.ten) {
        return 'TJQK'[value - PokerCardValue.ten];
    }

    return '' + (value + PokerCardValue.offset);
}

export function pokerCardString(card: PokerCard): string {
    return pokerCardSuitString(card.suit) + pokerCardValueString(card.value);
}

export function isRedJokerCard(card: PokerCard): boolean {
    return card.suit === PokerCardSuit.redJoker;
}

export function isRedJoker(index: number): boolean {
    return isRedJokerCard(pokerCard(index));
}

export function hasRedJoker(cards: number[]): boolean {
    return cards.indexOf(106) != -1 || cards.indexOf(107) != -1;
}

export function hasRedJokers(cards: number[]): boolean {
    return cards.indexOf(106) != -1 && cards.indexOf(107) != -1;
}

export interface PokerCards {
    type: PokerCardsType;
    length: number;
    value: number;
}

function getStrait(sortedValues: number[], width: number): number | undefined {
    if (sortedValues[sortedValues.length - 1] > PokerCardValue.ace) {
        return undefined;
    }

    let base = sortedValues[0];
    for (let i = 0; i < sortedValues.length; i++) {
        let value = sortedValues[i];
        let target = Math.floor(i / width);
        if (value - base != target) {
            return undefined;
        }
    }
    return base;
}

function getThreeWithTwoStrait(sortedValues: number[], length: number): number | undefined {
    let valueCount: Record<number, number> = {};
    let keys: number[] = [];
    for (let i = 0; i < sortedValues.length; i++) {
        let value = sortedValues[i];
        valueCount[value] = (valueCount[value] ? valueCount[value] : 0) + 1;
        if (keys.indexOf(value) == -1) {
            keys.push(value);
        }
    }

    let majors: Record<number, number> = {};
    let minors: Record<number, number> = {};
    let majorKeys: number[] = [];
    let minorKeys: number[] = [];
    let minorHasSingle: boolean = false;
    for (let i = 0; i < keys.length; i++) {
        let key = keys[i];
        let remaining = valueCount[key];
        if (remaining >= 3) {
            remaining = remaining - 3;
            majors[key] = valueCount[key];
            majorKeys.push(key);
        }

        if (remaining > 0) {
            minors[key] = remaining;
            minorKeys.push(key);
            if (remaining % 2 == 1) {
                minorHasSingle = true;
            }
        }
    }

    if (majorKeys.length < length) {
        return undefined;
    }

    let base: (number | undefined) = undefined;
    if (majorKeys.length == 1) {
        base = majorKeys[0];
    } else {
        base = getStrait(majorKeys, 1);
    }

    if (base == undefined) {
        return undefined;
    }

    let extra = majorKeys.length - length;
    if (extra < 0) {
        return undefined;
    }

    if (length >= 3) {
        return base + extra;
    }

    if (extra > 0) {
        return undefined;
    }

    if (majorKeys.length == 2) {
        if (minorHasSingle) {
            return undefined;
        }

        return base;
    }

    if (majorKeys.length == 1) {
        if (minorKeys.length == 1) {
            return base;
        }

        return undefined;
    }

    // bad routine
    return undefined;
}

export function getPokerCards(pokerCards: number[]): PokerCards | undefined {
    let length = pokerCards.length;
    if (length === 0) {
        return undefined;
    }

    let sortedCardIndices = pokerCards.sort((a, b) => a - b);
    let cards = sortedCardIndices.map((index: number) => pokerCard(index));
    let suits = cards.map((card: PokerCard) => card.suit);
    let values = cards.map((card: PokerCard) => card.value);
    let min = values[0];
    let max = values.at(-1);
    if (length === 1) {
        // 3
        return { type: PokerCardsType.highcard, length: length, value: min };
    }

    if (length === 2) {
        if (min == max) {
            if (isRedJoker(sortedCardIndices[0])) {
                // 🃏🃏
                return { type: PokerCardsType.redJokers, length: length, value: min };
            }
            // 33
            return { type: PokerCardsType.pair, length: length, value: min };
        }

        return undefined;
    }

    if (length === 3) {
        if (min == max) {
            // 333
            return { type: PokerCardsType.threeOfAKind, length: length, value: min };
        }

        if (min === PokerCardValue.five && values[1] === PokerCardValue.ten && values[2] === PokerCardValue.king) {
            if (suits[0] === suits[1] && suits[0] === suits[2]) {
                // 5TK
                return { type: PokerCardsType.tftk, length: length, value: suits[0] };
            }
            // 5TK
            return { type: PokerCardsType.fftk, length: length, value: min };
        }

        return undefined;
    }

    if (length === 4) {
        if (min == max) {
            // 3333
            return { type: PokerCardsType.fourOfAKind, length: length, value: min };
        }

        if (min === values[2] || values[1] === values[3]) {
            // 333 4
            return { type: PokerCardsType.threeWithOne, length: length, value: min };
        }

        return undefined;
    }

    if (length === 5) {
        if (min == max) {
            // 33333
            return { type: PokerCardsType.fiveOfAKind, length: length, value: min };
        }

        let value = getThreeWithTwoStrait(values, length / 5);
        if (value != undefined) {
            // 333 44
            return { type: PokerCardsType.fullHouseStrait, length: length, value: value };
        }

        if (getStrait(values, 1) != undefined) {
            // 34567
            return { type: PokerCardsType.strait, length: length, value: min };
        }

        return undefined;
    }

    if (length === 6) {
        if (min == max) {
            // 333333
            return { type: PokerCardsType.sixOfAKind, length: length, value: min };
        }

        if (getStrait(values, 3) != undefined) {
            // 333 444
            return { type: PokerCardsType.trioStrait, length: length, value: min };
        }

        if (getStrait(values, 2) != undefined) {
            // 33 44 55
            return { type: PokerCardsType.pairStrait, length: length, value: min };
        }

        if (getStrait(values, 1) != undefined) {
            // 345678
            return { type: PokerCardsType.strait, length: length, value: min };
        }

        return undefined;
    }

    if (length === 7) {
        if (min == max) {
            // 3333333
            return { type: PokerCardsType.sevenOfAKind, length: length, value: min };
        }

        if (getStrait(values, 1) != undefined) {
            // 3456789
            return { type: PokerCardsType.strait, length: length, value: min };
        }

        return undefined;
    }

    if (length === 8) {
        if (min == max) {
            // 33333333
            return { type: PokerCardsType.eightOfAKind, length: length, value: min };
        }

        if (getStrait(values, 2) != undefined) {
            // 33 44 55 66
            return { type: PokerCardsType.pairStrait, length: length, value: min };
        }

        if (getStrait(values, 1) != undefined) {
            // 3456789T
            return { type: PokerCardsType.strait, value: min, length: length };
        }

        return undefined;
    }

    if (length === 9) {
        if (getStrait(values, 3) != undefined) {
            // 333 444 555
            return { type: PokerCardsType.trioStrait, length: length, value: min };
        }

        if (getStrait(values, 1) != undefined) {
            // 3456789TJ
            return { type: PokerCardsType.strait, value: min, length: length };
        }

        return undefined;
    }

    if (length === 10) {
        let value = getThreeWithTwoStrait(values, length / 5);
        if (value != undefined) {
            // 333 444 55 88
            return { type: PokerCardsType.fullHouseStrait, length: length, value: value };
        }

        if (getStrait(values, 2) != undefined) {
            // 33 44 55 66 77
            return { type: PokerCardsType.pairStrait, length: length, value: min };
        }

        if (getStrait(values, 1) != undefined) {
            // 3456789TJQ
            return { type: PokerCardsType.strait, length: length, value: min };
        }

        return undefined;

    }

    if (length === 11) {
        if (getStrait(values, 1) != undefined) {
            // 3456789TJQK
            return { type: PokerCardsType.strait, length: length, value: min };
        }

        return undefined;
    }

    if (length === 12) {
        if (getStrait(values, 3) != undefined) {
            // 333 444 555 666
            return { type: PokerCardsType.trioStrait, length: length, value: min };
        }

        if (getStrait(values, 2) != undefined) {
            // 33 44 55 66 77 88
            return { type: PokerCardsType.pairStrait, length: length, value: min };
        }

        if (getStrait(values, 1) != undefined) {
            // 3456789TJQKA
            return { type: PokerCardsType.strait, length: length, value: min };
        }

        return undefined;
    }

    if (length === 14) {
        if (getStrait(values, 2) != undefined) {
            // 33 44 55 66 77 88 99
            return { type: PokerCardsType.pairStrait, length: length, value: min };
        }

        return undefined;
    }

    if (length === 15) {
        let value = getThreeWithTwoStrait(values, length / 5);
        if (value != undefined) {
            // 333 444 555 68TQAA
            return { type: PokerCardsType.fullHouseStrait, length: length, value: value };
        }

        if (getStrait(values, 3) != undefined) {
            // 333 444 555 666 777
            return { type: PokerCardsType.trioStrait, length: length, value: min };
        }

        return undefined;
    }

    if (length === 16) {
        if (getStrait(values, 2) != undefined) {
            // 33 44 55 66 77 88 99 TT
            return { type: PokerCardsType.pairStrait, length: length, value: min };
        }

        return undefined;
    }

    if (length === 18) {
        if (getStrait(values, 3) != undefined) {
            // 333 444 555 666 777 888
            return { type: PokerCardsType.trioStrait, length: length, value: min };
        }

        if (getStrait(values, 2) != undefined) {
            // 33 44 55 66 77 88 99 TT JJ
            return { type: PokerCardsType.pairStrait, length: length, value: min };
        }

        return undefined;
    }

    if (length === 20) {
        let value = getThreeWithTwoStrait(values, length / 5);
        if (value != undefined) {
            // 333 444 555 666 789TJQKA
            return { type: PokerCardsType.fullHouseStrait, length: length, value: value };
        }

        if (getStrait(values, 2) != undefined) {
            // 33 44 55 66 77 88 99 TT JJ QQ
            return { type: PokerCardsType.pairStrait, length: length, value: min };
        }

        return undefined;
    }

    if (length === 21) {
        if (getStrait(values, 3) != undefined) {
            // 333 444 555 666 777 888 999
            return { type: PokerCardsType.trioStrait, length: length, value: min };
        }

        return undefined;
    }

    if (length === 22) {
        if (getStrait(values, 2) != undefined) {
            // 33 44 55 66 77 88 99 TT JJ QQ KK
            return { type: PokerCardsType.pairStrait, length: length, value: min };
        }

        return undefined;
    }

    return undefined;
}

export function isGreaterThan(pokerCard: PokerCards, target: PokerCards): boolean {
    if (target.type == PokerCardsType.threeWithOne) {
        return false;
    }

    if (pokerCard.type == PokerCardsType.threeWithOne) {
        return false;
    }

    if (target.type < PokerCardsType.bomb) {
        if (pokerCard.type >= PokerCardsType.bomb) {
            return true;
        }

        if (pokerCard.type != target.type || pokerCard.length != target.length) {
            return false;
        }

        if (pokerCard.value > target.value) {
            return true;
        }

        return false;
    }

    if (pokerCard.type > target.type) {
        return true;
    }

    if (pokerCard.value > target.value) {
        return true;
    }

    return false;
}

export function getCardScore(index) {
    let score = 0;
    let card = pokerCard(index);
    let value = card.value
    if (value == PokerCardValue.five) {
        score = 5;
    } else if (value == PokerCardValue.ten || value == PokerCardValue.king) {
        score = 10;
    }
    return score;
}

export function getCardsScore(cards) {
    let score = 0;
    for (let index = 0; index < cards.length; index++) {
        const card = cards[index];
        score += getCardScore(card);
    }
    return score;
}
