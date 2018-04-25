'use strict';

const express = require('express');
const morgan = require('morgan')


// Constants
const PORT = 8080;
const HOST = '0.0.0.0';

// App
const app = express();

app.use(morgan('combined'))

app.get('/', (req, res) => {
  res.send('Hello World\n');
});

app.listen(PORT, HOST);
console.log(`Running on http://${HOST}:${PORT}`);
