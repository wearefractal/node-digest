digest = require '../lib/main.coffee'
  
server = digest.createServer 'username', 'password', (req, res) ->
  res.writeHead 200, 'Content-Type': 'text/plain'
  res.end 'Hello world! You are authenticated!'
server.listen 8080
  
console.log 'Server running!'
