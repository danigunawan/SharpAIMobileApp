if (Meteor.isClient) {
  Template.authOverlay.rendered = function() {
      $('.authOverlay').css('height', $(window).height());
    
      if(Meteor.loggingIn() && !Meteor.status().connected){
        
        // 由于meteor的重连时间是成倍累加的，所以增加手动处理。
        var autoReconnect = Meteor.setInterval(function(){
          if(Meteor.status().connected)
            Meteor.clearTimeout(autoReconnect);
          else
            Meteor.reconnect();
        }, 500);
        
//        var handReconnect = function(){
//          if(Meteor.isCordova){
//            navigator.notification.confirm('当前为离线状态,请检查网络连接！', function(index){
//              if(index === 1)
//                Meteor.reconnect();
//                Meteor.setTimeout(function(){if(!Meteor.status().connected){handReconnect();}}, 500);
//            }, '提示', ['重试', '知道了']);
//          }else{
//            if(confirm('当前为离线状态,按[确定]尝试重新连接？')){
//              Meteor.reconnect();
//              Meteor.setTimeout(function(){if(!Meteor.status().connected){handReconnect();}}, 500);
//            }
//          }
//        }
//        handReconnect();
      }
  };
  Template.authOverlay.helpers({
      isLoggingIn:function() {
          return Meteor.loggingIn();
      },
      isConnected: function(){
        return Meteor.status().connected;
      }
  });
  Template.authOverlay.events({
    'click #anonymous': function () {
        console.log ('UUID is ' + device.uuid);
        if (device.uuid){
            Meteor.loginWithPassword(device.uuid,'123456',function(error){
                console.log('Login Error is ' + JSON.stringify(error));
                if(error && error.reason && error.reason ==='User not found'){
                    console.log('User Not Found, need create');
                    $('.agreeDeal').css('display',"block");
                    Session.set("dealBack","anonymous");
                }
                if (!error){
                    Router.go ('/');
                }
            });
        } else {
            PUB.toast ('您的设备不支持匿名使用，请和我们联系');
        }
    },
    'click #cancle': function () {
      $('.agreeDeal').css('display',"none");
    },
    'click #agree': function () {
        Accounts.createUser({
                'username':device.uuid,
                'password':'123456',
                'profile':{
                    fullname:'匿名',
                    icon:'/userPicture.png',
                    anonymous:true
                }
            },
            function(error){
                console.log('Registration Error is ' + JSON.stringify(error));
                if (!error){
                    console.log('Registration Succ, goto Follow page');
                    Router.go('/registerFollow');
                } else {
                    $('.agreeDeal').css('display',"none");
                    PUB.toast ('匿名服务暂时不可用，请稍后重试');
                }
            });
    },
    'click #register': function () {
//      Router.go('/signupForm');
      $('.register').css('display',"block")
      $('#register').css('display',"none")
      $('#weibo').css('display',"none")
      $('#login').css('display',"none")
      $('.agreeDeal').css('display',"none");
      Session.set("dealBack","register");
//      $('.authOverlay').css('-webkit-filter',"blur(10px)")
    },
    'click #login': function () {
//      Router.go('/loginForm');
      $('.login').css('display',"block")
      $('#register').css('display',"none")
      $('#weibo').css('display',"none")
      $('#login').css('display',"none")
      $('.agreeDeal').css('display',"none");
//      $('.authOverlay').css('-webkit-filter',"blur(10px)")
    },
    'click #weibo': function () {
      Meteor.loginWithWeibo({
        loginStyle: 'popup'
        //loginStyle: 'redirect'
        //loginStyle: 'redirect'  you can use redirect for mobile web app
      }, function () {
        console.log('in call back', arguments);
      });
    },
    'click #wechat': function () {
      Meteor.loginWithWechat({
        loginStyle: 'popup'
        //loginStyle: 'redirect'
        //loginStyle: 'redirect'  you can use redirect for mobile web app
      }, function () {
        console.log('in call back', arguments);
      });
    },
    'click #qq': function () {
      Meteor.loginWithQq({
        loginStyle: 'popup'
        //loginStyle: 'redirect'
        //loginStyle: 'redirect'  you can use redirect for mobile web app
      }, function () {
        console.log('in call back', arguments);
      });
    }

  });
  Template.webHome.rendered = function() {
    $('.webHome').css('height', $(window).height());
    $('.webFooter').css('left', $(window).width()*0.5-105);
  };
  Meteor.startup(function() {
    $(window).resize(function() {
      $('.webHome').css('height', $(window).height());
      $('.webFooter').css('left', $(window).width()*0.5-105);
    });
  });
}

