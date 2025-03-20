import databus from '../databus.js';

class Login {
    do(callback = none) {
        this.loginCallback = callback;

        if (wx.getPrivacySetting != undefined) {
            wx.getPrivacySetting({
                success: (res) => {
                    console.log('getPrivacySetting success:' + res.errMsg);
                    if (res.errMsg == "getPrivacySetting:ok") {
                        if (res.needAuthorization) {
                            console.log('needAuthorization:' + res.privacyContractName);
                            this.requestPrivace(res.privacyContractName);
                        } else {
                            this.start();
                        }
                    }
                },
                fail: (res) => {
                    console.log('getPrivacySetting fail');
                }
            })
        } else {
            this.requestPrivace();
        }
    }

    addLoginBtn() {
        const width = 120;
        const height = 40;

        const button = wx.createUserInfoButton({
            type: 'image',
            image: 'images/start.png',
            style: {
                left: window.innerWidth / 2 - width / 2,
                top: window.innerHeight / 2 - height / 2,
                width,
                height,
            }
        });

        button.onTap((res) => {
            console.log("button.onTap: " + res);
            if (res.errMsg.indexOf(':ok') > -1) {
                button.destroy();
                try {
                    let userInfo = JSON.parse(res.rawData);
                    databus.userInfo = userInfo;
                    this.loginCallback();
                } catch (e) {
                    console.log(e, res);
                    this.loginCallback();
                }
            } else {
                console.log("button.onTap failure");
                wx.showToast({
                    title: '请授权开始游戏',
                    icon: 'none',
                    duration: 1500
                })
            }
        });
    }

    requestPrivace() {
        // wx.onNeedPrivacyAuthorization((resolve, eventInfo) => {
        //     console.log('onNeedPrivacyAuthorization:' + eventInfo.referrer);
        //     resolve({ buttonId: 'agree-btn', event: 'agree' });
        // })

        if (wx.requirePrivacyAuthorize) {
            wx.requirePrivacyAuthorize({
                success: (res) => {
                    console.log('requirePrivacyAuthorize success');
                    this.start();
                },
                fail: (res) => {
                    console.log('requirePrivacyAuthorize fail');
                }
            });
        } else {
            this.start();
        }
    }

    start() {
        console.log('start');
        wx.getSetting({
            success: (res) => {
                const authSetting = res.authSetting
                if (authSetting['scope.userInfo'] === true) {
                    wx.getUserInfo({
                        success: (res) => {
                            databus.userInfo = res.userInfo;
                            this.userInfo = res.userInfo
                            this.loginCallback(this.userInfo);
                        }
                    });
                } else if (authSetting['scope.userInfo'] === false) {
                    this.addLoginBtn();
                } else {
                    this.addLoginBtn();
                }
            }
        });
    }
}

export default new Login();

