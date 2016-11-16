' ** 
' ** Copyright (C) Reign Software 2016. All Rights Reserved. ***
' ** See attached LICENSE file included in this package for details.'
' ** 

sub init()
	print "[login.init]"
	m.button  = m.top.findNode("newcode")
	m.code    = m.top.findNode("code")
    m.timer   = m.top.findNode("validateTimer")
    m.state   = "idle"
    m.reg     = Registry()

	m.button.observeField("buttonSelected", "newCode")
    m.top.observeField("control", "run")
end sub

sub run(cmd as Object)
    print "[login.run]"
    m.apiclient = createObject("roSGNode","FTWAPI")
    m.apiclient.observeField("onresult", "gotCode")
    m.apiclient.request = {action:"generate-device-key"}
    m.state="gettingCode"
end sub

sub newCode(cmd as Object)
  print "[login.new.code]"
    m.apiclient.unobserveField("onresult")
    m.apiclient.observeField("onresult", "gotCode")
	m.apiclient.request = {action:"generate-device-key"}
    m.state="gettingCode"
end sub

sub validate(key as String)
	m.apiclient.unobserveField("onresult")
	m.apiclient.observeField("onresult", "gotValidate")
	m.apiclient.request = {action:"validate-device", key: key}
    m.state="validatingCode"
end sub

sub schedValidate()
    print "[login.new.validate]"
    if m.state <> "validatingCode"
        m.timer.observeField("fire", "doValidate")
        m.timer.control = "start"
    end if
end sub

sub doValidate()
    validate(m.code.text)
end sub

sub gotCode(rsp as Object)
	o = rsp.getData()
	print "[login.got.code]", o
	if o.status="200"
		m.state="gotCode"
        m.code.text=o.key
        schedValidate()
	else
		m.state="gettingCodeFailed"
        m.code.text="Server Error: "+o.status
	end if
end sub

sub gotValidate(rsp as Object)
  o = rsp.getData()
  print "[login.got.validate]", o
  if o.status = "200"
    m.timer.control="stop"
    m.reg.write("usertoken", o.message)   
    m.reg.sync()
    'Necessary to eliminate a race codition of exiting before writing through
    'to registry is complete
    m.reg.node.observeField("onread", "exitScreen")
    m.reg.read("usertoken")
  end if
end sub

sub exitScreen(res as Object)
    print "[login.exit]", res.getData()
    m.top.state="done"
    m.top.visible=false
end sub