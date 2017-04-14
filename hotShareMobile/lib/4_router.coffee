subs = new SubsManager({
  #maximum number of cache subscriptions
  cacheLimit: 999,
  # any subscription will be expire after 30 days, if it's not subscribed again
  expireIn: 60*24*30
});

if Meteor.isClient
  @refreshPostContent=()->
    layoutHelperInit()
    Session.set("displayPostContent",false)
    setTimeout ()->
      Session.set("displayPostContent",true)
      calcPostSignature(window.location.href.split('#')[0])
    ,300
  renderPost = (self,post)->
    if !post
      return self.render 'postNotFound'

    # if post and Session.get('postContent') and post.owner isnt Meteor.userId() and post._id is Session.get('postContent')._id and String(post.createdAt) isnt String(Session.get('postContent').createdAt)
    #   Session.set('postContent',post)
    #   refreshPostContent()
    #   toastr.info('作者修改了帖子内容.')
    # else
    Session.set('postContent',post)
    Session.set('focusedIndex',undefined)
    if post and post.addontitle and (post.addontitle isnt '')
      documentTitle = "『故事贴』" + post.title + "：" + post.addontitle
    else if post
      documentTitle = "『故事贴』" + post.title
    Session.set("DocumentTitle",documentTitle)
    if post
      self.render 'showPosts', {data: post}
    else
      self.render 'unpublish'
    Session.set 'channel','posts/'+self.params._id
  renderPost2 = (self,post)->
    if !post or (post.isReview is false and post.owner isnt Meteor.userId())
      return this.render 'postNotFound'
    if post and Session.get('postContent') and post.owner isnt Meteor.userId() and post._id is Session.get('postContent')._id and String(post.createdAt) isnt String(Session.get('postContent').createdAt)
      Session.set('postContent',post)
      refreshPostContent()
      toastr.info('作者修改了帖子内容.')
    else
      Session.set('postContent',post)
    Session.set('focusedIndex',undefined)
    if post and post.addontitle and (post.addontitle isnt '')
      documentTitle = "『故事贴』" + post.title + "：" + post.addontitle
    else if post
      documentTitle = "『故事贴』" + post.title
    Session.set("DocumentTitle",documentTitle)
    if post
      self.render 'showPosts', {data: post}
    else
      self.render 'unpublish'
    Session.set 'channel','posts/'+self.params._id
  renderPost3 = (self,post)->
    if !post or (post.isReview is false and post.owner isnt Meteor.userId())
      return this.render 'postNotFound'
    if post and Session.get('postContent') and post.owner isnt Meteor.userId() and post._id is Session.get('postContent')._id and String(post.createdAt) isnt String(Session.get('postContent').createdAt)
      Session.set('postContent',post)
      refreshPostContent()
      toastr.info('作者修改了帖子内容.')
    else
      Session.set('postContent',post)

    if Session.get("doSectionForward") is true
      Session.set("doSectionForward",false)
      Session.set("postPageScrollTop",0)
      document.body.scrollTop = 0
    Session.set("refComment",[''])
    Session.set('focusedIndex',self.params._index)
    if post.addontitle and (post.addontitle isnt '')
      documentTitle = post.title + "：" + post.addontitle
    else
      documentTitle = post.title
    Session.set("DocumentTitle",documentTitle)
    favicon = document.createElement('link')
    favicon.id = 'icon'
    favicon.rel = 'icon'
    favicon.href = post.mainImage
    document.head.appendChild(favicon)
    unless Session.equals('channel','posts/'+self.params._id+'/'+self.params._index)
      refreshPostContent()
    self.render 'showPosts', {data: post}
    Session.set('channel','posts/'+self.params._id+'/'+self.params._index)
  Meteor.startup ()->
    Tracker.autorun ()->
      channel = Session.get 'channel'
      $(window).off('scroll')
      console.log('channel changed to '+channel+' Off Scroll')
      setTimeout ->
          Session.set 'focusOn',channel
        ,300
    Tracker.autorun ()->
      if Session.get('channel') isnt 'addPost' and (Session.get('focusOn') is 'addPost')
        console.log('Leaving addPost mode')
        Session.set('showContentInAddPost',false)
        if window.iabHandle
          window.iabHandle.close()
          window.iabHandle = null
    Router.route '/',()->
      this.render 'home'
      Session.set 'channel','home'
      return
    Router.route '/group/add',()->
      if Meteor.isCordova is true
        this.render 'groupAdd'
      return
    Router.route '/seriesList',()->
      this.render 'seriesList'
      Session.set 'channel','seriesList'
    Router.route '/mySeries',()->
      this.render 'mySeries'
      Session.set 'channel','mySeries'
    Router.route '/series',()->
      Session.set('seriesId','')
      this.render 'series'
      return
    Router.route '/series/:_id',()->
      Meteor.subscribe("oneSeries",this.params._id)
      Meteor.subscribe("seriesFollow", this.params._id)
      console.log(this.params._id)
      seriesContent = Series.findOne({_id: this.params._id})
      Session.set('seriesId',this.params._id)
      Session.set('seriesContent',seriesContent)
      this.render 'series'
      return
    Router.route '/splashScreen',()->
      this.render 'splashScreen'
      Session.set 'channel', 'splashScreen'
      return
    Router.route '/search',()->
      if Meteor.isCordova is true
        this.render 'search'
        Session.set 'channel','search'
      return
    Router.route '/searchFollow',()->
      if Meteor.isCordova is true
        this.render 'searchFollow'
        Session.set 'channel','searchFollow'
      return
    Router.route '/searchPeopleAndTopic',()->
      if Meteor.isCordova is true
        this.render 'searchPeopleAndTopic'
        Session.set 'channel','searchPeopleAndTopic'
      return
    Router.route '/cropImage',()->
      this.render 'cropImage'
      return
    Router.route '/addressBook',()->
      if Meteor.isCordova is true
        this.render 'addressBook'
        Session.set 'channel','addressBook'
      return
    Router.route '/groupsList',()->
      if Meteor.isCordova is true
        Meteor.subscribe("get-my-group",Meteor.userId())
        this.render 'groupsList'
        Session.set 'channel','groupsList'
      return
    Router.route '/groupsProfile/:_type/:_id',()->
      console.log 'this.params._type'+this.params._type
      if this.params._type is 'group'
        limit = withShowGroupsUserMaxCount || 29;
        Meteor.subscribe("get-group-user-with-limit",this.params._id,limit)
      else
        Meteor.subscribe('usersById',this.params._id)
      console.log(this.params._id)
      Session.set('groupsId',this.params._id)
      Session.set('groupsType',this.params._type)
      this.render 'groupsProfile'
      return
    Router.route '/simpleUserProfile/:_id',()->
      Session.set('simpleUserProfileUserId',this.params._id)
      this.render 'simpleUserProfile'
      return
    Router.route '/explore',()->
      if Meteor.isCordova is true
        this.render 'explore'
        Session.set 'channel','explore'
      return
    Router.route '/bell',()->
      if Meteor.isCordova is true
        this.render 'bell'
        Session.set 'channel','bell'
      return
    Router.route '/user',()->
      if Meteor.isCordova is true
        this.render 'user'
        Session.set 'channel','user'
        return
    Router.route '/dashboard',()->
      if Meteor.isCordova is true
        this.render 'dashboard'
        return
    Router.route '/followers',()->
      if Meteor.isCordova is true
        this.render 'followers'
        return
    Router.route '/add',()->
      if Meteor.isCordova is true
        this.render 'addPost'
        Session.set 'channel','addPost'
        return
    Router.route '/registerFollow',()->
      if Meteor.isCordova is true
        this.render 'registerFollow'
        Session.set 'channel','registerFollow'
        return
    Router.route '/authOverlay',()->
      if Meteor.isCordova is true
        this.render 'authOverlay'
        Session.set 'channel','authOverlay'
        return
      else
        this.render 'webHome'
        return
    Router.route '/loginForm', ()->
      this.render 'loginForm'
      return
    Router.route '/signupForm', ()->
      this.render 'signupForm'
      return
    Router.route '/recoveryForm', ()->
      this.render 'recoveryForm'
      return

    Router.route '/webHome',()->
      this.render 'webHome'
      return
    Router.route '/help',()->
      this.render 'help'
      return
    Router.route '/progressBar',()->
      if Meteor.isCordova is true
        this.render 'progressBar'
        Session.set 'channel','progressBar'
        return
    Router.route '/redirect/:_id',()->
      Session.set('nextPostID',this.params._id)
      this.render 'redirect'
      return
    # Router.route '/posts/:_id', {
    #     waitOn: ->
    #       [subs.subscribe("publicPosts",this.params._id),
    #        subs.subscribe("postViewCounter",this.params._id),
    #        subs.subscribe("postsAuthor",this.params._id),
    #        subs.subscribe "pcomments"]
    #     loadingTemplate: 'loadingPost'
    #     action: ->
    #       post = Posts.findOne({_id: this.params._id})
    #       if !post or (post.isReview is false and post.owner isnt Meteor.userId())
    #         return this.render 'postNotFound'

    #       if post and Session.get('postContent') and post.owner isnt Meteor.userId() and post._id is Session.get('postContent')._id and String(post.createdAt) isnt String(Session.get('postContent').createdAt)
    #         Session.set('postContent',post)
    #         refreshPostContent()
    #         toastr.info('作者修改了帖子内容.')
    #       else
    #         Session.set('postContent',post)
    #       Session.set('focusedIndex',undefined)
    #       if post and post.addontitle and (post.addontitle isnt '')
    #         documentTitle = "『故事贴』" + post.title + "：" + post.addontitle
    #       else if post
    #         documentTitle = "『故事贴』" + post.title
    #       Session.set("DocumentTitle",documentTitle)
    #       if post
    #         this.render 'showPosts', {data: post}
    #       else
    #         this.render 'unpublish'
    #       if Session.get("readMomentsPost") is true
    #         Session.set 'readMomentsPost',false
    #         Session.set 'needReviewPostStyle',true
    #       Session.set 'channel','posts/'+this.params._id
    #   }
    Router.route '/posts/:_id', {
        loadingTemplate: 'loadingPost'
        action: ->
          self = this
          this.render 'loadingPost'
          if ajaxCDN?
            ajaxCDN.abort()
            ajaxCDN = null
          console.log(this.params._id);
          subs.subscribe "publicPosts",this.params._id, ()->
            console.log('subs loaded:', self.params._id);
          subs.subscribe("postViewCounter",this.params._id)
          subs.subscribe("postsAuthor",this.params._id)
          subs.subscribe "pcomments"
          post = Posts.findOne({_id: this.params._id})
          unless post
            # console.log("by ajax:", this.params._id)
            ajaxCDN = $.getJSON(rest_api_url+"/raw/"+this.params._id,(json,result)->
              post = Posts.findOne({_id: self.params._id})
              if post
                console.log('show subs post:', self.params._id);
                renderPost2(self, post)
              else if(result && result is 'success' && json && json.status && json.status is 'ok' && json.data)
                console.log('show ajax post:', self.params._id);
                Posts._connection._livedata_data({msg: 'added', collection: 'posts', id: new Mongo.ObjectID()._str, fields: json.data}) # insert post data
                post = json.data
                renderPost2(self, post)
              else
                this.render 'unpublish'
            )
            return
          renderPost2(self, post)
      }
    Router.route '/newposts/:_id', {
        action: ->
          self = this
          self.render 'loadingPost'
          Meteor.subscribe("reading",self.params._id)
          newpostsData = Session.get 'newpostsdata'
          if newpostsData
            renderPost(self,newpostsData)
          else
            post = Meteor.call("getPostContent",self.params._id)
            renderPost(self,post)
      }

    Router.route '/newposts1/:_id', {
        action: ->
          self = this
          self.render 'loadingPost'
          Meteor.subscribe("reading",self.params._id)
          $.getJSON(rest_api_url+"/raw/"+self.params._id,(json,result)->
            if(result && result is 'success' && json && json.status && json.status is 'ok' && json.data)
              post = json.data
              renderPost(self,post)
            else
              post = Meteor.call("getPostContent",self.params._id)
              renderPost(self,post)
          )
      }
    Router.route '/draftposts/:_id', {
      action: ->
        post = Session.get('postContent')

        if post and post.addontitle and (post.addontitle isnt '')
          documentTitle = "『故事贴』" + post.title + "：" + post.addontitle
        else if post
          documentTitle = "『故事贴』" + post.title
        Session.set("DocumentTitle",documentTitle)
        this.render 'showDraftPosts', {data: post}
        Session.set 'draftposts','draftposts/'+this.params._id
    }
    # Router.route '/posts/:_id/:_index', {
    #   waitOn: ->
    #     [Meteor.subscribe("publicPosts",this.params._id),
    #     Meteor.subscribe("postsAuthor",this.params._id),
    #     Meteor.subscribe "pcomments"]
    #   loadingTemplate: 'loadingPost'
    #   action: ->
    #     if Session.get("doSectionForward") is true
    #       Session.set("doSectionForward",false)
    #       Session.set("postPageScrollTop",0)
    #       document.body.scrollTop = 0
    #     post = Posts.findOne({_id: this.params._id})
    #     if !post or (post.isReview is false and post.owner isnt Meteor.userId())
    #       return this.render 'postNotFound'

    #     unless post
    #       console.log "Cant find the request post"
    #       this.render 'postNotFound'
    #       return
    #     Session.set("refComment",[''])
    #     if post and Session.get('postContent') and post.owner isnt Meteor.userId() and post._id is Session.get('postContent')._id and String(post.createdAt) isnt String(Session.get('postContent').createdAt)
    #       Session.set('postContent',post)
    #       refreshPostContent()
    #       toastr.info('作者修改了帖子内容.')
    #     else
    #       Session.set('postContent',post)
    #     Session.set('focusedIndex',this.params._index)
    #     if post.addontitle and (post.addontitle isnt '')
    #       documentTitle = post.title + "：" + post.addontitle
    #     else
    #       documentTitle = post.title
    #     Session.set("DocumentTitle",documentTitle)
    #     favicon = document.createElement('link')
    #     favicon.id = 'icon'
    #     favicon.rel = 'icon'
    #     favicon.href = post.mainImage
    #     document.head.appendChild(favicon)

    #     unless Session.equals('channel','posts/'+this.params._id+'/'+this.params._index)
    #       refreshPostContent()
    #     this.render 'showPosts', {data: post}
    #     Session.set('channel','posts/'+this.params._id+'/'+this.params._index)
    #   fastRender: true
    # }
    Router.route '/posts/:_id/:_index', {
      loadingTemplate: 'loadingPost'
      action: ->
        self = this
        this.render 'loadingPost'
        if ajaxCDN?
          ajaxCDN.abort()
          ajaxCDN = null
        console.log(this.params._id);
        subs.subscribe "publicPosts",this.params._id, ()->
          console.log('subs loaded:', self.params._id);
        subs.subscribe("postViewCounter",this.params._id)
        subs.subscribe("postsAuthor",this.params._id)
        subs.subscribe "pcomments"
        post = Posts.findOne({_id: this.params._id})
        unless post
          # console.log("by ajax:", this.params._id)
          ajaxCDN = $.getJSON(rest_api_url+"/raw/"+this.params._id,(json,result)->
            post = Posts.findOne({_id: self.params._id})
            if post
              console.log('show subs post:', self.params._id);
              renderPost3(self, post)
            else if(result && result is 'success' && json && json.status && json.status is 'ok' && json.data)
              console.log('show ajax post:', self.params._id);
              Posts._connection._livedata_data({msg: 'added', collection: 'posts', id: new Mongo.ObjectID()._str, fields: json.data}) # insert post data
              post = json.data
              renderPost3(self, post)
            else
              this.render 'unpublish'
          )
          return
        renderPost3(self, post)
      fastRender: true
    }
    # Router.route '/allDrafts',()->
    #   if Meteor.isCordova is true
    #     this.render 'allDrafts'
    #     Session.set 'channel','allDrafts'
    #     return
    Router.route '/allDrafts', {
      waitOn: ->
        [Meteor.subscribe("saveddrafts")]
      loadingTemplate: 'loadingPost'
      action: ->
        if Meteor.isCordova is true
          this.render 'allDrafts'
          Session.set 'channel','allDrafts'
    }
    Router.route '/myPosts',()->
      if Meteor.isCordova is true
        this.render 'myPosts'
        Session.set 'channel','myPosts'
        return
    Router.route '/my_email',()->
      if Meteor.isCordova is true
        this.render 'my_email'
        Session.set 'channel','my_email'
        return
    Router.route '/my_accounts_management', {
      waitOn: ->
        [Meteor.subscribe("userRelation")]
      loadingTemplate: 'loadingPost'
      action: ->
        if Meteor.isCordova is true
          this.render 'accounts_management'
          Session.set 'channel','my_accounts_management'
    }
    # Router.route '/my_accounts_management',()->
    #   if Meteor.isCordova is true
    #     this.render 'accounts_management'
    #     Session.set 'channel','my_accounts_management'
    #     return
    Router.route '/my_accounts_management_addnew',()->
      if Meteor.isCordova is true
        this.render 'accounts_management_addnew'
        Session.set 'channel','my_accounts_management_addnew'
        return
    Router.route '/my_password',()->
      if Meteor.isCordova is true
        this.render 'my_password'
        Session.set 'channel','my_password'
        return
    Router.route '/my_notice',()->
      if Meteor.isCordova is true
        this.render 'my_notice'
        Session.set 'channel','my_notice'
        return
    Router.route '/my_blacklist',()->
      if Meteor.isCordova is true
        this.render 'my_blacklist'
        Session.set 'channel','my_blacklist'
        return
    Router.route '/display_lang',()->
      if Meteor.isCordova is true
        this.render 'display_lang'
        Session.set 'channel','display_lang'
        return
    Router.route '/my_about',()->
      if Meteor.isCordova is true
        this.render 'my_about'
        Session.set 'channel','my_about'
        return
    Router.route '/deal_page',()->
      if Meteor.isCordova is true
        this.render 'deal_page'
        Session.set 'channel','deal_page'
        return
    Router.route '/topicPosts',()->
      if Meteor.isCordova is true
        this.render 'topicPosts'
        Session.set 'channel','topicPosts'
        return
    Router.route '/addTopicComment',()->
      if Meteor.isCordova is true
        this.render 'addTopicComment'
        Session.set 'addTopicComment_server_import', this.params.query.server_import
        Session.set 'channel','addTopicComment'
        return
    Router.route '/thanksReport',()->
      if Meteor.isCordova is true
        this.render 'thanksReport'
        Session.set 'channel','thanksReport'
        return
    Router.route '/reportPost',()->
      if Meteor.isCordova is true
        this.render 'reportPost'
        Session.set 'channel','reportPost'
        return
    Router.route '/userProfile',()->
      if Meteor.isCordova is true
        this.render 'userProfile'
        Session.set 'channel','userProfile'
        return
    Router.route 'userProfilePage1',
      template: 'userProfile'
      path: '/userProfilePage1'
    Router.route 'userProfilePage2',
      template: 'userProfile'
      path: '/userProfilePage2'
    Router.route 'userProfilePage3',
      template: 'userProfile'
      path: '/userProfilePage3'
    Router.route 'searchMyPosts',
      template: 'searchMyPosts'
      path: '/searchMyPosts'
    Router.route 'unpublish',
      template: 'unpublish'
      path: '/unpublish'
    Router.route 'setNickname',
      template: 'setNickname'
      path: '/setNickname'
    Router.route '/userProfilePage',()->
      this.render 'userProfilePage'
      return
    Router.route '/hotPosts/:_id',()->
      this.render 'hotPosts'
      return
    Router.route 'recommendStory',()->
      this.render 'recommendStory'
      return
if Meteor.isServer
  Router.route '/posts/:_id', {
      waitOn: ->
          [Meteor.subscribe("publicPosts",this.params._id),
           Meteor.subscribe("postsAuthor",this.params._id),
           Meteor.subscribe "pcomments"]
    }
