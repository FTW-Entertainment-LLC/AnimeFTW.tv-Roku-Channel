' ** 
' ** Copyright (C) Reign Software 2016. All Rights Reserved. ***
' ** See attached LICENSE file included in this package for details.'
' ** 

'Singleton: can be used in RSG code'

function Registry() as Object

  if m.global.regnode = Invalid 'this is a Singleton'
      m.global.AddField("regnode", "node", false)
      m.global.regnode = CreateObject("roSGNode", "RegistryTask") 'caller to setup callback(s) for onread'  
      print "[registry.singleton]", m.global.regnode
  end if

  if m.this = Invalid
    m.this = {
      node : m.global.regnode 'sinlge node shared across all clients'
      read : _read,
      write: _write,
      sync : _sync,
      dirty: _dirty,
    }
  end if

  return m.this
end function


'Blocking Legacy impl can only be used in Task code only'

function RegistrySync() as Object

  if m.this = Invalid
    m.this = {
      read : _read_sync,
      write: _write_sync
      sync : _sync_sync,
      dirty: sub() as Boolean : return false : end sub
    }
  end if

  return m.this
end function

'**  implementation **'
function _read(key as String, defValue="" as String, section="default" as String) as Void
  m.node.read = { key: key, def: defValue }
end function

function _write(key as String, value as Dynamic, section="default" as String) as Void
  m.node.write = { key: key, value: value }
end function

function _sync() as Void
  m.node.sync = 1 
end function

function _dirty() as Boolean
  return false
end function


function _read_sync(key as String, defValue="" as String, section="default" as String) as String
  sect = CreateObject("roRegistrySection", section)
  v = sect.Read(key)
  if v = "" AND defValue <> ""
    return defValue
  else
    return v
  end if
end function

function _write_sync(key as String, value as Dynamic, section="default" as String) as Void
  sect = CreateObject("roRegistrySection", section)
  sect.Write(key, to_string(value))
end function

sub _sync_sync() 
  CreateObject("roRegistry").Flush()
end sub

'Coerce to String type'
function to_string(v as Dynamic) as String
  if GetInterface(v, "ifToStr") <> Invalid 
    return v.ToStr()
  else
    return type(v)
  end if
end function