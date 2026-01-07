// Lua CLI - Command Line Interface for Lua 5.4 interpreter
// Supports standard Lua command-line options

///| Main entry point for Lua CLI
fn main {
  // Create command line parser
  let parser = @clap.Parser::new(
    prog="lua",
    description="Lua 5.4 interpreter in MoonBit",
    args={
      // Execute string
      "execute": @clap.Arg::named(
        short='e',
        nargs=@clap.AtMost(1),
        help="Execute string 'stat'",
      ),
      // Interactive mode
      "interactive": @clap.Arg::flag(
        short='i',
        help="Enter interactive mode after executing 'script'",
      ),
      // Load library
      "load": @clap.Arg::named(
        short='l',
        nargs=@clap.Any,
        help="Require library 'mod' into global 'mod'",
      ),
      // Version
      "version": @clap.Arg::flag(
        short='v',
        help="Show version information",
      ),
      // Ignore environment variables
      "no_env": @clap.Arg::flag(
        short='E',
        help="Ignore environment variables",
      ),
      // Warnings as errors
      "warnings_as_errors": @clap.Arg::flag(
        short='W',
        help="Turn warnings into errors",
      ),
      // Script file and arguments (positional)
      "positional": @clap.Arg::positional(
        nargs=@clap.Any,
        help="Script file and arguments",
      ),
    },
  )

  // Parse command line arguments
  let value = @clap.SimpleValue::new(parser.prog)
  try {
    parser.parse(value, @sys.get_cli_args()) |> ignore
    handle_command(value)
  } catch {
    err => {
      println("Error: \{err}")
    }
  }
}

///| Handle parsed command line arguments
fn handle_command(value : @clap.SimpleValue) -> Unit {
  // Show version
  let version_flag = value.flags.get("version").unwrap_or(false)
  if version_flag {
    println("Lua 5.4.0  Copyright (C) 1994-2020 Lua.org, PUC-Rio")
    println("MoonBit port Copyright (C) 2025")
    return
  }

  // Get options
  let execute_str : String? = try {
    value.get_option("execute")
  } catch {
    _ => None
  }
  let interactive_flag = value.flags.get("interactive").unwrap_or(false)
  let libraries : Array[String] = try {
    value.get_array("load")
  } catch {
    _ => []
  }
  let no_env_flag = value.flags.get("no_env").unwrap_or(false)
  let warnings_as_errors_flag = value.flags.get("warnings_as_errors").unwrap_or(false)

  // Get positional arguments (script and args)
  // Note: get_positional() includes the program name as the first argument
  let all_positional : Array[String] = try {
    value.get_positional()
  } catch {
    _ => []
  }

  // Skip the first argument (program name)
  let positional : Array[String] = if all_positional.length() > 1 {
    all_positional[1:].to_array()
  } else {
    []
  }

  let script_file : String? = if positional.length() > 0 {
    Some(positional[0])
  } else {
    None
  }

  let _script_args : Array[String] = if positional.length() > 1 {
    positional[1:].to_array()
  } else {
    []
  }

  // Create Lua API context
  let lua = @api.LuaAPI::new()

  // Load libraries (-l option)
  for lib in libraries {
    println("TODO: Load library '\{lib}'")
    // lua.load_string("require('\{lib}')")
    // lua.pcall(0, 0)
  }

  // Execute string (-e option)
  match execute_str {
    Some(code) => {
      try {
        lua.load_string(code) |> ignore
      } catch {
        err => {
          println("Error executing code: \{err}")
          return
        }
      }
    }
    None => ()
  }

  // Execute script file
  match script_file {
    Some(file) => {
      // Prepend script directory to package.path so require can find sibling modules
      let path = file
      let mut last_slash = -1
      for i = 0; i < path.length(); i = i + 1 {
        if path[i] == '/' {
          last_slash = i
        }
      }
      let script_dir = if last_slash >= 0 {
        let mut dir = ""
        for i = 0; i < last_slash; i = i + 1 {
          dir = dir + path[i].to_int().unsafe_to_char().to_string()
        }
        dir
      } else { "." }

      // Update package.path inside the Lua state
      let prep_path_code =
        "local dir = '" + script_dir + "'\n" +
        "package.path = dir .. '/?.lua;' .. dir .. '/?/init.lua;' .. package.path\n"
      try { lua.load_string(prep_path_code) |> ignore } catch { _ => () }

      // Read the script file using synchronous Node.js bindings (js.mbt)
      // Switch to mizchi/js Node fs for deterministic sync I/O under JS target
      let content = try {
        @fs.read_file_as_string(file)
      } catch {
        err => {
          println("Error reading file '\{file}': \{err}")
          return
        }
      }

      // Execute the script
      try {
        lua.load_string(content) |> ignore
      } catch {
        err => {
          println("Error executing script: \{err}")
          return
        }
      }
    }
    None => {
      // No script file, enter REPL if no -e option
      if execute_str is None {
        repl(no_env_flag, warnings_as_errors_flag)
      }
    }
  }

  // Enter interactive mode if -i flag is set
  if interactive_flag {
    repl(no_env_flag, warnings_as_errors_flag)
  }
}

///| Start interactive REPL
fn repl(no_env : Bool, warnings_as_errors : Bool) -> Unit {
  println("Lua 5.4.0  Copyright (C) 1994-2020 Lua.org, PUC-Rio")
  println("MoonBit port - Interactive mode")
  println("Type 'exit' or Ctrl+D to quit")
  println("Options: no_env=\{no_env}, warnings_as_errors=\{warnings_as_errors}")

  // TODO: Implement REPL loop
  // let lua = @api.LuaAPI::new()
  // loop {
  //   print("> ")
  //   match read_line() {
  //     Some(line) => {
  //       if line == "exit" {
  //         break
  //       }
  //       match lua.load_string(line) {
  //         Status::OK => {
  //           lua.pcall(0, 0)
  //           // Print result if any
  //           if lua.get_top() > 0 {
  //             let result = lua.to_string(-1)
  //             println(result)
  //           }
  //         }
  //         status => println("Error: \{status}")
  //       }
  //     }
  //     None => break
  //   }
  // }

  println("\nREPL not yet implemented - waiting for API implementation")
}
