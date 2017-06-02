var Fiber = Meteor.npmRequire('fibers');
var mqttMessages = new Meteor.Collection('mqttMessages');
var mqttPosts = new Meteor.Collection('mqttPosts');
var cluster = Meteor.npmRequire('cluster');

Meteor.startup(function(){
  if (!Date.prototype.format){
    Date.prototype.format = function(format) {
      var o = {
          "M+": this.getMonth() + 1,  //month
          "d+": this.getDate(),     //day
          "h+": this.getHours(),    //hour
          "m+": this.getMinutes(),  //minute
          "s+": this.getSeconds(), //second
          "q+": Math.floor((this.getMonth() + 3) / 3),  //quarter
          "S": this.getMilliseconds() //millisecond
      };
      if (/(y+)/.test(format)) {
          format = format.replace(RegExp.$1, (this.getFullYear() + "").substr(4 - RegExp.$1.length));
      }
      for (var k in o) {
          if (new RegExp("(" + k + ")").test(format)) {
              format = format.replace(RegExp.$1, RegExp.$1.length == 1 ? o[k] : ("00" + o[k]).substr(("" + o[k]).length));
          }
      }
      return format;
    };
  }
  var fromUser = Meteor.users.findOne({_id: 'zR2Y5Ar9k9LZQS9vS'}); // 故事贴小秘 -> tiegushi
  var deferSetImmediate = function(func) {
    var runFunction = function() {
            return func.apply(null);
    }
    if(typeof setImmediate == 'function') {
        setImmediate(function(){
            Fiber(runFunction).run();
        });
    } else {
        setTimeout(function(){
            Fiber(runFunction).run();
        }, 0);
    }
  }
  var formatPub = function(pub){
    for(var i=0;i<pub.length;i++){
      if(!pub[i]._id){pub[i]._id = new Mongo.ObjectID()._str;}
      if(pub[i].type === 'image'){
        pub[i].isImage = true;
        pub[i].data_sizey = 3;
      }else{
        pub[i].data_sizey = 1;
      }
      pub[i].data_row = 1;
      pub[i].data_col = 1;
      pub[i].data_sizex = 6;
    }

    // format
    for(var i=0;i<pub.length;i++){
      pub[i].index = i;
      pub[i].data_col = parseInt(pub[i].data_col);
      pub[i].data_row = parseInt(pub[i].data_row);
      pub[i].data_sizex = parseInt(pub[i].data_sizex);
      pub[i].data_sizey = parseInt(pub[i].data_sizey);
      pub[i].data_wait_init = true;
      if (i > 0) {
        pub[i].data_row = pub[i-1].data_row + pub[i-1].data_sizey;
      }
    }

    return pub;
  };
  var insertNewMsg = function(pub, doc, userId){
    switch(doc.type){
      case 'text':
        pub.unshift({
          _id: new Mongo.ObjectID()._str,
          type: 'text',
          isImage: false,
          owner: userId,
          text: doc.form.name.trim() + ': ' + new Date(doc.create_time).format('yyyy-MM-dd hh:mm') + '\n' + doc.text,
          style: '',
          layout: {
            font: 'quota'
          },
          data_row: 1,
          data_col: 1,
          data_sizex: 6,
          data_sizey: 3
        });
        break;
      case 'image':
        pub.unshift({
          _id: new Mongo.ObjectID()._str,
          type: 'image',
          isImage: true,
          owner: userId,
          imgUrl: doc.images[0].url,
          data_row: 1,
          data_col: 1,
          data_sizex: 6,
          data_sizey: 3
        });
        pub.unshift({
          _id: new Mongo.ObjectID()._str,
          type: 'text',
          isImage: false,
          owner: userId,
          text: doc.form.name.trim() + ': ' + new Date(doc.create_time).format('yyyy-MM-dd hh:mm') + '\n[图片]',
          style: '',
          layout: {
            font: 'quota'
          },
          data_row: 1,
          data_col: 1,
          data_sizex: 6,
          data_sizey: 3
        });
        break;
    }
  };
  var upsetTipImg = function(pub, userId){
    var index = -1;
    for(var i=0;i<pub.length;i++){
      if(pub[i].tipImg){
        index = i;
        break;
      }
    }
    if(index >= 0)
      pub.splice(index, 1);

    pub.unshift({
      _id: new Mongo.ObjectID()._str,
      type: 'image',
      isImage: true,
      owner: userId,
      imgUrl: 'http://data.tiegushi.com/Ju3gGj3Xb4CFyrihY_1495872904864_cdv_photo_003.jpg',
      data_row: 1,
      data_col: 1,
      data_sizex: 6,
      data_sizey: 3,
      tipImg: true
    });
  }
  var findAndCreatePost = function(userId, doc){
    var user = Meteor.users.findOne({_id: userId});
    var postId = userId+'11';
    var post = mqttPosts.findOne({_id:postId});
    if (!post){
      post = {
        pub: [
          {
            _id: new Mongo.ObjectID()._str,
            type: 'text',
            isImage: false,
            owner: user._id,
            text: '打开链接更新最新版本，随时私信聊天，轻松互动，下载地址：http://cdn.tiegushi.com',
            layout: {
              align: 'center'
            },
            style: '',
            data_row: 1,
            data_col: 1,
            data_sizex: 6,
            data_sizey: 3
          }
        ],
        _id: postId,
        title: '您有新的私信消息（1条）',
        addontitle: '下载新版本可互动',
        browse: 0,
        heart: [],
        retweet: [],
        comment: [],
        commentsCount: 0,
        mainImage: 'http://data.tiegushi.com/Ju3gGj3Xb4CFyrihY_1495869374666_cdv_photo_002.jpg',
        publish: true,
        owner: user._id,
        ownerName: user.profile && user.profile.fullname ? user.profile.fullname : user.username,
        ownerIcon: user.profile && user.profile.icon ? user.profile.icon : '/userPicture.png',
        createdAt: new Date(),
        isReview: true,
        insertHook: true,
        import_status: 'done',
        fromUrl: '',
        message_post: true,
        message_count: 0
      }
      console.log('insert post:', post._id);
      insertNewMsg(post.pub, doc);
      upsetTipImg(post.pub, userId);
      formatPub(post.pub);
      post.message_count += 1;
      post.title = '您有新的私信消息（'+post.message_count+'条）';
      mqttPosts.insert(post);
      Posts.insert(post);
    } else {
      console.log('update post:', post._id);
      insertNewMsg(post.pub, doc);
      upsetTipImg(post.pub, userId);
      formatPub(post.pub);
      post.message_count += 1;
      post.title = '您有新的私信消息（'+post.message_count+'条）';
      mqttPosts.update({_id: post._id}, {$set: {pub: post.pub, message_count: post.message_count, title: post.title}});
      Posts.update({_id: post._id}, {$set: {pub: post.pub, message_count: post.message_count, title: post.title}});
    }

    return post;
  };
  var createOrUpdateFollowPosts = function(userId, post){
    var postId = userId + '11';
    var followPost = FollowPosts.findOne({_id:postId});
    if (!followPost){
      followPost = {
        _id: postId,
        postId:post._id,
        title:post.title,
        addontitle:post.addontitle,
        mainImage: post.mainImage,
        mainImageStyle:post.mainImageStyle,
        heart:0,
        retweet:0,
        comment:0,
        browse: 0,
        publish: post.publish,
        owner:post.owner,
        ownerName:post.ownerName,
        ownerIcon:post.ownerIcon,
        createdAt: new Date(),
        message_post: true,
        followby: userId
      };
      followPost.title = post.title;
      followPost.addontitle = post.addontitle;
      FollowPosts.insert(followPost);
    } else {
      followPost.title = post.title;
      followPost.addontitle = post.addontitle;
      FollowPosts.update({_id: followPost._id}, {$set: {createdAt: new Date(), title: post.title, postId: post._id}});
    }

    return followPost;
  };

  var tasks = [];
  var task = null;
  var runTask = function(){
    if (task)
      return;

    task = tasks.shift();
    if (task){
      publishPostToUser(task.id, task.doc);
      task = null;
      return runTask();
    }
  };

  var publishPostToUser = function(id, doc){
    try{
      var post = findAndCreatePost(doc.to.id, doc);
      createOrUpdateFollowPosts(doc.to.id, post);
    }catch(e){console.log(e);}
    console.log('['+id+']发送私信消息给老版本用户 =>', doc.to.id);
  };

  if(process.env.PRODUCTION != true && process.env.NODE_ENV === 'production' && cluster.isMaster === true){
    mqttMessages.find({}).observeChanges({
      added: function(id, fields){
        try{mqttMessages.remove({_id: id});}catch(e){}
        tasks.push({id: id, doc: fields});
        runTask();
        // publishPostToUser(id, fields);
      }
    });
  }
});
