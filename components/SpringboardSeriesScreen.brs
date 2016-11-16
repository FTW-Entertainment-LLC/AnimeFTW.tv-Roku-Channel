' ** 
' ** Copyright (C) Reign Software 2016. All Rights Reserved. ***
' ** See attached LICENSE file included in this package for details.'
' ** 

sub init()
  print "[sbs.init]"
  m.screen = m.top.findNode("sbElements")
  m.menu   = m.top.findNode("menuList")
  m.poster = m.top.findNode("moviePoster")
  m.desctext = m.top.findNode("DescText")
  m.desctitle= m.top.findNode("DescTitle")
  m.rating = m.top.findNode("rating")

  m.poster.observeField("loadStatus", "onPosterLoading")
  m.menu.observeField("itemSelected", "onMenuAction")
 
  m.video   = m.top.findNode("videoNode")
  m.video.observeField("state", "onVideoStateChanged")
end sub

sub startvideoplayback(content as Object)
  print "[sbs.start.play]", content

  m.video.content = content
  m.video.control = "play"
  m.screen.visible=false
  m.video.visible=true
  m.video.setFocus(true)
end sub

sub fetchEpisodes(data as Object)
  if NOT m.doesexist("apiclient")
    m.apiclient = createObject("roSGNode","FTWAPI")
    m.apiclient.observeField("onresult","gotEpisodes")
  endif
  m.apiclient.request = {action:"display-episodes", id:data.id, count:"20"}
end sub

sub gotEpisodes(rsp as Object)
  print "[sbs.got.episodes]"
  o = rsp.getData()

  if o.status <> "200"
    print "[sbs.got.epi]", "Server error: "; o.status
    return
  endif
  m.menu.content.removeChildIndex(0) 'remove loading... node'
  count=1
  for each item in o.results
    'print item
    content = m.menu.content.createChild("ContentNode")
    content.url          = item.video
    content.streamformat = item.videotype
    content.title        = substitute("Ep{0}: {1}",count.toStr(),item.epname)
    content.categories   = item.category
    count++
  end for
  m.menu.setFocus(true)
end sub

sub resetmenu(rootcontent as Object)
  rootcontent.removeChildrenIndex(rootcontent.getChildCount(), 0)
  content=rootcontent.createChild("ContentNode")
  content.title="Loading..."
end sub

sub onContentChange()
  data = m.top.content
  print "[sbs.on.cont.change]","count=";data.count()
  m.poster.uri    =data.image
  m.desctext.text =data.description
  m.desctitle.text=data.fullSeriesName
  m.rating.text = "Rating: "+ data.rating.ToStr()
  m.screen.visible=true

  resetmenu(m.menu.content)
  fetchEpisodes(data)
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  print "[sbs.onkey]", key, "press=";press
  handled = false
  if press
      if key = "back" 
        if m.video.state="playing" OR m.video.state="buffering"
          m.video.control="stop"
        else
          m.screen.visible = false 'return to Homescreen '
          m.top.state="done"
          m.apiclient.cancel = {} 'try cancelling an outstanding request before quitting'
        endif
        handled = true
      elseif key="up" OR key="down"
        handled=true 'simply consume'
      endif
  else
    handled=true 'consume release'
  endif
  return handled
end function

sub onPosterLoading()
  print "[sbs.on.load]", m.poster.loadStatus
end sub

sub onMenuAction()
  print "[sbs.on.menu]"
  index = m.menu.itemSelected
  startvideoplayback(m.menu.content.getChild(index))
end sub

sub onVideoStateChanged()
  print "[sbs.vid.state]", m.video.state
  if m.video.state="stopped" OR m.video.state="finished" OR m.video.state="error"
    m.screen.visible = true
    m.video.visible = false
    m.menu.setFocus(true)
  end if
end sub
