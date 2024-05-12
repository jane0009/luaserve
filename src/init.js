const fs = require("fs");

function doInit() {
  if (!fs.existsSync(".ls")) {
    fs.mkdirSync(".ls");
  }
  if (!fs.existsSync(".ls/src")) {
    fs.mkdirSync(".ls/src");
  }

  if (!fs.existsSync("luasrc")) {
    const example = "print(\"example\")";
    fs.mkdirSync("luasrc");
    fs.writeFileSync("luasrc/example.lua", example);
  }
}

module.exports = doInit;