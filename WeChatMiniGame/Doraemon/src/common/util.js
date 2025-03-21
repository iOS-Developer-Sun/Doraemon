/**
 * 获取当前设备信息
 */
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