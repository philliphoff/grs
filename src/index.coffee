request = require 'request'
_ = require 'highland'
JSONStream = require 'JSONStream'

request = request.defaults
    headers:
        accept: 'application/vnd.github.manifold-preview'
        'user-agent': 'grs-releases/' + require('../package.json').version

module.exports = (options)->

    ###*
     * options.repo
     * options.tag
     * options.name
    ###

    baseRequest = request.defaults(options.requestOptions)

    for option in ['repo', 'tag', 'name']
        if !options || !options[option]
            throw new Error("Miss option #{option}")
    token = if options.token then "?access_token=" + options.token else ""
    stream = _(baseRequest("https://api.github.com/repos/#{options.repo}/releases#{token}")
    .pipe(JSONStream.parse('*')))
    .map (res)->
        if typeof res is 'string'
            stream.emit 'error', new Error("#{options.repo} #{options.tag} #{options.name} " + res)
        else res
    .where ({tag_name: options.tag})
    .map (release)->
        return release.assets
    .flatten()
    .find (asset)->
        return asset.name  is options.name
    .flatMap (asset)->
        uri = "https://github.com/#{options.repo}/releases/download/#{options.tag}/#{asset.name}"
        stream.emit 'size', asset.size
        return _(baseRequest(uri))
