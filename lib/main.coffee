require('coffee-script');
http = require 'http'
config = require './config'
md5 = require 'MD5'

nonces = {}


parseHeader = (header) ->
  # Check for inconsistencies
  if !header?
    return false
  unless header.toLowerCase().indexOf(String('digest').toLowerCase()) is 0
    return false

  out = {}
  # Remove 'Digest ' from the string
  header = header.toLowerCase().replace 'digest ', ''
  chunks = header.split ', '

  for piece in chunks
    val = piece.trim().split '='
    if val.length < 2
      return false
    val[1] = val[1].replace('"', '') for x in val[1]
    out[val[0]] = val[1]
  return out

authenticate = (request, header, username, password) ->
  authinfo = parseHeader header

  # Check for inconsistencies
  if !authinfo
    return false
  unless authinfo.nonce of nonces
    return false
  if authinfo.algorithm is 'MD5-sess'
    return false
  if authinfo.qop is 'auth-int'
    return false
  if authinfo.username isnt username
    return false

  userAuth = authinfo.username + ':' + config.realm + ':' + password
  methodAuth = request.method + ':' + authinfo.uri

  if !authinfo.qop?
    digest = md5 [md5(userAuth), authinfo.nonce, md5(methodAuth)].join(':')
  else
    if authinfo.nc <= nonces[authinfo.nonce].count
      return false
    nonces[authinfo.nonce].count = authinfo.nc
    digest = md5 [md5(userAuth), authinfo.nonce, authinfo.nc, authinfo.cnonce, authinfo.qop, md5(methodAuth)].join(':')
  return digest is authinfo.response

digest = (request, response, username, password, callback) ->
  authenticated = false

  if request.headers.authorization?
    header = request.headers.authorization

  if authenticate request, header, username, password
    callback request, response
  else
    nonce = md5 new Date().getTime() + config.key
    nonces[nonce] = count: 0
    setTimeout nonces.remove, config.timeout, nonce
    opaque = md5 config.opaque
    response.writeHead 401, {'WWW-Authenticate': 'Digest realm="' + config.realm + '", qop="auth", nonce="' + nonce + '", opaque="' + opaque + '"'}
    response.end '401 Unauthorized'

exports.createServer = (username, password, callback) ->
  @server = http.createServer (request, response) ->
    digest request, response, username, password, callback
  return @server

