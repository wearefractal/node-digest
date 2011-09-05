digest = require '../lib/main.coffee'
config = digest.config
  
server = digest.createServer 'admin', 'password', (req, res) ->
  res.writeHead 200, 'Content-Type': 'text/plain'
  res.end 'Hello world! You are authenticated!'
    
server.listen 8080
  
console.log 'Server running!'
