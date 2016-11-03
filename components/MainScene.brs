' ** 
' ** Copyright Vlad Troyanker 2016. All Rights Reserved. ***
' ** See attached LICENSE file included in this package for details.'
' ** 

sub init()
  print "[grid.init]"
  m.grid    = m.top.findNode("posterGrid")
  m.sb      = m.top.findNode("sbMovieScreen")
  m.sbs     = m.top.findNode("sbSeriesScreen")
  m.callout = m.top.findNode("gridCallout")
  m.alg     = m.top.findNode("posterGridScreen")

  m.content = createObject("RoSGNode","ContentNode") 'root content node'

  m.apiclient = createObject("roSGNode","FTWAPI")
  m.apiclient.observeField("onresult", "gotTopSeries")
  
  m.apiclient2 = createObject("roSGNode","FTWAPI")
  m.apiclient2.observeField("onresult","gotNewSeries")

  m.apiclient.request = {action:"top-series", count:"12"}
  m.apiclient2.request = {action:"display-series", count:"12", latest:"1"}

  m.grid.observeField("rowItemFocused", "onitemfocused")
end sub

sub focusBackHome()
  print "[grid.back.home]"
 m.sbs.unobserveField("state")
 m.sb.unobserveField("state")
 m.alg.unobserveField("state")
 showpostergrid()
end sub

sub showpostergrid()
  print "[grid.show]"
  m.grid.visible=true
  m.sb.visible=false
  m.grid.setFocus(true)
end sub

sub showmoviesb(content as Object)
  print "[grid.sb.show]", content
  m.sb.observeField("state", "focusBackHome")
  m.sb.content = content
  m.grid.visible=false
  m.callout.visible=false
  m.sb.visible=true
  m.sb.setFocus(true)
end sub

sub showseriessb(content as Object)
  print "[grid.sbs.show]", content
  m.sbs.observeField("state", "focusBackHome")
  m.sbs.content = content
  m.grid.visible=false
  m.callout.visible=false
  m.sbs.visible=true
  m.sbs.setFocus(true)
end sub

sub showcallout(content as Object)
  print "[grid.show.co]"
 
  m.callout.content = content
  m.callout.visible=true
end sub

sub showalltitlesgrid()
  m.alg.observeField("state", "focusBackHome")
  m.alg.action = "start"
  m.grid.visible=false
  m.callout.visible=false
  m.alg.visible=true
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  print "[scene.onkey]", key, "press=";press
  handled = false
  if key = "OK" AND m.grid.hasFocus() then
      sect = posterSelected()
      if sect = 0 OR sect = 1 then
          showseriessb(m.chosenItemContent.record)
     else if sect = 2
        showmoviesb(m.chosenItemContent.record)
      else if sect = 3
        if m.chosenItemContent.title="AllSeries"
          showalltitlesgrid()
        else
        endif
      else
        print "Warn:Unknown content category"
      endif
      handled = true
  end if
  
  return handled
end function

'return row index to determine category'
function posterSelected() as Integer
  m.chosenItemContent = lookupContentNode(m.grid.rowItemSelected)
  print "Poster item selected", m.chosenItemContent
  return m.grid.rowItemSelected[0]
end function


sub fetchMovies()
  m.apiclient.unobserveField("onresult")
  m.apiclient.observeField("onresult","gotMovies")
  m.apiclient.request = {action:"display-movies", count:"25"}
end sub

sub fetchContentDetails(content as Object)
  m.apiclient2.unobserveField("onresult")
  m.apiclient2.observeField("onresult","gotEpisodeDetails")
  m.apiclient2.request = {action:"display-single-series", id:content.url}
end sub

function lookupContentNode(index as Object) as Object
  row = index[0]
  item= index[1]
  return m.content.getChild(row).getChild(item)
end function

function addAllTitlesRow(parent as Object)
  parent.title="ALL TITLES"
  poster = parent.createChild("ContentNode")
  poster.hdgridposterurl = "pkg:/images/allseries-poster.png"
  poster.sdgridposterurl = "pkg:/images/allseries-poster.png"
  poster.title = "AllSeries"
  poster = parent.createChild("ContentNode")
  poster.hdgridposterurl = "pkg:/images/allmovies-poster.png"
  poster.sdgridposterurl = "pkg:/images/allmovies-poster.png"
  poster.title = "AllMovies"
end function


'**'
'** Data callbacks'
'**'
sub gotTopSeries(rsp as Object)
  o = rsp.getData()

  print "[grid.got.top]", type(rsp), rsp.getNode(), rsp.getField(), type(rsp.getData())

  sectionContent = m.content.createChild("ContentNode")
  sectionContent.TITLE = "TRENDING"

  for each item in o.results
    poster = createObject("roSGNode","ContentNode")
    poster.hdgridposterurl = item.image
    poster.sdgridposterurl = item.image
      
    poster.title = item.fullSeriesName
    poster.description = item.description
    poster.url = item.id
    ok = poster.addField("record", "assocarray", false)
    poster.record = item

    sectionContent.appendChild(poster)
  end for

  m.grid.content = m.content
  showpostergrid()
  fetchMovies()
end sub

sub gotNewSeries(rsp as Object)
  o = rsp.getData()

  print "[grid.got.new]", type(rsp), rsp.getNode(), rsp.getField(), type(rsp.getData())
  sectionContent = m.content.createChild("ContentNode")
  sectionContent.TITLE = "NEW EPISODES"

  for each item in o.results
    poster = createObject("roSGNode","ContentNode")
    poster.hdgridposterurl = item.image
    poster.sdgridposterurl = item.image

    poster.title = item.fullSeriesName
    poster.description = item.description
    poster.url = item.id
    ok = poster.addField("record", "assocarray", false)
    poster.record = item
    
    sectionContent.appendChild(poster)
  end for

  m.grid.content = m.content
  showpostergrid()
end sub

sub gotMovies(rsp as Object)
  o = rsp.getData()
  if o.status <> "200"
    print "[grid.got.mv]", "Server error: "; o.status
    return
  else
    print "[grid.got.mv]"
  endif
  data = o.results
  sectionContent = m.content.createChild("ContentNode")
  sectionContent.TITLE = "MOVIES"

  for each item in data
    poster = sectionContent.createChild("ContentNode")
    poster.hdgridposterurl = item.image
    poster.sdgridposterurl = item.image
    poster.contenttype = "movie"
    poster.title = item.fullSeriesName
    poster.url   = item.sid 
    ok = poster.addField("record", "assocarray", false)
    poster.record = item
  end for

  m.grid.content = m.content
  addAllTitlesRow(m.content.createChild("ContentNode"))
end sub

sub gotEpisodeDetails(rsp as Object)
  o = rsp.getData()
  if o.status <> "200"
    print "[got.ep.det]", "Server error: "; o.status
    return
  endif
  content = createObject("roSGNode","ContentNode")
  data = o.results
  content.url          = data.video
  content.streamformat = data.videotype
  content.title        = data.fullSeriesName
  content.starrating   = data.reviews_average_stars * 20
  content.rating       = "PG-13"
  content.categories   = data.category
  content.description  = data.description
  content.ishd         = false
  content.watched      = false

  showmoviesb(content)
end sub

sub onitemfocused()
  print "[grid.focus]", m.grid.rowItemFocused, m.grid.visible
  content = lookupContentNode(m.grid.rowItemFocused)
  if content.title <> ""
    m.callout.content = content
    m.callout.visible=true
  end if
end sub
