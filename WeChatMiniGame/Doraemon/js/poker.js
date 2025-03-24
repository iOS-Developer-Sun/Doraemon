"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PokerCardsType = exports.PokerCardValue = exports.PokerCardSuit = void 0;
exports.pokerCard = pokerCard;
exports.pokerCardCharacter = pokerCardCharacter;
exports.pokerCardImage = pokerCardImage;
exports.pokerCardsString = pokerCardsString;
exports.pokerCardSuitString = pokerCardSuitString;
exports.pokerCardValueString = pokerCardValueString;
exports.pokerCardString = pokerCardString;
exports.isRedJokerCard = isRedJokerCard;
exports.isRedJoker = isRedJoker;
exports.getPokerCards = getPokerCards;
exports.isGreaterThan = isGreaterThan;
exports.getCardScore = getCardScore;
exports.getCardsScore = getCardsScore;
exports.getJokersCount = getJokersCount;
var PokerCardSuit;
(function (PokerCardSuit) {
    PokerCardSuit[PokerCardSuit["club"] = 0] = "club";
    PokerCardSuit[PokerCardSuit["diamond"] = 1] = "diamond";
    PokerCardSuit[PokerCardSuit["spade"] = 2] = "spade";
    PokerCardSuit[PokerCardSuit["heart"] = 3] = "heart";
    PokerCardSuit[PokerCardSuit["blackJoker"] = 4] = "blackJoker";
    PokerCardSuit[PokerCardSuit["redJoker"] = 5] = "redJoker";
})(PokerCardSuit || (exports.PokerCardSuit = PokerCardSuit = {}));
var PokerCardValue;
(function (PokerCardValue) {
    PokerCardValue[PokerCardValue["offset"] = 3] = "offset";
    PokerCardValue[PokerCardValue["three"] = 0] = "three";
    PokerCardValue[PokerCardValue["four"] = 1] = "four";
    PokerCardValue[PokerCardValue["five"] = 2] = "five";
    PokerCardValue[PokerCardValue["six"] = 3] = "six";
    PokerCardValue[PokerCardValue["seven"] = 4] = "seven";
    PokerCardValue[PokerCardValue["eight"] = 5] = "eight";
    PokerCardValue[PokerCardValue["nine"] = 6] = "nine";
    PokerCardValue[PokerCardValue["ten"] = 7] = "ten";
    PokerCardValue[PokerCardValue["jack"] = 8] = "jack";
    PokerCardValue[PokerCardValue["queen"] = 9] = "queen";
    PokerCardValue[PokerCardValue["king"] = 10] = "king";
    PokerCardValue[PokerCardValue["ace"] = 11] = "ace";
    PokerCardValue[PokerCardValue["two"] = 12] = "two";
    PokerCardValue[PokerCardValue["blackJoker"] = 13] = "blackJoker";
    PokerCardValue[PokerCardValue["redJoker"] = 14] = "redJoker";
})(PokerCardValue || (exports.PokerCardValue = PokerCardValue = {}));
var PokerCardsType;
(function (PokerCardsType) {
    PokerCardsType[PokerCardsType["threeWithOne"] = 0] = "threeWithOne";
    PokerCardsType[PokerCardsType["highcard"] = 1] = "highcard";
    PokerCardsType[PokerCardsType["pair"] = 2] = "pair";
    PokerCardsType[PokerCardsType["threeOfAKind"] = 3] = "threeOfAKind";
    PokerCardsType[PokerCardsType["strait"] = 4] = "strait";
    PokerCardsType[PokerCardsType["pairStrait"] = 5] = "pairStrait";
    PokerCardsType[PokerCardsType["trioStrait"] = 6] = "trioStrait";
    PokerCardsType[PokerCardsType["fullHouseStrait"] = 7] = "fullHouseStrait";
    PokerCardsType[PokerCardsType["bomb"] = 8] = "bomb";
    PokerCardsType[PokerCardsType["fourOfAKind"] = 9] = "fourOfAKind";
    PokerCardsType[PokerCardsType["fftk"] = 10] = "fftk";
    PokerCardsType[PokerCardsType["fiveOfAKind"] = 11] = "fiveOfAKind";
    PokerCardsType[PokerCardsType["tftk"] = 12] = "tftk";
    PokerCardsType[PokerCardsType["sixOfAKind"] = 13] = "sixOfAKind";
    PokerCardsType[PokerCardsType["sevenOfAKind"] = 14] = "sevenOfAKind";
    PokerCardsType[PokerCardsType["eightOfAKind"] = 15] = "eightOfAKind";
    PokerCardsType[PokerCardsType["redJokers"] = 16] = "redJokers";
})(PokerCardsType || (exports.PokerCardsType = PokerCardsType = {}));
function pokerCard(index) {
    // D3 C3 S3 H3 ... D2 C3 S2 H2 BJ RJ
    var suit = PokerCardSuit.redJoker;
    var value = 0;
    var i = Math.floor(index / 2);
    if (i == 53) { // the last
        return { suit: PokerCardSuit.redJoker, value: PokerCardValue.redJoker };
    }
    if (i == 52) { // second to the last
        return { suit: PokerCardSuit.blackJoker, value: PokerCardValue.blackJoker };
    }
    suit = i % 4;
    value = Math.floor(i / 4);
    return { suit: suit, value: value };
}
function pokerCardCharacter(pokerCard) {
    var c = ['🃓', '🃔', '🃕', '🃖', '🃗', '🃘', '🃙', '🃚', '🃛', '🃝', '🃞', '🃑', '🃒'];
    var d = ['🃃', '🃄', '🃅', '🃆', '🃇', '🃈', '🃉', '🃊', '🃋', '🃍', '🃎', '🃁', '🃂'];
    var s = ['🂣', '🂤', '🂥', '🂦', '🂧', '🂨', '🂩', '🂪', '🂫', '🂭', '🂮', '🂡', '🂢'];
    var h = ['🂳', '🂴', '🂵', '🂶', '🂷', '🂸', '🂹', '🂺', '🂻', '🂽', '🂾', '🂱', '🂲'];
    var b = ['🂳', '🂴', '🂵', '🂶', '🂷', '🂸', '🂹', '🂺', '🂻', '🂽', '🂾', '🂱', '🂲', '🃟'];
    var r = ['🂳', '🂴', '🂵', '🂶', '🂷', '🂸', '🂹', '🂺', '🂻', '🂽', '🂾', '🂱', '🂲', '🃟', '🃏'];
    var deck = [c, d, s, h, b, r];
    var ret = deck[pokerCard.suit][pokerCard.value];
    return ret;
}
function pokerCardImageFilename(card) {
    var suit = card.suit;
    var value = card.value;
    if (suit === PokerCardSuit.redJoker) {
        // return 'red_joker';
        // return 'card_joker_0';
        return '54';
    }
    if (suit === PokerCardSuit.blackJoker) {
        // return 'black_joker';
        // return 'card_joker_1';
        return '53';
    }
    var suitnames = [
        // 'clubs',
        // 'diamonds',
        // 'spades',
        // 'hearts',
        // '2',
        // '3',
        // '0',
        // '1',
        3,
        4,
        1,
        2,
    ];
    var valuenames = [
        // '3', '4', '5', '6', '7', '8', '9', '10', 'jack', 'queen', 'king', 'ace', '2'
        // '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '1', '2'
        3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1, 2
    ];
    var suitname = suitnames[suit];
    var valuename = valuenames[value];
    // return valuename + '_of_' + suitname;
    // return 'card_' + valuename + '_' + suitname;
    return '' + ((valuename - 1) * 4 + suitname);
}
function pokerCardImage(index) {
    var card = pokerCard(index);
    var filename = pokerCardImageFilename(card);
    // return 'images/cards/' + filename + '.png';
    // return 'images/cards2/' + filename + '.png';
    return 'images/cards3/' + filename + '.png';
}
function pokerCardsString(indices) {
    var ret = '';
    for (var i = 0; i < indices.length; i++) {
        ret = ret + pokerCardCharacter(pokerCard(indices[i]));
    }
    return ret;
}
function pokerCardSuitString(suit) {
    return ['♣️', '♦️', '♠️', '♥️', '🃟', '🃏'][suit];
}
function pokerCardValueString(value) {
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
function pokerCardString(card) {
    return pokerCardSuitString(card.suit) + pokerCardValueString(card.value);
}
function isRedJokerCard(card) {
    return card.suit === PokerCardSuit.redJoker;
}
function isRedJoker(index) {
    return isRedJokerCard(pokerCard(index));
}
function getStrait(sortedValues, width) {
    if (sortedValues[sortedValues.length - 1] > PokerCardValue.ace) {
        return undefined;
    }
    var base = sortedValues[0];
    for (var i = 0; i < sortedValues.length; i++) {
        var value = sortedValues[i];
        var target = Math.floor(i / width);
        if (value - base != target) {
            return undefined;
        }
    }
    return base;
}
function getThreeWithTwoStrait(sortedCardIndices, length) {
    var valueCount = {};
    var keys = [];
    for (var i = 0; i < sortedCardIndices.length; i++) {
        var cardIndex = sortedCardIndices[i];
        var value = pokerCard(cardIndex).value;
        if (valueCount[value] == undefined) {
            valueCount[value] = [];
        }
        valueCount[value].push(cardIndex);
        if (keys.indexOf(value) == -1) {
            keys.push(value);
        }
    }
    if (length < 3 && keys.length != length * 2) {
        return undefined;
    }
    var allMajorKeys = [];
    for (var i = 0; i < keys.length; i++) {
        var key = keys[i];
        if (valueCount[key].length >= 3) {
            allMajorKeys.push(key);
        }
    }
    if (allMajorKeys.length < length) {
        return undefined;
    }
    var _loop_1 = function (i) {
        var majorKeys = allMajorKeys.slice(allMajorKeys.length - i - length, allMajorKeys.length - i);
        var base = undefined;
        if (majorKeys.length == 1) {
            base = majorKeys[0];
        }
        else {
            base = getStrait(majorKeys, 1);
        }
        if (base == undefined) {
            return "continue";
        }
        var majors = {};
        var minors = {};
        var minorKeys = [];
        var minorHasSingle = false;
        for (var i_1 = 0; i_1 < keys.length; i_1++) {
            var key = keys[i_1];
            var remaining = valueCount[key].slice();
            if (majorKeys.indexOf(key) != -1) {
                majors[key] = remaining.splice(remaining.length - 3, remaining.length);
            }
            if (remaining.length > 0) {
                minors[key] = remaining;
                minorKeys.push(key);
                if (remaining.length % 2 == 1) {
                    minorHasSingle = true;
                }
            }
        }
        var resultCards = function () {
            var resultCards = [];
            for (var index = 0; index < minorKeys.length; index++) {
                var key = minorKeys[index];
                var cards = minors[key];
                resultCards.push.apply(resultCards, cards);
            }
            for (var index = 0; index < majorKeys.length; index++) {
                var key = majorKeys[index];
                var cards = majors[key];
                resultCards.push.apply(resultCards, cards);
            }
            return resultCards.reverse();
        };
        if (length >= 3) {
            return { value: { value: base, cards: resultCards() } };
        }
        else if (length == 2) {
            if (minorHasSingle) {
                return "continue";
            }
            return { value: { value: base, cards: resultCards() } };
        }
        else {
            return { value: { value: base, cards: resultCards() } };
        }
    };
    for (var i = 0; i <= allMajorKeys.length - length; i++) {
        var state_1 = _loop_1(i);
        if (typeof state_1 === "object")
            return state_1.value;
    }
    return undefined;
}
function getPokerCards(pokerCards) {
    var length = pokerCards.length;
    if (length === 0) {
        return undefined;
    }
    var sortedCardIndices = pokerCards.slice().sort(function (a, b) { return a - b; });
    var cards = sortedCardIndices.map(function (index) { return pokerCard(index); });
    var suits = cards.map(function (card) { return card.suit; });
    var values = cards.map(function (card) { return card.value; });
    var min = values[0];
    var max = values[values.length - 1];
    if (length === 1) {
        // 3
        return { type: PokerCardsType.highcard, length: length, value: min, cards: sortedCardIndices };
    }
    if (length === 2) {
        if (min == max) {
            if (isRedJoker(sortedCardIndices[0])) {
                // 🃏🃏
                return { type: PokerCardsType.redJokers, length: length, value: min, cards: sortedCardIndices };
            }
            // 33
            return { type: PokerCardsType.pair, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        return undefined;
    }
    if (length === 3) {
        if (min == max) {
            // 333
            return { type: PokerCardsType.threeOfAKind, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        if (min === PokerCardValue.five && values[1] === PokerCardValue.ten && values[2] === PokerCardValue.king) {
            if (suits[0] === suits[1] && suits[0] === suits[2]) {
                // 5TK
                return { type: PokerCardsType.tftk, length: length, value: suits[0], cards: sortedCardIndices };
            }
            // 5TK
            return { type: PokerCardsType.fftk, length: length, value: min, cards: sortedCardIndices };
        }
        return undefined;
    }
    if (length === 4) {
        if (min == max) {
            // 3333
            return { type: PokerCardsType.fourOfAKind, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        if (min === values[2]) {
            // 333 4
            return { type: PokerCardsType.threeWithOne, length: length, value: min, cards: sortedCardIndices };
        }
        if (values[1] === max) {
            // 555 4
            return { type: PokerCardsType.threeWithOne, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        return undefined;
    }
    if (length === 5) {
        if (min == max) {
            // 33333
            return { type: PokerCardsType.fiveOfAKind, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        var threeWithTwoStrait = getThreeWithTwoStrait(sortedCardIndices, length / 5);
        if (threeWithTwoStrait != undefined) {
            // 333 44
            return { type: PokerCardsType.fullHouseStrait, length: length, value: threeWithTwoStrait.value, cards: threeWithTwoStrait.cards };
        }
        if (getStrait(values, 1) != undefined) {
            // 34567
            return { type: PokerCardsType.strait, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        return undefined;
    }
    if (length === 6) {
        if (min == max) {
            // 333333
            return { type: PokerCardsType.sixOfAKind, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        if (getStrait(values, 3) != undefined) {
            // 333 444
            return { type: PokerCardsType.trioStrait, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        if (getStrait(values, 2) != undefined) {
            // 33 44 55
            return { type: PokerCardsType.pairStrait, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        if (getStrait(values, 1) != undefined) {
            // 345678
            return { type: PokerCardsType.strait, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        return undefined;
    }
    if (length === 7) {
        if (min == max) {
            // 3333333
            return { type: PokerCardsType.sevenOfAKind, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        if (getStrait(values, 1) != undefined) {
            // 3456789
            return { type: PokerCardsType.strait, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        return undefined;
    }
    if (length === 8) {
        if (min == max) {
            // 33333333
            return { type: PokerCardsType.eightOfAKind, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        if (getStrait(values, 2) != undefined) {
            // 33 44 55 66
            return { type: PokerCardsType.pairStrait, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        if (getStrait(values, 1) != undefined) {
            // 3456789T
            return { type: PokerCardsType.strait, value: min, length: length, cards: sortedCardIndices.reverse() };
        }
        return undefined;
    }
    if (length === 9) {
        if (getStrait(values, 3) != undefined) {
            // 333 444 555
            return { type: PokerCardsType.trioStrait, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        if (getStrait(values, 1) != undefined) {
            // 3456789TJ
            return { type: PokerCardsType.strait, value: min, length: length, cards: sortedCardIndices.reverse() };
        }
        return undefined;
    }
    if (length === 10) {
        var threeWithTwoStrait = getThreeWithTwoStrait(sortedCardIndices, length / 5);
        if (threeWithTwoStrait != undefined) {
            // 333 444 55 88
            return { type: PokerCardsType.fullHouseStrait, length: length, value: threeWithTwoStrait.value, cards: threeWithTwoStrait.cards };
        }
        if (getStrait(values, 2) != undefined) {
            // 33 44 55 66 77
            return { type: PokerCardsType.pairStrait, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        if (getStrait(values, 1) != undefined) {
            // 3456789TJQ
            return { type: PokerCardsType.strait, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        return undefined;
    }
    if (length === 11) {
        if (getStrait(values, 1) != undefined) {
            // 3456789TJQK
            return { type: PokerCardsType.strait, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        return undefined;
    }
    if (length === 12) {
        if (getStrait(values, 3) != undefined) {
            // 333 444 555 666
            return { type: PokerCardsType.trioStrait, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        if (getStrait(values, 2) != undefined) {
            // 33 44 55 66 77 88
            return { type: PokerCardsType.pairStrait, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        if (getStrait(values, 1) != undefined) {
            // 3456789TJQKA
            return { type: PokerCardsType.strait, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        return undefined;
    }
    if (length === 14) {
        if (getStrait(values, 2) != undefined) {
            // 33 44 55 66 77 88 99
            return { type: PokerCardsType.pairStrait, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        return undefined;
    }
    if (length === 15) {
        var threeWithTwoStrait = getThreeWithTwoStrait(sortedCardIndices, length / 5);
        if (threeWithTwoStrait != undefined) {
            // 333 444 555 68TQAA
            return { type: PokerCardsType.fullHouseStrait, length: length, value: threeWithTwoStrait.value, cards: threeWithTwoStrait.cards };
        }
        if (getStrait(values, 3) != undefined) {
            // 333 444 555 666 777
            return { type: PokerCardsType.trioStrait, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        return undefined;
    }
    if (length === 16) {
        if (getStrait(values, 2) != undefined) {
            // 33 44 55 66 77 88 99 TT
            return { type: PokerCardsType.pairStrait, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        return undefined;
    }
    if (length === 18) {
        if (getStrait(values, 3) != undefined) {
            // 333 444 555 666 777 888
            return { type: PokerCardsType.trioStrait, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        if (getStrait(values, 2) != undefined) {
            // 33 44 55 66 77 88 99 TT JJ
            return { type: PokerCardsType.pairStrait, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        return undefined;
    }
    if (length === 20) {
        var threeWithTwoStrait = getThreeWithTwoStrait(sortedCardIndices, length / 5);
        if (threeWithTwoStrait != undefined) {
            // 333 444 555 666 789TJQKA
            return { type: PokerCardsType.fullHouseStrait, length: length, value: threeWithTwoStrait.value, cards: threeWithTwoStrait.cards };
        }
        if (getStrait(values, 2) != undefined) {
            // 33 44 55 66 77 88 99 TT JJ QQ
            return { type: PokerCardsType.pairStrait, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        return undefined;
    }
    if (length === 21) {
        if (getStrait(values, 3) != undefined) {
            // 333 444 555 666 777 888 999
            return { type: PokerCardsType.trioStrait, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        return undefined;
    }
    if (length === 22) {
        if (getStrait(values, 2) != undefined) {
            // 33 44 55 66 77 88 99 TT JJ QQ KK
            return { type: PokerCardsType.pairStrait, length: length, value: min, cards: sortedCardIndices.reverse() };
        }
        return undefined;
    }
    return undefined;
}
function isGreaterThan(pokerCard, target) {
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
    if (pokerCard.type < target.type) {
        return false;
    }
    if (pokerCard.value > target.value) {
        return true;
    }
    return false;
}
function getCardScore(index) {
    var score = 0;
    var card = pokerCard(index);
    var value = card.value;
    if (value == PokerCardValue.five) {
        score = 5;
    }
    else if (value == PokerCardValue.ten || value == PokerCardValue.king) {
        score = 10;
    }
    return score;
}
function getCardsScore(cards) {
    var score = 0;
    for (var index = 0; index < cards.length; index++) {
        var card = cards[index];
        score += getCardScore(card);
    }
    return score;
}
function getJokersCount(cards) {
    var jokersCount = 0;
    for (var index = 0; index < cards.length; index++) {
        var card = cards[index];
        if (isRedJoker(card)) {
            jokersCount++;
        }
    }
    return jokersCount;
}
