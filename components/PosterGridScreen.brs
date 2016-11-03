 '** 
' ** Copyright Vlad Troyanker 2016. All Rights Reserved. ***
' ** See attached LICENSE file included in this package for details.'
' ** 

sub init()
  print "[pgs.init]"
  m.grid      = m.top.findNode("posterGrid")
  m.content   = m.top.findNode("rootcontent")
  m.progbar   = m.top.findNode("progressbar")
  m.sbs       = m.top.findNode("sbSeriesScreen")

  m.apiclient = createObject("roSGNode","FTWAPI")
  m.apiclient.observeField("onresult", "gotSeries")

  m.total  = Invalid
  m.loaded = 0
  m.top.observeField("action", "onAction")

  m.grid.observeField("itemSelected", "onItemSelected")
  m.grid.observeField("itemFocused", "onItemFocused")
end sub

sub focusBackHome()
  print "[pgs.back.home]"
  m.sbs.unobserveField("state")
  showpostergrid()
end sub

sub showpostergrid()
  print "[pgs.show]"
  m.grid.visible=true
  m.sbs.visible=false
  m.grid.setFocus(true)
end sub

sub showseriessb(content as Object)
  print "[pgs.sbs.show]", content
   
  m.sbs.observeField("state", "focusBackHome")
  m.sbs.content = content
  m.grid.visible=false
  m.sbs.visible=true
  m.sbs.setFocus(true)
end sub

sub onAction()
  print "[pgs.on.action]"
  m.apiclient.request = {action:"display-series", count:"100"}
  showpostergrid()
end sub

sub onItemSelected()
  print "[pgs.on.sel]", m.grid.itemSelected
  content = m.content.getChild(m.grid.itemSelected)
  showseriessb(content.record)
end sub

sub onItemFocused()
  print "[pgs.on.focus]", m.grid.itemFocused
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  print "[pgs.onkey]", key, "press=";press
  handled = false
  if press
	  if key = "back" 
	      m.grid.visible=false
	      m.top.state="done"
	      handled = true
	  end if
  else
	handled=true  'consume all release(s) that bubble up'
  endif 
  return handled
end function

sub gotSeries(rsp as Object)
  o = rsp.getData()

  if o.status <> "200"
    print "[pgs.got]", "Server error: "; o.status
    m.progbar.text=o.message
    return
  else
	m.progbar.visible=false
  endif

  m.total=o.total_series
  m.loaded=o.count
  print "[pgs.got]", m.loaded, m.total
  for each item in o.results
    poster = m.content.createChild("ContentNode")
    poster.hdgridposterurl = item.image
    poster.sdgridposterurl = item.image
      
    poster.title = item.fullSeriesName
    poster.description = item.description
    poster.url = item.id
    ok = poster.addField("record", "assocarray", false)
    poster.record = item
  end for
end sub