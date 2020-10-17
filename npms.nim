import os, strutils, httpclient, json, browsers, cgi, cliptomania
import wox

type
  Package = object
    name: string
    title: string
    desc: string
    github: string
    npm: string

const
  ico   = "Images\\npms.png"
  url   = "https://api.npms.io/v2/search?q="
  icons = @["copy.png", "npm.png", "npms.png"]

proc getWoxDirs(): seq[string] =
  var dirs: seq[string]
  for kind, path in walkDir(joinPath([getEnv("LOCALAPPDATA"), "Wox"])):
    if kind == pcDir and lastPathPart(path).startsWith("app"):
      dirs.add(path)
  return dirs

proc copyIcons(paths: seq[string]) =
  for icon in icons:
    for dir in getWoxDirs():
      let imageDir = joinPath([dir, "Images"])
      if dirExists(imageDir):
        copyFile(joinPath([getAppDir(), "Images", icon]), joinPath([imageDir, icon]))

proc existsWoxIcon(icon: string): bool =
  for dir in getWoxDirs():
    if fileExists(joinPath([dir, "Images", icon])):
      return true

proc parsePackage(n: JsonNode): Package =
  let
    p = n["package"]
    name = p["name"].getStr
    version = p["version"].getStr
    username = p["publisher"]["username"].getStr
    links = p["links"]
  var
    desc, url, npm, flags = ""

  if n.hasKey("flags"):
    var flagsKeys: seq[string]
    for key in n["flags"].pairs:
      flagsKeys.add(key.key)
    flags = " [" & join(flagsKeys, ", ") & "]"

  if links.hasKey("repository"):
    url = links["repository"].getStr
  else:
    url = links["npm"].getStr

  npm = links["npm"].getStr

  if p.hasKey("description"):
    desc =join(p["description"].getStr.split(), " ")

  let
    # desc =join(p["description"].getStr.split(), " ")
    title = name & " v" & version & " by " & username & flags

  return Package(name: name, title: title, desc: desc, github: url, npm: npm)

proc query(wp: Wox, params: varargs[string]) =
  let
    query = params[0].strip
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
    let package = parsePackage(package)
    wp.add(package.title, package.desc, ico, package.name & " " & package.npm, "openUrl", package.github, false)

  if wp.data.result.len == 0:
    wp.add("No Results", "", ico, "", "", "", true)

  echo wp.results()

proc contextmenu(wp: Wox, params: varargs[string]) =
  let
    params = params[0].split(" ")
    cmd = "npm install " & params[0].strip
    link = params[1].strip
  wp.add("Open npm page", "", "Images/npm.png", "", "openUrl", link, false)
  wp.add("Copy install command", "", "Images/copy.png", "", "copyCmd", cmd, false)
  echo wp.results()

proc openUrl(wp: Wox, params: varargs[string]) =
  let url = params[0].strip
  openDefaultBrowser(url)

proc copyCmd(wp: Wox, params: varargs[string]) =
  let cmd = params[0].strip
  clip.set_text(cmd)

when isMainModule:
  if not existsWoxIcon("npms.png"):
    copyIcons(icons)

  var wp = newWox()
  wp.register("query", query)
  wp.register("contextmenu", contextmenu)
  wp.register("openUrl", openUrl)
  wp.register("copyCmd", copyCmd)
  wp.run()
