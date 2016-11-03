' ** 
' ** Copyright Vlad Troyanker 2016. All Rights Reserved. ***
' ** See attached LICENSE file included in this package for details.'
' ** 

sub init()
    m.title             = m.top.findNode("title")
    m.text              = m.top.findNode("description")
end Sub

sub onContentChange()
	data = m.top.content
	print "[co.on.change]"
	m.title.text = data.title
	m.text.text  = data.description
end sub