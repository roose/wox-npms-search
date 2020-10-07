import os, strutils, httpclient, json, browsers, cgi, future
import "../../code/nim-wox/src/wox"

proc parsePackage(n: JsonNode): tuple[title, desc, url: string] =
  let
    p = n["package"]
    name = p["name"].getStr
    version = p["version"].getStr
    username = p["publisher"]["username"].getStr
    links = p["links"]
  var
    desc, url, flags = ""

  if n.hasKey("flags"):
    var flagsKeys: seq[string]
    for key in n["flags"].pairs:
      flagsKeys.add(key.key)
    flags = " [" & join(flagsKeys, ", ") & "]"

  if links.hasKey("repository"):
    url = links["repository"].getStr
  else:
    url = links["npm"].getStr

  if p.hasKey("description"):
    desc =join(p["description"].getStr.split(), " ")

  let
    # desc =join(p["description"].getStr.split(), " ")
    title = name & " v" & version & " by " & username & flags

  return (title, desc, url)

proc query(wp: Wox, params: varargs[string]) =
  let
    query = params[0].strip
    ico   = "Images\\npms.png"
    url   = "https://api.npms.io/v2/search?q="
    params = encodeUrl(query)

  if query == "":
    quit(0)

  if isCacheOld(params, 1*24*60*60):
    let
      client = newHttpClient()
      content = client.getContent(url & params)
      data    = parseJson(content)
    wp.saveCache(params, data)

  let packages = wp.loadCache(params)
  for package in packages["results"]:
    let (title, desc, url) = parsePackage(package)
    wp.add(title, desc, ico, "openUrl", url, false)

  if wp.data.result.len == 0:
    wp.add("No Results", "", ico, "", "", true)

  echo wp.results()

proc openUrl(wp: Wox, params: varargs[string]) =
  let url = params[0].strip
  openDefaultBrowser(url)

when isMainModule:
  var wp = newWox()
  wp.register("query", query)
  wp.register("openUrl", openUrl)
  wp.run()
