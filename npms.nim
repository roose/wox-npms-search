import os, strutils, httpclient, json, browsers, cgi, future
import wox

proc parsePackage(n: JsonNode): tuple[title, desc, url: string] =
  let
    p = n["package"]
    name = p["name"].getStr
    version = p["version"].getStr
    username = p["publisher"]["username"].getStr
    links = p["links"]
  var
    url, flags = ""

  if n.hasKey("flags"):
    flags = " [" & join(lc[ y.key | ( y <- n["flags"].pairs ), string ], ", ") & "]"

  if links.hasKey("repository"):
    url = links["repository"].getStr
  else:
    url = links["npm"].getStr

  let
    desc =join(p["description"].getStr.split(), " ")
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
      content = getContent(url & params)
      data    = parseJson(content)
    wp.saveCache(params, data)

  let packages = wp.loadCache(params)
  for package in packages["results"]:
    # let p = package["package"]
    # var flags = ""
    # if package.hasKey("flags"):
      # flags = " ["& join(lc[ y.key | ( y <- package["flags"].pairs ), string ], ", ") & "]"

    # if p["description"].getStr.contains("\n")

    # let
      # name = p["name"].getStr
      # version = p["version"].getStr
      # username = p["publisher"]["username"].getStr
      # links = p["links"]
      # title = name & " v" & version & " by " & username & flags
      # desc  = if p["description"].getStr.contains("\n"): join(p["description"].getStr.split(), " ") else: p["description"].getStr
      # url   = if links.hasKey("repository"): links["repository"].getStr else: links["npm"].getStr
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
