' ** 
' ** Copyright (C) Reign Software 2016. All Rights Reserved. ***
' ** See attached LICENSE file included in this package for details.'
' ** 


sub init()
  print "[reg.init]"

  m.sections = {} 'default section'
  m.node = m.top

  ' setting the task thread function
  m.port = createObject("roMessagePort")

  m.top.observeField("read", m.port)
  m.top.observeField("write", m.port)
  m.top.observeField("sync", m.port)
  m.reg = RegistrySync()
  m.top.functionName = "task"
  m.top.control = "RUN"
end sub


sub task() 'Task function
  print "[reg.task] keys:", CreateObject("roRegistrySection", "default").GetKeyList()

  while true
    msg = wait(0, m.port)
    mt = type(msg)
    print "[reg.task.msg]", msg.GetField(), msg.GetData()

    if mt = "roSGNodeEvent"
      data = msg.GetData()
      if msg.GetField() = "read"
          sect = section(data.lookup("section"))
          key  = data.key
          v = sect.Read(key)
          if v = Invalid then v = data.def
          m.node.onread = {key:key, value:v, section: data.lookup("section")}
      else if msg.GetField() = "write"
          sect = section(data.lookup("section"))
          key  = data.key
          sect.Write(key, to_string(data.value))
          m.dirty=true
      else if msg.GetField() = "sync"
          CreateObject("roRegistry").Flush()
          m.dirty=false
      end if
    else ' Handle unexpected cases
       print "[reg.task.msg] Error: unrecognized event type '"; mt ; "'"
       return
    end if
  end while
end sub

'returns section name defaulting properly if empty'
function section(name as Dynamic) as Object
  if name = Invalid OR len(name) = 0
    name = "default"
  end if
  if NOT m.sections.DoesExist(name)
    m.sections[name] = CreateObject("roRegistrySection", name)
  end if

  return m.sections[name]
end function
