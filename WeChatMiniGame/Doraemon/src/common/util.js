function getCurrentDateString() {
    return '[' + (new Date()).toLocaleString() + ']';
};
const originalLog = console.log;
console.log = function () {
    var args = [].slice.call(arguments);
    originalLog.apply(console.log,[getCurrentDateString()].concat(args));
};

const originalError = console.error;
console.error = function () {
    var args = [].slice.call(arguments);
    originalError.apply(console.error,[getCurrentDateString()].concat(args));
};

export function getDeviceInfo() {
    let info = {};
    let defaultInfo = {
        devicePixelRatio: 2,
        windowWidth: 375, windowHeight: 667
    }

    if (typeof wx !== 'undefined') {
        try {
            info = wx.getSystemInfoSync();
        } catch (e) {
            info = defaultInfo
        }
    } else {
        info = defaultInfo;
    }

    return info;
}

export function isPointNearPoint(point1, point2) {
    const threshold = 20;
    if (Math.abs(point1.x - point2.x) > threshold) {
        return false;
    }
    if (Math.abs(point1.y - point2.y) > threshold) {
        return false;
    }
    return true;
}

export function numbersArray(length, start = 0) {
    var array = [];
    for (let i = 0; i < length; i++) {
        array.push(start + i);
    }
    return array;
}

export function createArray(length, object = null) {
    var array = [];
    for (let i = 0; i < length; i++) {
        let copy = object;
        if (copy instanceof Function) {
            copy = copy(i);
        }
        array.push(copy);
    }
    return array;
}

export function arrayByRemovingObjectsFromArray(array, removedObjectsArray) {
    return array.filter(object => !removedObjectsArray.includes(object));
}

export function setWithArray(array) {
    var set = [];
    for (let i = 0; i < array.length; i++) {
        let object = array[i];
        if (set.includes(object)) {
            continue;
        }
        set.push(object);
    }
    return set;
}

export function arrayContainsObjectsFromArray(container, array) {
    let contains = true;
    for (let i = 0; i < array.length; i++) {
        let object = array[i];
        if (!container.includes(object)) {
            contains = false;
            break;
        }
    }
    return contains;
}

export function arrayIsEqualToArray(a, b) {
    if (a === b) {
        return true;
    }

    if (a == null || b == null) {
        return false;
    }

    if (a.length !== b.length) {
        return false;
    }

    for (var i = 0; i < a.length; ++i) {
        if (a[i] !== b[i]) {
            return false;
        }
    }
    return true;
}