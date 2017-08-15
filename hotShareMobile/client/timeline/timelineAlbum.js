Template.timelineAlbum.onRendered(function(){
  Session.set('timelineAlbumMultiSelect',false);
  Session.set('timelineAlbumLimit',10);
  var uuid = Router.current().params._uuid;
  Meteor.subscribe('device-timeline',uuid,Session.get('timelineAlbumLimit'));
  $('.content').scroll(function(){
    var height = $('.timeLine').height();
    var contentTop = $('.content').scrollTop();
    var contentHeight = $('.content').height();
    console.log(contentTop+contentHeight)
    console.log(height)
    if(timelineAlbumTimeout){
      window.clearTimeout(timelineAlbumTimeout);
    }
    timelineAlbumTimeout = setTimeout(function() {
      $("img.lazy").lazyload({});
    }, 500);
    if((contentHeight + contentTop + 50 ) >= height){
      var limit = Session.get('timelineAlbumLimit') + 10
      console.log('loadMore and limit = ',limit);
      // SimpleChat.withMessageHisEnable && SimpleChat.loadMoreMesage({to_type:'group',people_uuid:uuid,type:'text', images: {$exists: true}}, {limit: limit, sort: {create_time: -1}}, limit);
      Meteor.subscribe('device-timeline',uuid,Session.get('timelineAlbumLimit'));
      Session.set('timelineAlbumLimit',limit);
    }
  });

  Meteor.subscribe('devices-by-uuid',Router.current().params._uuid);
  //Meteor.subscribe('get-workai-user-relation',Meteor.userId());  
  timelineAlbumTimeout = setTimeout(function() {
      $("img.lazy").lazyload({});
  }, 1000);
});
Template.timelineAlbum.onDestroyed(function(){
  Session.set('wantModify',false);
});
Template.timelineAlbum.helpers({
  // lists: function(){
  //   var uuid = Router.current().params._uuid;
  //   var msgs = [];
  //   var tempDate = null;
  //   if(SimpleChat.Messages.find({to_type:'group',people_uuid:uuid,type:'text', images: {$exists: true}},{sort:{create_time:1}}).count() ==0){
  //      SimpleChat.withMessageHisEnable && SimpleChat.loadMoreMesage({to_type:'group',people_uuid:uuid,type:'text', images: {$exists: true}}, {limit: 10, sort: {create_time: -1}}, 10);
  //   }
  //   SimpleChat.Messages.find({to_type:'group',people_uuid:uuid,type:'text', images: {$exists: true}},{sort:{create_time:-1}}).forEach(function(item){
  //     var date = new Date(item.create_time);
  //     var time = date.shortTime();
  //     var obj = {
  //       create_time: time,
  //       ts: item.create_time,
  //       images: item.images
  //     };
  //     if(tempDate !== time){
  //       obj.isShowTime = true;
  //     }
  //     msgs.push(obj);
  //     tempDate = time;
  //   });
  //   return msgs;
  // },

  lists: function(){
    var uuid = Router.current().params._uuid;
    var lists = [];
    DeviceTimeLine.find({uuid: uuid},{sort:{hour:-1}}).forEach(function(item){
      var tmpArr = [];
      for(x in item.perMin){
        var hour = new Date(item.hour)
        hour = hour.setMinutes(x);
        var tmpObj = {
          time: hour,
          images: []
        }
        item.perMin[x].forEach(function(img){
          tmpObj.images.push(img);
        });
        tmpArr.push(tmpObj);
      }
      tmpArr.reverse();
      lists = lists.concat(tmpArr);
    })
    return lists;
  },
  formatDate: function(time){
    var date = new Date(time);
    return date.shortTime()
  },
  isMultiSelect: function(){
    return Session.equals('timelineAlbumMultiSelect',true);
  }

});

Template.timelineAlbum.events({
  'click .back': function(){
    return PUB.back();
  },
  'click .images-click-able': function(e){
    var uuid = Router.current().params._uuid;
    device = Devices.findOne({uuid: uuid});
    var people_id = e.currentTarget.id,
        group_id  = device.groupId;
    var person_name = $(e.currentTarget).data('name') || '';
    var confirm_text = '';
    var person_info = {
      'name': person_name,
      'uuid': uuid,
      'group_id': group_id,
      'img_url': $(e.currentTarget).data('imgurl'),
      'type': 'face',
      'ts': $(e.currentTarget).data('ts'),
      'accuracy': 1,
      'fuzziness': 1
    };

    var data = {
      user_id:Meteor.userId(),
      face_id:people_id,
      person_info: person_info
    };

    if(device.in_out && device.in_out == 'in'){
      data.checkin_time =  new Date( $(e.currentTarget).data('ts')).getTime()
      data.checkin_image = $(e.currentTarget).data('imgurl');
    } else {
      data.checkout_time =  new Date( $(e.currentTarget).data('ts')).getTime()
      data.checkout_image = $(e.currentTarget).data('imgurl');
    }
    data.wantModify = Session.get('wantModify');
    console.log(data);
    // 检查是否标识过自己
    var relations = WorkAIUserRelations.findOne({'app_user_id':Meteor.userId()});
    var callbackRsu = function(res){

    };
    if(relations){ // 标识过
      confirm_text = '是否将该时间记录到每日出勤报告？';
      if(person_name){
        confirm_text = '是否将该时间记录到「'+person_name+'」每日出勤报告？'
      }
      PUB.confirm(confirm_text,function(){
        Meteor.call('ai-checkin-out',data,function(err, res){
          if(err){
            PUB.toast('记录失败，请重试');
            console.log('ai-checkin-out error:' + err);
            return;
          }
          if(timelineAlbumTimeout){
            window.clearTimeout(timelineAlbumTimeout);
          }
          timelineAlbumTimeout = setTimeout(function() {
            $("img.lazy").lazyload({});
          }, 500);
          if(res && res.result == 'succ'){
            PUB.toast('已记录到每日出勤报告');
            return PUB.back();
          } else {
            return navigator.notification.confirm(res.text,function(index){

            },res.reason,['知道了']);
          }
        });
      });
    } else {
      confirm_text = '是否选择此照片？';
      if(person_name){
        confirm_text = '此照片是：「'+person_name+'」，是否选择？';
      }
      else{
        Session.set('setPicturePersonNameData',data);
        $('#picturePersonName').val("");
        Meteor.setTimeout(function(){
          $('#picturePersonName').focus();
        },800);
        return $('#setPicturePersonName').modal('show');
        // confirm_text = '请选择一张有名字的照片或前往聊天室进行标记~';
        // var url = '/simple-chat/to/group?id='+ group_id;
        // try{
        //   navigator.notification.confirm(confirm_text,function
        //         (index){if (index === 2) {PUB.page(url);}},
        //         '提示',['重选','转入聊天室']);
        // }
        // catch (error){
        //   if(confirm(confirm_text)){
        //     PUB.page(url);
        //   }
        // }
      }
      PUB.confirm(confirm_text,function(){
        Meteor.call('ai-checkin-out',data,function(err,res){
          if(err){
            PUB.toast('请重试');
            console.log('ai-checkin-out error:' + err);
            return;
          }
          if(timelineAlbumTimeout){
            window.clearTimeout(timelineAlbumTimeout);
          }
          timelineAlbumTimeout = setTimeout(function() {
            $("img.lazy").lazyload({});
          }, 500);
          if(res && res.result == 'succ'){
            PUB.toast('已记录到每日出勤报告');
            return PUB.back();
          } else {
            return navigator.notification.confirm(res.text,function(index){

            },res.reason,['知道了']);
          }
        });
      });
    }
  },
  'click .confirmPersonName': function(e){
    var name = $('#picturePersonName').val();
    if(!name || name.length < 1){
      PUB.toast('请输入姓名');
      return $('#picturePersonName').focus();
    }
    var data = Session.get('setPicturePersonNameData');
    data.person_info.name = name;
    console.log(data);
    Meteor.call('ai-checkin-out',data,function(err,res){
      $('#setPicturePersonName').modal('hide');
      $('body').removeClass('modal-open');
      $('.modal-backdrop').remove();
      if(err){
        PUB.toast('请重试');
        console.log('ai-checkin-out error:' + err);
        return;
      }
      if(timelineAlbumTimeout){
        window.clearTimeout(timelineAlbumTimeout);
      }
      timelineAlbumTimeout = setTimeout(function() {
        $("img.lazy").lazyload({});
      }, 500);
      if(res && res.result == 'succ'){
        PUB.toast('已记录到每日出勤报告');
        return PUB.back();
      } else {
        return navigator.notification.confirm(res.text,function(index){

        },res.reason,['知道了']);
      }
    });
  }
});