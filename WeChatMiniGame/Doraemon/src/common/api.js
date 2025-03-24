
function getUrl() {
  return 'https://calapi.yoloho.com/calendar/getdata?device=a8ed7ba8fc07881cff0c1161dec57bad&ver=1&platform=iphone&channel=AppStore&model=iPhone&sdkver=iPhone%206%20Plus%20(Global)&releasever=17.7.2&screen_width=828&screen_height=1792&period=&period_index=&userStatus=&lngt=&latt=&networkType=0&token=227998153-fcff5918e1da89a8175306dd66a5c865';
}

function updateUrl() {
  return 'https://calapi.yoloho.com/calendar/update?device=a8ed7ba8fc07881cff0c1161dec57bad&ver=1&platform=iphone&channel=AppStore&model=iPhone&sdkver=iPhone%206%20Plus%20(Global)&releasever=17.7.2&screen_width=828&screen_height=1792&period=&period_index=&userStatus=&lngt=&latt=&networkType=0&token=227998153-fcff5918e1da89a8175306dd66a5c865';
}

function dateline() {
  return 20250216;
}

function randomPasscode() {
  let passcode = '';
  for (let index = 0; index < 4; index++) {
    passcode = passcode + Math.floor(Math.random() * 10);
  }
  return passcode;
}

function getData(callback) {
  let url = getUrl();
  let header = {
    'content-type': 'application/x-www-form-urlencoded'
  };
  let body = {
    lastupdate: Date.parse(new Date()) / 1000 - 3600
  };

  wx.request({
    url: url,
    method: 'POST',
    header: header,
    data: body,
    success: (res) => {
      console.log('getData success', res);
      const data = res.data;
      callback && callback(data);
    },
    fail: (res) => {
      console.log('getData fail', res);
      callback && callback(null);
    }
  });
}

function uploadPasscodeList(accessInfoList, callback) {
  let url = updateUrl();
  let header = {
    'content-type': 'application/x-www-form-urlencoded'
  };

  const note = JSON.stringify(accessInfoList);
  const event = {
    data: note,
    eventtype: 7,
    mtime: Date.parse(new Date()) / 1000,
    dateline: dateline(),
  }
  const events = [event];
  const string = JSON.stringify(events);
  let body = {
    data: string
  };

  wx.request({
    url: url,
    method: 'POST',
    header: header,
    data: body,
    success: (res) => {
      console.log('uploadPasscodeList success', res);
      const errno = res.data && res.data.errno;
      callback && callback(errno === '0' ? null : errno);
    },
    fail: (res) => {
      console.log('uploadPasscodeList fail', res);
      callback && callback(res);
    }
  });
}

function parseAccessInfo(json) {
  const ret = {};
  for (const key in json) {
    const item = json[key];
    const date = item.date;
    if (!date) {
      continue;
    }

    if (Date.parse(new Date()) / 1000 > date) {
      continue;
    }

    const passcode = item.passcode;
    if (!passcode) {
      continue;
    }

    ret[key] = item;
  }
  return ret;
}

export function getPasscode(accessInfo, callback) {
  getData((res) => {
    if (!res) {
      callback && callback(null);
      return;
    }

    const list = res.data;
    if (!(list instanceof Array)) {
      callback && callback(null);
      return;
    }

    let data = null;
    for (let index = 0; index < list.length; index++) {
      const element = list[index];
      if (element.dateline == ('' + dateline())) {
        data = element;
        break;
      }
    }

    let accessInfoMap = {};
    if (data) {
      const string = data.data;
      if (typeof string === 'string') {
        const json = JSON.parse(string);
        accessInfoMap = parseAccessInfo(json);
      }
    }

    let passcode = accessInfoMap[accessInfo];
    if (passcode) {
      callback && callback(passcode);
      return;
    }

    passcode = randomPasscode();
    while (accessInfoMap[passcode] != undefined) {
      passcode = randomPasscode();
    }
    const date = Date.parse(new Date()) / 1000 + 3600;
    accessInfoMap[accessInfo] = { passcode, date };
    uploadPasscodeList(accessInfoMap, (error) => {
      callback && callback(error ? null : passcode);
    });
  });
}

export function getAccessInfo(passcode, callback) {
  getData((res) => {
    const list = res.data;
    if (!(list instanceof Array)) {
      callback && callback(null);
      return;
    }

    let data = null;
    for (let index = 0; index < list.length; index++) {
      const element = list[index];
      if (element.dateline == ('' + dateline())) {
        data = element;
        break;
      }
    }

    let accessInfoMap = {};
    if (data) {
      const string = data.data;
      if (typeof string === 'string') {
        const json = JSON.parse(string);
        accessInfoMap = parseAccessInfo(json);
      }
    }

    let accessInfo = null;
    for (const key in accessInfoMap) {
      const item = accessInfoMap[key];
      if (passcode == item.passcode) {
        accessInfo = key;
        break;
      }
    }

    callback && callback(accessInfo);
  });
}
