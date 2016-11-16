' ** 
' ** Copyright (C) Reign Software 2016. All Rights Reserved. ***
' ** See attached LICENSE file included in this package for details.'
' ** 

sub init()
  print "[pgs.init]"
  m.grid      = m.top.findNode("posterGrid")
  m.content   = m.top.findNode("rootcontent")
  m.progbar   = m.top.findNode("progressbar")
  m.sbs       = m.top.findNode("sbSeriesScreen")

  m.total  = 0        'total content items'
  m.first  = 0        'index of first loaded item within total'
  m.last   = 0        'index of last loaded item within total'
  m.blocksize = 60    'max items downloaded at once'
  m.lastrow = 0       'store last focused to row to detect pg up/down'

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

sub requestBlock(offset as Integer)
  print "[pgs.req.blk]"
  'delay creating httpClient because it needs usertoken (loginScreen)'
  m.apiclient.request = { action:"display-series", 
                          count : m.blocksize, 
                          start : offset }
  m.newfirst = offset
end sub

sub pageforward()
  print "[pgs.pg.for]"
  requestBlock(m.last+1)
end sub

sub pageback()
  print "[pgs.pg.back]"
  requestBlock(m.first-m.blocksize)
end sub

'*******************'
'**   Callbacks   **'

sub onAction()
  print "[pgs.on.action]"
  'delay creating httpClient because it needs usertoken (loginScreen)'
  m.apiclient = createObject("roSGNode","FTWAPI")
  m.apiclient.observeField("onresult", "gotSeries")
  requestBlock(0)
  showpostergrid()
end sub

sub onItemSelected()
  print "[pgs.on.sel]", m.grid.itemSelected
  content = m.content.getChild(m.grid.itemSelected)
  showseriessb(content.record)
end sub

sub onItemFocused()
  row = m.grid.itemFocused \ m.grid.numColumns 'integer division'
  if row < 0  OR row=m.lastrow 'initial or duplicate callback'
    return
  endif

  print "[pgs.on.focus]", "index=";m.grid.itemFocused, "row=";row, "lastrow=";m.lastrow

  if Abs(row - m.lastrow) > 1 AND row = 0 'wrap forward'
    if m.last < m.total
      pageforward()
    end if
  else if Abs(row - m.lastrow) > 1 AND row <> 0 'wrap backward'
    if m.first > 0
      pageback()
    end if    
  endif
  m.lastrow = row
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  print "[pgs.onkey]", key, "press=";press
  handled = false
  if press
	  if key = "back" 
	      m.grid.visible=false
        m.progbar.visible=false
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

  m.total = o.total_series.ToInt()
  m.first = m.newfirst
  m.last  = m.newfirst + o.count.ToInt() - 1
  print "[pgs.got]", m.first, m.last, m.total
  childindex = 0
  createNewNodes = (m.content.getChildCount() = 0)
  for each item in o.results
    if createNewNodes
      poster = m.content.createChild("ContentNode")
    else  'replace
      poster = m.content.getChild(childindex)
      childindex++
    end if
    populate(poster, item)
  end for
end sub

sub populate(poster as Object, item as Object)
    poster.hdgridposterurl = item.image
    poster.sdgridposterurl = item.image
      
    poster.title = item.fullSeriesName
    poster.description = item.description
    poster.url = item.id
    ok = poster.addField("record", "assocarray", false)
    poster.record = item
end sub