if Meteor.isClient
  Template.addPost.rendered=->
    $('.img').css('max-width',$(window).width())
    $('.mainImage').css('height',$(window).height()*0.55)
    $('.title').css('top',$(window).height()*0.25)
    $('.addontitle').css('top',$(window).height()*0.35)
  Template.addPost.helpers
    mainImage:->
      if Drafts.find().count() > 0
        Drafts.find().fetch()[0]
      else
        null
    items:()->
      if Drafts.find().count() > 1
        for i in [1..(Drafts.find().count()-1)]
          Drafts.find().fetch()[i]
  Template.addPost.events
    'click #addmore':->
      uploadFile (result)->
        console.log 'upload success: url is ' + result
        Drafts.insert {owner: Meteor.userId(), imgUrl:result}
    'click #cancle':->
      #Router.go('/')
      Drafts
        .find {owner: Meteor.userId()}
        .forEach (drafts)->
          Drafts.remove drafts._id
        return
    'click #publish':->
      if Meteor.user() is null
        Router.go('/user')
        false
      else
        pub=[]
        title = $("#title").val()
        addontitle = $("#addontitle").val()
        draftData = Drafts.find().fetch()
        postId = draftData[0]._id;
#        console.log "#####" + pub
        for i in [0..(draftData.length-1)]
#          console.log i
          if i is 0
            mainImage = draftData[i].imgUrl
            mainText = $("#"+draftData[i]._id+"text").val()
          else
            pub.push {
              imgUrl:draftData[i].imgUrl,
              text: $("#"+draftData[i]._id+"text").val(),
            }
#        console.log "#####end" + pub
        Posts.insert {
          _id:postId,
          pub:pub,
          title:title,
          addontitle:addontitle,
          mainImage: mainImage,
          mainText: mainText,
          owner:Meteor.userId(),
          createdAt: new Date()
        }
        Router.go('/posts/'+postId)
        Drafts
          .find {owner: Meteor.userId()}
          .forEach (drafts)->
            Drafts.remove drafts._id
          return
    'click .remove':(event)->
      Drafts.remove this._id
