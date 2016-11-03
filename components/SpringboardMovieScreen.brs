' ** 
' ** Copyright Vlad Troyanker 2016. All Rights Reserved. ***
' ** See attached LICENSE file included in this package for details.'
' ** 
sub init()
  print "[sb.init]"
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

sub startvideoplayback()
  print "[sb.start.play]",m.top.content
  content = createObject("roSGNode","ContentNode")

  if m.top.content.doesexist("video_1080p")
    content.url          = m.top.content.video_1080p
  else if m.top.content.doesexist("video_720p")
    content.url          = m.top.content.video_720p
  else
    content.url          = m.top.content.video
  endif
  content.streamformat = m.top.content.videotype
  content.title        = m.top.content.fullSeriesName

  m.video.content = content
  m.video.control = "play"
  m.screen.visible=false
  m.video.visible=true
  m.video.setFocus(true)
end sub

sub onContentChange()
  print "[sb.on.cont.change]",m.top.content
  m.poster.uri    =m.top.content.image
  m.desctext.text =m.top.content.description
  m.desctitle.text=m.top.content.fullSeriesName
  m.rating.text = "Rating: "+ m.top.content.average_rating.ToStr()
  if m.top.content.doesexist("video_1080p") OR  m.top.content.doesexist("video_720p")
    m.rating.text += "  |  HD"
  endif
  m.screen.visible=true
  m.menu.setFocus(true)
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  print "[sb.onkey]", key, "press=";press
  handled = false
  if press
      if key = "back" 
        if m.video.state="playing" OR m.video.state="buffering"
          m.video.control="stop"
        else
          m.screen.visible = false 'return to Homescreen '
          m.top.state="done"
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
  print "[sb.on.load]", m.poster.loadStatus
end sub

sub onMenuAction()
  print "[sb.on.menu]", m.menu.itemSelected
  if m.menu.itemSelected = 0 OR m.menu.itemSelected = 1 then
    startvideoplayback()
  end if
end sub

sub onVideoStateChanged()
  print "[sb.vid.state]", m.video.state
  if m.video.state="stopped" OR m.video.state="finished" OR m.video.state="error"
    m.screen.visible = true
    m.video.visible = false
    m.menu.setFocus(true)
  end if
end sub
