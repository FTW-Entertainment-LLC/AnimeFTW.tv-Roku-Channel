' ** 
' ** Copyright Vlad Troyanker 2016. All Rights Reserved. ***
' ** See attached LICENSE file included in this package for details.'
' ** 


' 1st function called when channel application starts.
sub Main(input as Dynamic)

  screen = CreateObject("roSGScreen")
  m.port = CreateObject("roMessagePort")
  screen.setMessagePort(m.port)
  m.global = screen.getGlobalNode()
  

  scene = screen.CreateScene("MainScene")
  screen.show()

  while(true)
    msg = wait(0, m.port)
    msgType = type(msg)
    print "[main.ev]", msgType
    if msgType = "roSGScreenEvent"
      if msg.isScreenClosed() then return
    end if
  end while
end sub
