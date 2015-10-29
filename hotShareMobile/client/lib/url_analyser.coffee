if Meteor.isClient
  showDebug=false
  importColor=false
  titleRules = [
    # link string, class name
    {prefix:'view.inews.qq.com',titleClass:'title'},
    {prefix:'buluo.qq.com',titleClass:'post-title'},
    {prefix:'wap.koudaitong.com',titleClass:'custom-title.wx_template .title'}
  ]
  hostnameMapping = [
    {hostname:'mp.weixin.qq.com',displayName:'微信公众号'},
    {hostname:'m.toutiao.com',displayName:'头条'},
    {hostname:'news.shou.com',displayName:'搜狐新闻'},
    {hostname:'m.shou.com',displayName:'搜狐'},
    {hostname:'www.zhihu.com',displayName:'知乎'},
    {hostname:'card.weibo.com',displayName:'微博'},
    {hostname:'mil.sohu.com',displayName:'搜狐军事'},
    {hostname:'wap.koudaitong.com',displayName:'罗辑思维'}
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
  musicExtactorMappingV2 = [
    {
      nodeSelector: 'QQMUSIC'
      parentSelector: ''
      getMusicUrl:(node, body)->
        return $(node).attr('audiourl')
      getMusicThumbImageURL:(node, body)->
        return $(node.parentNode).find('.qqmusic_area .play_area img')[1].attr('src')
      getMusicSongName:(node, body)->
        return $(body).find('.qqmusic_area .qqmusic_songname').text()
      getMusicSingerName:(node, body)->
        return $(body).find('.qqmusic_area .qqmusic_singername').text()
      cleanUp:(node, body)->
        $(node.parentNode).remove('.qqmusic_area')
    },
    {
      nodeSelector: 'MPVOICE'
      parentSelector: ''
      getMusicUrl:(node)->
        playUrl = node.getAttribute('voice_encode_fileid');
        if playUrl and playUrl isnt ''
          playUrl = 'http://res.wx.qq.com/voice/getvoice?mediaid='+playUrl
          console.log('getMusicUrl '+playUrl)
          return playUrl
        ''
      getMusicThumbImageURL:(node)->
        console.log('getMusicThumbImageURL None')
        ''
      getMusicSongName:(node)->
        console.log('GetMusicSongName')
        if node and node.parentNode
          return $(node.parentNode).find('.audio_area .audio_info_area .audio_title').text()
        ''
      getMusicSingerName:(node)->
        console.log('getMusicSingerName')
        if node and node.parentNode
          return $(node.parentNode).find('.audio_area .audio_info_area .audio_source').text()
        ''
      cleanUp:(node)->
        if node and node.parentNode
          return $(node.parentNode).remove('.audio_area')
    },
    {
      nodeSelector: '#playerbox'
      parentSelector: ''
      getMusicInfo:(node, body)->
        for item in $(body).find('script')
          text = item.innerText
          if text.indexOf('window.__bootstrap_data') isnt -1
            eval(text)
            if window.__bootstrap_data.song
              return {
                playUrl: window.__bootstrap_data.song.url
                image: window.__bootstrap_data.song.picture
                songName: window.__bootstrap_data.song.title
                singerName: window.__bootstrap_data.song.artist
              }
          return {}
      cleanUp:(node)->
        if node and node.parentNode
          return $(node).html('')
    }
    {
      nodeSelector: '.j-orientation-0'
      parentSelector: ''
      getMusicInfo:(node, body)->
        console.log(node)
        for item in $(body).find('#j-body script')
          text = item.innerText
          if text.indexOf('showData:{"') isnt -1
            text = text.substr(text.indexOf('showData:{"') + 'showData:'.length)
            text = text.substring(0, text.indexOf('"}},')+3)
            obj = JSON.parse(text)
            return {
              playUrl: obj.data.url
              image: obj.data.cover
              songName: obj.data.name
              singerName: obj.data.ownername
            }
        return {}
      cleanUp:(node)->
    }
    {
      nodeSelector: ''
      parentSelector: '.article'
      getMusicInfo:(node, body)->
        for item in $(body).find('script')
          text = item.innerText
          if text.indexOf('mp3:"/') isnt -1
            text = text.substr(text.indexOf('mp3:"/') + 'mp3:"/'.length)
            text = text.substring(0, text.indexOf('.mp3"')+4)
            player = $(body).find('#jp_container_1')
            
            return {
              playUrl: 'http://yuedu.fm' + text
              image: 'http://yuedu.fm' + player.find('.cover img').attr('src')
              songName: player.find('.item-title h1').text()
              singerName: player.find('.item-title p').text()
            }
        return {}
      cleanUp:(node)->
    }
    {
      nodeSelector: '.song_infosong_info' # QQ 音乐
      parentSelector: ''
      getMusicInfo:(node, body)->
        return {
          playUrl: $(body).find('#h5audio_media').attr('src')
          image: $(node).find('.album_cover__img').attr('src')
          songName: $(node).find('.song_name__text').text()
          singerName: $(node).find('.singer_name__text').text()
        }
      cleanUp:(node)->
        $(node).html()
    }
  ]
  @getMusicFromNode = (node, body) ->
    for s in musicExtactorMappingV2
      isExist = false
      findNone = node
      
      if s.nodeSelector isnt '' and node.nodeType isnt Node.TEXT_NODE
        if s.nodeSelector.indexOf('#') is 0
          if node.id is s.nodeSelector.substr(1)
            isExist = true
        else if s.nodeSelector.indexOf('.') is 0
          if node.className is s.nodeSelector.substr(1)
            isExist = true
        else
          if node.tagName is s.nodeSelector.toUpperCase()
            isExist = true
      else if s.parentSelector isnt '' and $(node.parentNode).find('musicExtracted').length <= 0
        if s.parentSelector.indexOf('#') is 0
          if node.parentNode.id is s.parentSelector.substr(1)
            findNone = node.parentNode
            isExist = true
        else if s.parentSelector.indexOf('.') is 0
          if node.parentNode.className is s.parentSelector.substr(1)
            findNone = node.parentNode
            isExist = true
        else
          if node.parentNode.tagName is s.parentSelector.toUpperCase()
            findNone = node.parentNode
            isExist = true
            
      if isExist is true
        musicInfo = {}
        if s.getMusicInfo
          musicInfo = s.getMusicInfo(findNone, body)
        else
          if typeof(s.getMusicUrl) is 'function'
            musicInfo.playUrl = s.getMusicUrl(findNone, body)
          if typeof(s.getMusicThumbImageURL) is 'function'
            musicInfo.image = s.getMusicThumbImageURL(findNone, body)
          if typeof(s.getMusicSongName) is 'function'
            musicInfo.songName = s.getMusicSongName(findNone, body)
          if typeof(s.getMusicSingerName) is 'function'
            musicInfo.singerName = s.getMusicSingerName(findNone, body)
        if typeof(s.cleanUp) is 'function'
            s.cleanUp(findNone, body)
        if musicInfo.playUrl
          musicElement = document.createElement("musicExtracted")
          musicElement.setAttribute('playUrl', musicInfo.playUrl)
          musicElement.setAttribute('image', musicInfo.image)
          musicElement.setAttribute('songName', musicInfo.songName)
          musicElement.setAttribute('singerName', musicInfo.singerName)
          
          findNone.appendChild(musicElement)
          console.log('Got Music Info '+JSON.stringify(musicInfo))
          return musicInfo
      else if s.parentSelector isnt '' and $(node.parentNode).find('musicExtracted').length > 0
        musicInfo = {}
        musicInfo.playUrl = $(node.parentNode).find('musicExtracted').attr('playUrl')
        musicInfo.image = $(node.parentNode).find('musicExtracted').attr('image')
        musicInfo.songName = $(node.parentNode).find('musicExtracted').attr('songName')
        musicInfo.singerName = $(node.parentNode).find('musicExtracted').attr('singerName')
        return musicInfo
    return null
  @getMusicFromScript = (url, page)->
    for mapping in musicExtactorScriptMapping
      if (url.toLowerCase().indexOf(mapping.url) is 0)
        return extractScript(page, mapping.getMusic)

    return null
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
  _html2data = (url, data, callback)->
    Meteor.defer ()->
      if data[0]
        showDebug&&console.log 'data0 is ' + JSON.stringify(data[0])
        data = data[0]
      data.bgArray = []
      data.imageArray = []
      documentBody = $.parseHTML( data.body )
      documentBody.innerHTML = data.body

      for titleRule in titleRules
        if url.indexOf(titleRule.prefix) > -1
          realTitle = $(documentBody).find('.'+titleRule.titleClass).text().replace(/^\s+|\s+$/g, "")
          if realTitle and realTitle isnt ''
            #data.host = data.title
            data.title = realTitle
            break
      for item  in hostnameMapping
        if data.host is item.hostname
          data.host = '摘自 ' + item.displayName
          break

      #musicInfo = getMusicFromPage documentBody
      extracted = extract(documentBody)
      console.log('extracted:')
      console.log(extracted)
      
      toBeInsertedText = ''
      toBeInsertedStyleAlign=''
      previousIsImage = false
      resortedArticle = []
      sortedImages = 0

#      musics = getMusicFromScript(url, documentBody)
#      if(musics.length > 0)
#        for musicInfo in musics
#          resortedArticle.push {type:'music', musicInfo: musicInfo}

      if extracted.id is 'hotshare_special_tag_will_not_hit_other'
        toBeProcessed = extracted
      else
        toBeProcessed = extracted.innerHTML
      console.log($(toBeProcessed))
      previousIsSpan = false
      $(toBeProcessed).children().each (index,node)->
        info = {}
        info.bgArray = []
        info.imageArray = []
        info.body = node.innerHTML
        nodeColor = $(node).css('color')
        nodeBackgroundColor = $(node).css('background-color')
        #iframeNumber = $(node).find('iframe').length
        console.log('    Node['+index+'] tagName '+node.tagName+' text '+node.textContent)
        styleAlign=getStyleInItem(node,'textAlign')
        console.log('    Got style '+styleAlign);
        if node.tagName is 'BR'
          if toBeInsertedText.length > 0
            resortedArticle.push {type:'text',text:toBeInsertedText,layout:{align:toBeInsertedStyleAlign}}
            toBeInsertedText = ''
            toBeInsertedStyleAlign = ''
            previousIsSpan = false
            return true
        else if node.tagName is 'MUSICEXTRACTED'
          if toBeInsertedText and toBeInsertedText isnt ''
            resortedArticle.push {type:'text',text:toBeInsertedText}
            toBeInsertedText = ''

          playUrl=node.getAttribute('playUrl')
          image=node.getAttribute('image')
          songName=node.getAttribute('songName')
          singerName=node.getAttribute('singerName')
          resortedArticle.push {type:'music', musicInfo: {
            playUrl:playUrl
            image:image
            songName:songName
            singerName:singerName
          }}
          previousIsSpan = false
          return true
        text = $(node).text()
        if text and text isnt ''
          text = text.replace(/\s\s\s+/g, '')
        console.log('text '+text)
        if node.tagName == 'IFRAME'
          previousIsSpan = false
          node.width = '100%'
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
            dataSrc = dataSrc.replace(/v.qq.com\/iframe\/preview.html/g, 'v.qq.com/iframe/player.html')
            node.setAttribute('data-src',dataSrc)
            node.src = dataSrc
          showDebug&&console.log(node.outerHTML)
          if toBeInsertedText and toBeInsertedText isnt ''
            resortedArticle.push {type:'text',text:toBeInsertedText}
            toBeInsertedText = ''
          resortedArticle.push {type:'iframe',iframe:node.outerHTML}
        else if node.tagName == 'IMG'
          previousIsSpan = false
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
            previousIsSpan = false
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
            previousIsSpan = false
            if toBeInsertedText and toBeInsertedText isnt ''
              resortedArticle.push {type:'text',text:toBeInsertedText}
            toBeInsertedText = ''
            for imageUrl in info.bgArray
              if imageUrl.startsWith('http://') or imageUrl.startsWith('https://')
                showDebug&&console.log('    save background imageUrl ' + imageUrl)
                sortedImages++
                resortedArticle.push {type:'image',imageUrl:imageUrl}
                data.imageArray.push imageUrl
        if text and text isnt ''
          previousIsImage = false
          showDebug&&console.log '    Got text in this element('+toBeInsertedText.length+') '+text
          showDebug&&console.log 'Text  ['+text+'] color is '+nodeColor+' nodeBackgroundColor is '+nodeBackgroundColor
          ###
          if importColor and nodeColor and nodeColor isnt ''
            if toBeInsertedText.length > 0
              toBeInsertedText += '\n'
              resortedArticle.push {type:'text',text:toBeInsertedText}
              toBeInsertedText = ''
            resortedArticle.push {type:'text',text:text,color:nodeColor,backgroundColor:nodeBackgroundColor}
          else
          ###
          #console.log('Get style '+$(node).attr('style'));
          if toBeInsertedText.length is 0
            toBeInsertedStyleAlign = styleAlign
          if node.tagName is 'SPAN'
            toBeInsertedText +=text
            previousIsSpan = true
          else if previousIsSpan is true
            toBeInsertedText += text
            previousIsSpan = false
            text = ''
          else if toBeInsertedText.length < 20 and styleAlign is toBeInsertedStyleAlign
            if toBeInsertedText.length > 0
              toBeInsertedText += '\n'
            toBeInsertedText += text
          else
            if toBeInsertedText.length > 0
              resortedArticle.push {type:'text',text:toBeInsertedText,layout:{align:toBeInsertedStyleAlign}}
            toBeInsertedText = text;
            toBeInsertedStyleAlign = styleAlign;
      if toBeInsertedText and toBeInsertedText isnt ''
        resortedArticle.push {type:'text',text:toBeInsertedText}
      if sortedImages < 1
        console.log('no image ?')
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
      data.resortedArticle = resortedArticle
      showDebug&&console.log('Resorted Article is ' + JSON.stringify(data.resortedArticle))
      callback data
  _html2data2 = (url, data, callback)->
    Meteor.defer ()->
      #Added by Frank, get paragraphs and insert into an array
      pageInnerText = ''
      previousParagraph = ''
      paragraphArray = []
      paragraphArrayTmp = []
      initParagraphArray = (extracted)->
          divElement = document.createElement("div");
          divElement.style.display = ''
          divElement.style.height = 0
          divElement.style.width = 0
          divElement.style.left = -100;
          divElement.style.position = 'absolute'
          divElement.appendChild(extracted);
          document.body.appendChild(divElement);
          pageInnerText = divElement.innerText
          console.log("pageInnerText = "+pageInnerText)
          console.log("divElement.innerHTML = "+divElement.innerHTML)
          paragraphArrayTmp = pageInnerText.split('\n')
          document.body.removeChild(divElement)
          if paragraphArrayTmp.length > 0
            isLineBreak = false
            ###
            for i in [0..paragraphArrayTmp.length-1]
              console.log('paragraphArrayTmp['+i+']='+paragraphArrayTmp[i])
              str = paragraphArrayTmp[i];
              hexStr = ''
              for j in [0..str.length-1]
                num = str.charCodeAt(j);
                hexStr = hexStr + num.toString(16) + ' '
              console.log('hexStr = '+hexStr)
            ###
            for i in [0..paragraphArrayTmp.length-1]
              #if (paragraphArrayTmp[i].length == 0 or paragraphArrayTmp[i] == ' ')
              if (paragraphArrayTmp[i].length == 0)
                if isLineBreak
                  if (paragraphArray.length == 0)
                    paragraphArray.push('\n')
                  else
                    paragraphArray[paragraphArray.length-1] = paragraphArray[paragraphArray.length-1]+'\n'
                else
                  isLineBreak = true
              else
                isLineBreak = false
                paragraphArray.push(paragraphArrayTmp[i])
          if paragraphArray.length > 0
            console.log("paragraphArray.length="+paragraphArray.length)
            for i in [0..paragraphArray.length-1]
              console.log('paragraphArray['+i+']='+paragraphArray[i])
      findInParagraphsArray = (text)->
        outputParagraphs = []
        if paragraphArray.length > 0
          for i in [0..paragraphArray.length-1]
              curParagraph = paragraphArray[i]
              if curParagraph.length > 0 and curParagraph.length >= text.length
                comparelen = Math.min(text.length, 30)
                if curParagraph.substr(0, comparelen).indexOf(text.substr(0, comparelen)) >= 0
                  for j in [0..i]
                    outputParagraphs.push(paragraphArray[j])
                  paragraphArray.splice(0, i+1)
                  previousParagraph = ''
                  break;
        return outputParagraphs;
      getOutputParagraphs = (text)->
        if previousParagraph.length > 0 and previousParagraph.length >= text.length
          index = previousParagraph.indexOf(text)
          if index >= 0
            previousParagraph = previousParagraph.substr(index+text.length)
            return []
          else
            return findInParagraphsArray(text)
        else
          return findInParagraphsArray(text)
      appendParagraph = (resortedArticle, text, styleAlign)->
        appendTextWithStyleAlign = ()->
          if styleAlign is undefined
            resortedArticle.push {type:'text',text:text}
          else
            resortedArticle.push {type:'text',text:text,layout:{align:styleAlign}}
        appendTextWithStyleAlign()
        return
        if resortedArticle.length > 0
          lastArtical = resortedArticle[resortedArticle.length-1]
          if lastArtical.type is 'text'
            if lastArtical.text.length < 20 and styleAlign is (if lastArtical.layout then lastArtical.layout.align else undefined)
              lastArtical.text += '\n' + text
            else
              appendTextWithStyleAlign()
          else
            appendTextWithStyleAlign()
        else
          appendTextWithStyleAlign()


      if data[0]
        showDebug&&console.log 'data0 is ' + JSON.stringify(data[0])
        data = data[0]
      data.bgArray = []
      data.imageArray = []
      documentBody = $.parseHTML( data.body )
      documentBody.innerHTML = data.body

      for titleRule in titleRules
        if url.indexOf(titleRule.prefix) > -1
          realTitle = $(documentBody).find('.'+titleRule.titleClass).text().replace(/^\s+|\s+$/g, "")
          if realTitle and realTitle isnt ''
            #data.host = data.title
            data.title = realTitle
            break
      for item  in hostnameMapping
        if data.host is item.hostname
          data.host = '摘自 ' + item.displayName
          break

      #musicInfo = getMusicFromPage documentBody
      extracted = extract(documentBody)
      initParagraphArray(extracted)
      toBeInsertedText = ''
      toBeInsertedStyleAlign=''
      previousIsImage = false
      resortedArticle = []
      sortedImages = 0

#      musics = getMusicFromScript(url, documentBody)
#      if(musics.length > 0)
#        for musicInfo in musics
#          resortedArticle.push {type:'music', musicInfo: musicInfo}

      if extracted.id is 'hotshare_special_tag_will_not_hit_other'
        toBeProcessed = extracted
      else
        toBeProcessed = extracted.innerHTML
      console.log($(toBeProcessed))
      $(toBeProcessed).children().each (index,node)->
        info = {}
        info.bgArray = []
        info.imageArray = []
        info.body = node.innerHTML
        nodeColor = $(node).css('color')
        nodeBackgroundColor = $(node).css('background-color')
        #iframeNumber = $(node).find('iframe').length
        console.log('    Node['+index+'] tagName '+node.tagName+' text '+node.textContent)
        styleAlign=getStyleInItem(node,'textAlign')
        console.log('    Got style '+styleAlign);
        if node.tagName is 'BR'
          if toBeInsertedText.length > 0
            #resortedArticle.push {type:'text',text:toBeInsertedText,layout:{align:toBeInsertedStyleAlign}}
            toBeInsertedText = '';
            toBeInsertedStyleAlign = '';
            return true
        else if node.tagName is 'MUSICEXTRACTED'
          if toBeInsertedText and toBeInsertedText isnt ''
            #resortedArticle.push {type:'text',text:toBeInsertedText}
            toBeInsertedText = ''

          playUrl=node.getAttribute('playUrl')
          image=node.getAttribute('image')
          songName=node.getAttribute('songName')
          singerName=node.getAttribute('singerName')
          resortedArticle.push {type:'music', musicInfo: {
            playUrl:playUrl
            image:image
            songName:songName
            singerName:singerName
          }}
          return true
        text = $(node).text()
        if text and text isnt ''
          text = text.replace(/\s\s\s+/g, '')

        if node.tagName == 'IFRAME'
          node.width = '100%'
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
            node.src = dataSrc
          showDebug&&console.log(node.outerHTML)
          if toBeInsertedText and toBeInsertedText isnt ''
            #resortedArticle.push {type:'text',text:toBeInsertedText}
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
            #if toBeInsertedText and toBeInsertedText isnt ''
            #  resortedArticle.push {type:'text',text:toBeInsertedText}
            toBeInsertedText = ''
            sortedImages++;
            resortedArticle.push {type:'image',imageUrl:src}
            data.imageArray.push src
        else if info.body
          console.log("info.body = "+info.body)
          grabImagesInHTMLString(info)
          if info.imageArray.length > 0
            showDebug&&console.log('    Got image')
            previousIsImage = true
            #if toBeInsertedText and toBeInsertedText isnt ''
            #  resortedArticle.push {type:'text',text:toBeInsertedText}
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
            #if toBeInsertedText and toBeInsertedText isnt ''
            #  resortedArticle.push {type:'text',text:toBeInsertedText}
            toBeInsertedText = ''
            for imageUrl in info.bgArray
              if imageUrl.startsWith('http://') or imageUrl.startsWith('https://')
                showDebug&&console.log('    save background imageUrl ' + imageUrl)
                sortedImages++
                resortedArticle.push {type:'image',imageUrl:imageUrl}
                data.imageArray.push imageUrl
        if text and text isnt ''
          previousIsImage = false
          showDebug&&console.log '    Got text in this element('+toBeInsertedText.length+') '+text
          showDebug&&console.log 'Text  ['+text+'] color is '+nodeColor+' nodeBackgroundColor is '+nodeBackgroundColor
          outputParagraphs = getOutputParagraphs(text.trim())
          if outputParagraphs.length > 0
            console.log("    outputParagraphs.length = "+outputParagraphs.length);
            for i in [0..outputParagraphs.length-1]
              if i is outputParagraphs.length-1
                #if styleAlign is undefined
                #  resortedArticle.push {type:'text',text:outputParagraphs[i]}
                #else
                #  resortedArticle.push {type:'text',text:outputParagraphs[i],layout:{align:styleAlign}}
                appendParagraph(resortedArticle, outputParagraphs[i], styleAlign)
              else
                #toBeInsertedStyleAlign = ''
                #resortedArticle.push {type:'text',text:outputParagraphs[i]}
                appendParagraph(resortedArticle, outputParagraphs[i], undefined)
      #Added by Frank
      outputParagraphs = paragraphArray
      if outputParagraphs.length > 0
        for i in [0..outputParagraphs.length-1]
          appendParagraph(resortedArticle, outputParagraphs[i], undefined)
          #resortedArticle.push {type:'text',text:outputParagraphs[i]}
      if sortedImages < 1
        console.log('no image ?')
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
      data.resortedArticle = resortedArticle
      showDebug&&console.log('Resorted Article is ' + JSON.stringify(data.resortedArticle))
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
      _html2data2(url, data, callback)
  @_getContentListsFromUrl_test = (url, callback)->
    headers = {
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
      'Content-Type': 'text/html; charset=utf-8'
      'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 8_0 like Mac OS X) AppleWebKit/600.1.3 (KHTML, like Gecko) Version/8.0 Mobile/12A4345d Safari/600.1.4'
    }
    Meteor.call 'http_get', url , headers, (error, result)->
      if(error)
        console.log(error)
      else
        returnJson = {}
        html = document.createElement('html')
        html.innerHTML = result.content
        
        if(html.getElementsByTagName('title').length > 0)
          returnJson["title"] = html.getElementsByTagName('title')[0].innerText
        if(html.getElementsByTagName('body').length > 0)
          returnJson["body"] = html.getElementsByTagName('body')[0].innerHTML
          returnJson["bodyLength"] = returnJson["body"].length
        showDebug && console.log(returnJson)
#        treeWalker = document.createTreeWalker(
#          html, NodeFilter.SHOW_TEXT
#          {
#            acceptNode : (node)->
#              console.log(node)
#              return NodeFilter.FILTER_REJECT
#          }
#          false
#        )
        _html2data2(url, returnJson, callback)
