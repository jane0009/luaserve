const init = require("./init");
const fs = require("fs");
const express = require("express");
const crypto = require("crypto");
const path = require("path");

const addr = "0.0.0.0";
const port = 25519;

const app = express();

const md5_secret = "lua";

let versions = {};

if (fs.existsSync(".ls/version")) {
  const file = fs.readFileSync(".ls/version");
  versions = JSON.parse(file.toString());
  console.log("load", versions);
}

app.use("/", express.static(".ls"));

function diffy(filepath) {
  filepath = filepath.replace(/\\/g, "/"); // windows fix
  console.log("diffy", filepath);
  if (!fs.existsSync(".ls/src/" + filepath)) {
    update_version(filepath);
    write_changes();
    return;
  }

  if (!fs.existsSync("luasrc/" + filepath)) {
    delete_file(filepath);
    write_changes();
    return;
  }
  const file_current = fs.readFileSync("luasrc/" + filepath);
  const file_served = fs.readFileSync(".ls/src/" + filepath);

  const md5_cur = crypto.createHmac("md5", md5_secret);
  const md5_ser = crypto.createHmac("md5", md5_secret);
  md5_cur.update(file_current);
  md5_ser.update(file_served);
  const hash_cur = md5_cur.digest("hex");
  const hash_ser = md5_ser.digest("hex");
  console.log(hash_cur, hash_ser);
  if (hash_cur != hash_ser) {
    update_version(filepath);
    write_changes();
  }
  md5_cur.end();
  md5_ser.end();
}

function update_version(filepath) {
  console.log("update", filepath);
  fs.cpSync(path.join("luasrc", filepath), path.join(".ls/src", filepath));
  const md5 = crypto.createHmac("md5", md5_secret);
  const file = fs.readFileSync(".ls/src/" + filepath);
  md5.update(file);
  const hash = md5.digest("hex");
  versions[filepath] = hash;
}

function delete_file(filepath) {
  console.log("delete", filepath);
  fs.unlinkSync(path.join(".ls/src", filepath));
  delete versions[filepath];
}

function write_changes() {
  console.log("write version");
  fs.writeFileSync(".ls/version", JSON.stringify(versions));
}

function on_file_change(parent) {
  return function (event, filename) {
    console.log(event, path.join(parent, filename));
    diffy(path.join(parent, filename));
  };
}

function serve(options) {
  app.listen(port, addr, () => {
    console.log("express started at " + addr + ":" + port);
  });
  traverse();
}

module.exports = serve;

function traverse(parentPath = "") {
  console.log("adding dir listener for " + parentPath);
  fs.watch("luasrc/" + parentPath, on_file_change(parentPath));
  const dirlist = fs.readdirSync("luasrc/" + parentPath);
  for (const file of dirlist) {
    console.log(path.join(parentPath, file));
    const stat = fs.statSync(path.join("luasrc", parentPath, file));
    if (stat.isDirectory()) {
      traverse(path.join(parentPath, file));
    } else {
      diffy(path.join(parentPath, file));
    }
  }
  write_changes();
}

init();