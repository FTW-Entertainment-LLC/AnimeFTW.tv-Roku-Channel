' ** 
' ** Copyright Vlad Troyanker 2016. All Rights Reserved. ***
' ** See attached LICENSE file included in this package for details.'
' ** 


sub init()
  print "[api.init]"

  m.apihost="https://www.animeftw.tv/api/v2/?action="

  m.static_params = {
				devkey: "e9r9-0cA8-7515-82q3",
				token:  "873b9231-1ef1-4c03-a50f-847cfe2e6fc0"
				}

  m.port = createObject("roMessagePort")

  m.xfer = createObject("roUrlTransfer")
  m.xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
  m.xfer.InitClientCertificates()
  m.xfer.setPort(m.port)

  m.top.observeField("request", m.port)

  ' setting the task thread function
  m.top.functionName = "task"
  m.top.control = "RUN"
end sub

function buildUrl(action as String, params={} as Object) as String
	url=m.apihost+action
	params.Append(m.static_params)

	for each k in params
		qs = Substitute("&{0}={1}",k, params[k])
		url.AppendString(qs, qs.len())
	end for
	return url
end function


function get(uri as String, headers=Invalid as Dynamic) as Boolean
  m.xfer.setUrl(uri)
  ' Add headers to the request
  print "[api.get]", uri
  if headers <> Invalid then
    for each hdr in headers
      m.xfer.AddHeader(hdr, headers[hdr])
    end for
  end if
  m.xfer.setRequest("GET")
  return m.xfer.AsyncGetToString()
end function


function post(uri as String, body as String, headers as Dynamic) as Boolean
  m.xfer.setUrl(uri)
  print "[api.post]", uri
  if headers <> Invalid then
    for each hdr in headers
      m.xfer.AddHeader(hdr, headers[hdr])
    end for
  end if
  m.xfer.setRequest("POST")
  return m.xfer.AsyncPostFromString(body)
end function

function head(uri as String, headers={} as Object) as Boolean
  m.xfer.setUrl(uri)
  ' Add headers to the request
  for each hdr in headers
    m.xfer.AddHeader(header, headers[header])
  end for
  return m.xfer.AsyncHead()
end function

function cancel() as Boolean
  print "[api.cancel]"
  return m.xfer.AsyncCancel()
end function


sub task() 'Task function
  print "[api.task]"

  while true
    msg = wait(0, m.port)
    mt = type(msg)
    print "[api.task.msg]", mt
    if mt = "roSGNodeEvent"
        req = msg.GetData()
       	action = req.action
        req.Delete("action")
 	      get( buildUrl(action, req) )
     else if mt="roUrlEvent" ' If a request was made
        processResponse(msg)
    else ' Handle unexpected cases
	     print "[hc.task.msg] Error: unrecognized event type '"; mt ; "'"
       return
    end if
  end while
end sub



'Received a response
sub processResponse(msg as Object)
  print "[api.proc.resp]", "request=", msg.GetSourceIdentity(), "HTTP=", msg.GetResponseCode()

  if msg.GetResponseCode() <= 200 AND msg.GetResponseCode() < 300
    m.top.onresult = parseJson(msg.GetString())
    'print "[hc.proc.resp]", m.top.result
  else
    print "Error: status: " + (msg.GetResponseCode()).toStr()
  end if

  m.top.responseheaders = msg.GetResponseHeaders()
end sub

function parse_topseries(reply as String) as Object
	o = parseJson(reply)
	return o.results
end function
