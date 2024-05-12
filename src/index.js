const { program } = require("commander");
const serve = require("./serve");

program.name("luaserve")
  .description("serve computercraft lua")
  .version("0.1.0");

program.command("serve")
  .option("--no-watch", "Don't watch files")
  .action(serve);

program.parse();