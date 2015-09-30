if Meteor.isClient
  showDebug=false
  importColor=false
  titleRules = [
    # link string, class name
    {'prefix':'view.inews.qq.com','titleClass':'title'},
    {'prefix':'buluo.qq.com','titleClass':'post-title'}
  ]
  hostnameMapping = [
    {'hostname':'mp.weixin.qq.com',displayName:'微信公众号'},
    {'hostname':'m.toutiao.com',displayName:'头条'},
    {'hostname':'news.shou.com',displayName:'搜狐新闻'},
    {'hostname':'m.shou.com',displayName:'搜狐'},
    {'hostname':'www.zhihu.com',displayName:'知乎'},
    {'hostname':'card.weibo.com',displayName:'微博'},
    {'hostname':'mil.sohu.com',displayName:'搜狐军事'}
  ]
  musicExtactorMapping = [
    {
      musicClass:'.qqmusic_area',
      musicUrlSelector:'.qqmusic_area .qqmusic_thumb',
      musicUrlAttr:'data-autourl',
      musicImgSelector:'.qqmusic_area .qqmusic_thumb',
      musicImgAttr:'src',
      musicSongNameSelector:'.qqmusic_area .qqmusic_songname',
      musicSingerNameSelector:'.qqmusic_area .qqmusic_singername'
    },
    {
      musicClass:'mpvoice',
      musicUrlSelector:'mpvoice',
      musicUrlAttr:'voice_encode_fileid',
      prefixToMusicUrl:'http://res.wx.qq.com/voice/getvoice?mediaid=',
      musicImgSelector:'',
      musicImgAttr:'',
      musicSongNameSelector:'.audio_area .audio_info_area .audio_title',
      musicSingerNameSelector:'.audio_area .audio_info_area .audio_source'
    }
  ]
  getMusicFromPage = (page) ->
    for s in musicExtactorMapping
      if $(page).find(s.musicClass).length > 0
        playUrl = $(page).find(s.musicUrlSelector).attr(s.musicUrlAttr)
        if s.prefixToMusicUrl and s.prefixToMusicUrl isnt ''
          playUrl = s.prefixToMusicUrl + playUrl
        if s.musicImgSelector and s.musicImgSelector isnt ''
          image = $(page).find(s.musicImgSelector).attr(s.musicImgAttr)
        songName = $(page).find(s.musicSongNameSelector).text()
        singerName = $(page).find(s.musicSingerNameSelector).text()
        console.log('found music element ' + playUrl + ' image ' + image + ' song name ' + songName + ' singer ' + singerName)
        $(page).find(s.musicClass).remove()
        if playUrl
          return {
            playUrl : playUrl,
            image : image,
            songName : songName,
            singerName: singerName
          }
    return null
  ###
  http://stackoverflow.com/a/1634841/3380894
  To remove the width/height parameter in url, center the video play icon
  ###
  `function removeURLParameter(url, parameter) {
      //prefer to use l.search if you have a location/link object
      var urlparts= url.split('?');
      if (urlparts.length>=2) {

          var prefix= encodeURIComponent(parameter)+'=';
          var pars= urlparts[1].split(/[&;]/g);

          //reverse iteration as may be destructive
          for (var i= pars.length; i-- > 0;) {
              //idiom for string.startsWith
              if (pars[i].lastIndexOf(prefix, 0) !== -1) {
                  pars.splice(i, 1);
              }
          }

          url= urlparts[0]+'?'+pars.join('&');
          return url;
      } else {
          return url;
      }
  }`
  @seekSuitableImageFromArray = (imageArray,callback,minimal,onlyOne)->
    @imageCounter = 0
    @foundImages = 0
    if minimal
      minimalWidthAndHeight = minimal
    else
      minimalWidthAndHeight = 150
    unless @imageResolver
      @imageResolver = new Image()
    imageResolver.onload = ->
      height = imageResolver.height
      width = imageResolver.width
      showDebug&&console.log imageArray[imageCounter] + ' width is ' + width + ' height is ' + height
      if height >= minimalWidthAndHeight and width >= minimalWidthAndHeight
        showDebug&&console.log 'This image can be used ' + imageArray[imageCounter] + ' width is ' + width + ' height is ' + height
        callback imageArray[imageCounter],width,height, ++foundImages,imageCounter,imageArray.length
        if onlyOne
          return
      if ++imageCounter < imageArray.length
        imageResolver.src = imageArray[imageCounter]
      else
        callback null,0,0,foundImages,imageCounter,imageArray.length
    imageResolver.onerror = ->
      showDebug&&console.log 'image resolve url got error'
      if ++imageCounter < imageArray.length
        imageResolver.src = imageArray[imageCounter]
      else
        callback null,0,0,foundImages,imageCounter,imageArray.length
    imageResolver.src = imageArray[imageCounter]
  @seekSuitableImageFromArrayAndDownloadToLocal = (imageArray,callback,minimal,onlyOne)->
    @imageCounter = 0
    @foundImages = 0
    if minimal
      minimalWidthAndHeight = minimal
    else
      minimalWidthAndHeight = 150
    downloadHandler = (downloadedUrl,source,file)->
      #showDebug&&console.log('Got downloaded URL ' + downloadedUrl)
      if downloadedUrl
        onSuccess(downloadedUrl,source,file)
      else
        onError(source)
    onSuccess = (url,source,file)->
      #showDebug&&console.log('To call get_image_size_from_URI on ' + url)
      get_image_size_from_URI(url,(width,height)->
        #showDebug&&console.log url + ' width is ' + width + ' height is ' + height
        if height >= minimalWidthAndHeight and width >= minimalWidthAndHeight
          #showDebug&&console.log 'This image can be used ' + imageArray[imageCounter] + ' width is ' + width + ' height is ' + height
          callback file,width,height, ++foundImages,imageCounter,imageArray.length,source
          if onlyOne
            return
        if ++imageCounter < imageArray.length
          #showDebug&&console.log('imageCounter ' + imageCounter + ' imageArray.length ' + imageArray.length)
          downloadFromBCS(imageArray[imageCounter],downloadHandler)
        else
          callback null,0,0,foundImages,imageCounter,imageArray.length,source
      )
    onError = (source)->
      showDebug&&console.log 'image resolve url got error'
      if ++imageCounter < imageArray.length
        downloadFromBCS(imageArray[imageCounter],downloadHandler)
      else
        callback null,0,0,foundImages,imageCounter,imageArray.length,null,source
    downloadFromBCS(imageArray[imageCounter],downloadHandler)

  @analyseUrl = (url,callback)->
    @iabRef = window.open(url, '_blank', 'hidden=yes')
    iabRef.addEventListener 'loadstop', ()->
      showDebug&&console.log 'load stop'
      getImagesListFromUrl(iabRef,url,callback)
    iabRef.addEventListener 'loaderror', ()->
      showDebug&&console.log 'load error'
      if callback
        callback(null,0,0)
  @reAnalyseUrl = (url,callback)->
    unless iabRef
      callback(null,0,0)
      return
    getImagesListFromUrl(iabRef,url,callback)
  @clearLastUrlAnalyser = ()->
    if iabRef
      iabRef.close()
      iabRef = undefined
  @seekOneUsableMainImage = (data,callback,minimal)->
    imageArray = []
    #showDebug&&console.log 'Url Analyse result is ' + JSON.stringify(data)
    if data.imageArray
      for img in data.imageArray
        if img and img.startsWith("http")
          imageArray.push img
    if data.bgArray
      for bgImg in data.bgArray
        imageUrl = (bgImg.match( /url\([^\)]+\)/gi ) ||[""])[0].split(/[()'"]+/)[1]
        if imageUrl and imageUrl.startsWith("http")
          imageArray.push imageUrl
    showDebug&&console.log 'Got images to be anylised ' + JSON.stringify(imageArray)
    if imageArray.length > 0
      seekSuitableImageFromArrayAndDownloadToLocal imageArray,(file,w,h,found,index,length,source)->
        if file
          showDebug&&console.log('Original source:'+source+'Got local url '+ JSON.stringify(file)+' w:'+w+' h:'+h)
          callback(file,w,h,found,index,length,source)
        else
          showDebug&&console.log('No local url '+' w:'+w+' h:'+h)
          callback(null,0,0,found,index,length,source)
      ,minimal,true
    else
      callback(null,0,0,0,0,0,null)
  @processInAppInjectionData = (data,callback,minimal)->
    imageArray = []
    #showDebug&&console.log 'Url Analyse result is ' + JSON.stringify(data)
    if data.imageArray
      for img in data.imageArray
        if img and img.startsWith("http")
          imageArray.push img
    if data.bgArray
      for bgImg in data.bgArray
        imageUrl = (bgImg.match( /url\([^\)]+\)/gi ) ||[""])[0].split(/[()'"]+/)[1]
        if imageUrl and imageUrl.startsWith("http")
          imageArray.push imageUrl
    showDebug&&console.log 'Got images to be anylised ' + JSON.stringify(imageArray)
    if imageArray.length > 0
      seekSuitableImageFromArray imageArray,(url,w,h,found,index,length)->
        if url
          callback(url,w,h,found,index,length)
        else
          callback(null,0,0,found,index,length)
      ,minimal,false
    else
      callback(null,0,0,0,0,0)
  # data.body, the data to be analyse. (string)
  # return value
  # data.bgArray, the background images
  # data.imageArray, the image in the element
  grabImagesInHTMLString = (data)->
    documentBody = $.parseHTML( data.body )
    documentBody.innerHTML = data.body
    $(documentBody).find('img').each ()->
      dataSrc = $(this).attr('data-src')
      if dataSrc and dataSrc isnt ''
        src = dataSrc
      else
        src = $(this).attr('src')
      if src and src isnt ''
        src = src.replace(/&amp;/g, '&').replace("tp=webp","tp=jpeg")
        unless src.startsWith('http')
          if src.startsWith('//')
            src = data.protocol + src
          else if src.startsWith('/')
            src = data.protocol + '//' + data.host + '/' + src
        showDebug&&console.log 'Image Src: ' + src
        if (data.imageArray.indexOf src) <0
          data.imageArray.push src
    $(documentBody).find('input').each ()->
      src = $(this).attr('src')
      if src and src isnt '' and src.startsWith('http')
        src = src.replace(/&amp;/g, '&').replace("tp=webp","tp=jpeg")
        if (data.imageArray.indexOf src) <0
          showDebug&&console.log 'Got src is ' + src
          data.imageArray.push src
    $(documentBody).find('div').each ()->
      bg_url = $(this).css('background-image')
      # ^ Either "none" or url("...urlhere..")
      if bg_url and bg_url isnt ''
        bg_url = bg_url.replace(/&amp;/g, '&').replace("tp=webp","tp=jpeg")
        bg_url = /^url\((['"]?)(.*)\1\)$/.exec(bg_url)
        # If matched, retrieve url, otherwise ""
        if bg_url
          bg_url =  bg_url[2]
          if bg_url and bg_url isnt ''
            unless bg_url.startsWith('http')
              bg_url = data.protocol + '//' + data.host + '/' + bg_url
            showDebug&&console.log 'Background Image: ' + bg_url
            if (data.bgArray.indexOf bg_url) <0
              data.bgArray.push bg_url
    pattern = /img src=\"([\s\S]*?)(?=\")/g
    result = data.body.match(pattern)
    if result and result.length > 0
      showDebug&&console.log 'result ' + JSON.stringify(result)
      for subString in result
        dataSrc = subString.substring(9, subString.length).replace(/&amp;/g, '&').replace("tp=webp","tp=jpeg")
        if (data.imageArray.indexOf dataSrc) <0 and (data.bgArray.indexOf dataSrc) <0
          data.imageArray.push(dataSrc)
          showDebug&&console.log 'push dataSrc: ' + dataSrc
    pattern = /data-src=\"([\s\S]*?)(?=\")/g
    result = data.body.match(pattern)
    if result and result.length > 0
      showDebug&&console.log 'result ' + JSON.stringify(result)
      for subString in result
        dataSrc = subString.substring(10, subString.length).replace(/&amp;/g, '&').replace("tp=webp","tp=jpeg")
        if (data.imageArray.indexOf dataSrc) <0 and (data.bgArray.indexOf dataSrc) <0
          data.imageArray.push(dataSrc)
          showDebug&&console.log 'push dataSrc: ' + dataSrc
    pattern = /data-url=\"([\s\S]*?)(?=\")/g
    result = data.body.match(pattern)
    if result and result.length > 0
      showDebug&&console.log 'result ' + JSON.stringify(result)
      for subString in result
        dataSrc = subString.substring(10, subString.length).replace(/&amp;/g, '&').replace("tp=webp","tp=jpeg")
        if (data.imageArray.indexOf dataSrc) <0 and (data.bgArray.indexOf dataSrc) <0
          data.imageArray.push(dataSrc)
          showDebug&&console.log 'push dataSrc: ' + dataSrc
  @getImagesListFromUrl = (inappBrowser,url,callback)->
    inappBrowser.executeScript {
        code: '
          var returnJson = {};
          if(document.title){
            returnJson["title"] = document.title;
          }
          if(location.host){
            returnJson["host"] = location.host;
          }
          if(document.body){
            returnJson["body"] = document.body.innerHTML;
            returnJson["bodyLength"] = document.body.innerHTML.length;
          }
          if(window.location.protocol){
            returnJson["protocol"] = window.location.protocol;
          }
          returnJson;
      '}
    ,(data)->
      if data[0]
        showDebug&&console.log 'data0 is ' + JSON.stringify(data[0])
        data = data[0]
      data.bgArray = []
      data.imageArray = []
      grabImagesInHTMLString(data)
      documentBody = $.parseHTML( data.body )
      documentBody.innerHTML = data.body
      extracted = extract(documentBody)
      data.fullText = $(extracted).text()
      #showDebug&&console.log data.body
      callback data
  @getContentListsFromUrl = (inappBrowser,url,callback)->
    inappBrowser.executeScript {
        code: '
          var returnJson = {};
          if(document.title){
            returnJson["title"] = document.title;
          }
          if(location.host){
            returnJson["host"] = location.host;
          }
          if(document.body){
            returnJson["body"] = document.body.innerHTML;
            returnJson["bodyLength"] = document.body.innerHTML.length;
          }
          if(window.location.protocol){
            returnJson["protocol"] = window.location.protocol;
          }
          returnJson;
      '}
    ,(data)->
      if data[0]
        showDebug&&console.log 'data0 is ' + JSON.stringify(data[0])
        data = data[0]
      data.bgArray = []
      data.imageArray = []
      documentBody = $.parseHTML( data.body )
      documentBody.innerHTML = data.body

      for titleRule in titleRules
        if url.indexOf(titleRule.prefix) > -1
          realTitle = $(documentBody).find('.'+titleRule.titleClass).text()
          if realTitle and realTitle isnt ''
            data.host = data.title
            data.title = realTitle
            break
      for item  in hostnameMapping
        if data.host is item.hostname
          data.host = '摘自 ' + item.displayName
          break
      musicInfo = getMusicFromPage documentBody
      extracted = extract(documentBody)
      toBeInsertedText = ''
      previousIsImage = false
      resortedArticle = []
      sortedImages = 0

      if musicInfo
        resortedArticle.push {type:'music', musicInfo: musicInfo}
      if extracted.id is 'hotshare_special_tag_will_not_hit_other'
        toBeProcessed = extracted
      else
        toBeProcessed = extracted.innerHTML
      $(toBeProcessed).children().each (index,node)->
        info = {}
        info.bgArray = []
        info.imageArray = []
        info.body = node.innerHTML
        nodeColor = $(node).css('color')
        nodeBackgroundColor = $(node).css('background-color')
        #iframeNumber = $(node).find('iframe').length
        console.log('    Node['+index+'] tagName '+node.tagName+' text '+node.textContent)
        if node.tagName is 'BR'
          if toBeInsertedText.length > 0
            resortedArticle.push {type:'text',text:toBeInsertedText}
            toBeInsertedText = '';
        text = $(node).text().toString().replace(/\s\s\s+/g, '')
        if text and text isnt ''
          previousIsImage = false
          showDebug&&console.log '    Got text in this element('+toBeInsertedText.length+') '+text
          showDebug&&console.log 'Text  ['+text+'] color is '+nodeColor+' nodeBackgroundColor is '+nodeBackgroundColor
          if importColor and nodeColor and nodeColor isnt ''
            if toBeInsertedText.length > 0
              toBeInsertedText += '\n'
              resortedArticle.push {type:'text',text:toBeInsertedText}
              toBeInsertedText = ''
            resortedArticle.push {type:'text',text:text,color:nodeColor,backgroundColor:nodeBackgroundColor}
          else
            if text.length <80 and toBeInsertedText.length < 400
              if toBeInsertedText.length > 0
                toBeInsertedText += '\n'
              toBeInsertedText += text
            else
              if toBeInsertedText.length > 0
                resortedArticle.push {type:'text',text:toBeInsertedText}
              toBeInsertedText = text;
        if node.tagName == 'IFRAME'
          node.width = '100%'
          node.height = '100%'
          node.src = removeURLParameter(node.src,'width')
          node.src = removeURLParameter(node.src,'height')
          node.src = node.src.replace(/https:\/\//g, 'http://')
          node.removeAttribute("style")
          dataSrc = node.getAttribute('data-src')
          if dataSrc
            dataSrc = removeURLParameter(dataSrc,'width')
            dataSrc = removeURLParameter(dataSrc,'height')
            dataSrc = dataSrc.replace(/https:\/\//g, 'http://')
            node.setAttribute('data-src',dataSrc)
          showDebug&&console.log(node.outerHTML)
          if toBeInsertedText and toBeInsertedText isnt ''
            resortedArticle.push {type:'text',text:toBeInsertedText}
            toBeInsertedText = ''
          resortedArticle.push {type:'iframe',iframe:node.outerHTML}
        else if node.tagName == 'IMG'
          dataSrc = $(node).attr('data-src')
          if dataSrc and dataSrc isnt ''
            src = dataSrc
          else
            src = $(node).attr('src')
          if src and src isnt ''
            src = src.replace(/&amp;/g, '&').replace("tp=webp","tp=jpeg")
            unless src.startsWith('http')
              if src.startsWith('//')
                src = data.protocol + src
              else if src.startsWith('/')
                src = data.protocol + '//' + data.host + '/' + src
            showDebug&&console.log 'Image Src: ' + src
            previousIsImage = true
            if toBeInsertedText and toBeInsertedText isnt ''
              resortedArticle.push {type:'text',text:toBeInsertedText}
            toBeInsertedText = ''
            sortedImages++;
            resortedArticle.push {type:'image',imageUrl:src}
            data.imageArray.push src
        else if info.body
          grabImagesInHTMLString(info)
          if info.imageArray.length > 0
            showDebug&&console.log('    Got image')
            previousIsImage = true
            if toBeInsertedText and toBeInsertedText isnt ''
              resortedArticle.push {type:'text',text:toBeInsertedText}
            toBeInsertedText = ''
            for imageUrl in info.imageArray
              if imageUrl.startsWith('http://') or imageUrl.startsWith('https://')
                showDebug&&console.log('    save imageUrl ' + imageUrl)
                sortedImages++;
                resortedArticle.push {type:'image',imageUrl:imageUrl}
                data.imageArray.push imageUrl
          else if info.bgArray.length > 0
            showDebug&&console.log('    Got Background image')
            previousIsImage = true
            if toBeInsertedText and toBeInsertedText isnt ''
              resortedArticle.push {type:'text',text:toBeInsertedText}
            toBeInsertedText = ''
            for imageUrl in info.bgArray
              if imageUrl.startsWith('http://') or imageUrl.startsWith('https://')
                showDebug&&console.log('    save background imageUrl ' + imageUrl)
                sortedImages++
                resortedArticle.push {type:'image',imageUrl:imageUrl}
                data.imageArray.push imageUrl
      if toBeInsertedText and toBeInsertedText isnt ''
        resortedArticle.push {type:'text',text:toBeInsertedText}
      if sortedImages < 1
        grabImagesInHTMLString(data)
        if data.imageArray.length > 0
          for imageUrl in data.imageArray
            if imageUrl.startsWith('http://') or imageUrl.startsWith('https://')
              showDebug&&console.log('    save imageUrl ' + imageUrl)
              resortedArticle.push {type:'image',imageUrl:imageUrl}
        else if data.bgArray.length > 0
          for imageUrl in data.bgArray
            if imageUrl.startsWith('http://') or imageUrl.startsWith('https://')
              showDebug&&console.log('    save background imageUrl ' + imageUrl)
              resortedArticle.push {type:'image',imageUrl:imageUrl}
      if musicInfo
        data.musicInfo = musicInfo
      data.resortedArticle = resortedArticle
      showDebug&&console.log('Resorted Article is ' + data.resortedArticle)
      callback data
