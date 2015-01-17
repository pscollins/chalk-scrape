tough = require 'tough-cookie'
request = require 'request'
read = require 'readline-sync'
phantom = require 'phantom'

url = 'https://chalk.uchicago.edu/webapps/login/'
jar = request.jar()

if process.argv.length < 5
  console.log "Usage: #{process.argv[1].split('/').pop()} <username> <depth> <chalk URL>"
  process.exit 1

makeParams = (user, pass) ->
    user_id: user,
    password: pass,
    login: "Login",
    action: "login",
    new_loc: ""

mergeCookies = (cookies, ph) ->
    parseCookie = (cookie) ->
        console.log "Parsing #{cookie}"
        new ->
            @[if k == "key" then "name" else k] = v for own k, v of cookie
            @

    ph.set("cookies", parseCookie c for c in cookies)




# user = read.question "Username? "
user = process.argv[2]
maxDepth = process.argv[3]
toScrape = process.argv[4]

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
        phantom.create (ph) ->
            ph.createPage (page) ->
                crawl = (url, depth) ->
                    console.log "Crawling #{url}, depth = #{depth}"
                    if depth >= maxDepth
                        return
                    page.open url, (status) ->
                        console.log "Opened #{url}. Status: #{status}"
                        page.render "pictures/#{url}.png"
                        page.evaluate (-> el.href for el in document.querySelectorAll 'a'), (result) ->
                                console.log "Got children: #{result}"
                                crawl child, depth + 1 for child in result
                crawl toScrape, 0
)
