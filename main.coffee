tough = require 'tough-cookie'
request = require 'request'
read = require 'readline-sync'
phantom = require 'phantom'

url = 'https://chalk.uchicago.edu/webapps/login/'
jar = request.jar()

if process.argv.length < 5
  console.log "Usage: #{process.argv[1].split('/').pop()} <username> <depth> <chalk URL> <selector?>"
  process.exit 1

makeParams = (user, pass) ->
    user_id: user,
    password: pass,
    login: "Login",
    action: "login",
    new_loc: ""

mergeCookies = (cookies, ph) ->
    console.log "Got ph #{ph}"
    parseCookie = (cookie) ->
        console.log "Parsing #{cookie} for ph #{ph}"
        new ->
            @[if k == "key" then "name" else k] = v for own k, v of cookie
            @
    # ph.set("cookies", parseCookie c for c in cookies)


printProps = (obj) ->
    console.log "Props of #{obj}"
    for k, v of obj
        console.log "Key: #{k}, value: #{v}"

# user = read.question "Username? "
user = process.argv[2]
maxDepth = process.argv[3]
toScrape = process.argv[4]
# NB: grades are under #grades_wrapper
selector = if process.argv.length == 6 then "#{process.argv[5]} " else ""

class PageFilters
    constructor: (@selector, @searchRe) ->

password = read.question("Password? ", noEchoBack: true)

request.post(
	url: url,
	form: makeParams(user, password),
	jar: jar,
, (error, response, body) ->
    console.log "Jar: #{jar.getCookieString url}"
    # parsedCookies = (parseCookie c for c in (jar.getCookies url))
    if error?
        console.log "Something went wrong. Error: #{error}"
    else
        crawl = (url, depth, selector="") ->
            phantom.create (ph) ->
                addCookie = (cookie) ->
                    console.log "Parsing #{cookie} for ph #{ph}"
                    ph.addCookie (new ->
                        @[if k == "key" then "name" else k] = v for own k, v of cookie
                        @), (status) -> console.log "Added? #{status}"
                addCookie c for c in jar.getCookies url
                ph.get "cookies", (cookies) -> console.log "Cookies set: #{cookies}"
                ph.createPage (page) ->
                    console.log "Crawling #{url}, depth = #{depth}"
                    if depth >= maxDepth
                        ph.exit()
                    page.open url, (status) ->
                        console.log "Opened #{url}. Status: #{status}"
                        if status == "fail"
                            ph.exit()
                        page.render "pictures/#{url}.png"
                        page.getContent (res) -> console.log "Content: #{res}"
                        docCallback = (selector) -> el.href for el in document.querySelectorAll "#{selector}a"
                        resCallback = (result) ->
                            console.log "Called with selector #{selector}, qs = #{selector}a"
                            console.log "Got children: #{result}"
                            crawl child, depth + 1 for child in result when /https/.test child
                            ph.exit()
                        page.evaluate docCallback, resCallback, selector
        crawl toScrape, 0, "#grades_wrapper "
)
