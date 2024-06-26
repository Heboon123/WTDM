let {parse_json, object_to_json_string} = require("json")

let io = require("io")
let {read_text_from_file} = require("dagor.fs")

let defLogger = @(...) print(" ".join(vargv))
let callableTypes = ["function","table","instance"]
function isCallable(v) {
  return callableTypes.indexof(type(v)) != null && (v.getfuncinfos() != null)
}

function defSaveJsonFile(file_path, data){
  assert(type(data) == "string", "data should be string")
  let file = io.file(file_path, "wt+")
  file.writestring(data)
  file.close()
  return true
}

let defParamsSave = {pretty_print=true, logger=defLogger, save_text_file = defSaveJsonFile}
function save(file_path, data, params = defParamsSave) {
  let pretty_print = params?.pretty_print ?? defParamsSave.pretty_print
  let save_text_file = params?.save_text_file ?? defParamsSave.save_text_file
  let logger = params?.logger ?? defParamsSave.logger
  let logerr = params?.logerr ?? logger
  assert(isCallable(save_text_file), "save_text_file should be Callable")
  assert(type(file_path)=="string", "file_path should be string")
  assert(logger== null || isCallable(logger), @() $"logger should be Callable or null, got {type(logger)}")
  assert(["function","class","instance","generator"].indexof(type(data))==null)
  try {
    data = object_to_json_string(data, pretty_print)
    let res = save_text_file(file_path, data)
    if (res){
      logger?($"file:{file_path} saved")
      return true
    }
    else {
      logerr?($"file:{file_path} was not saved!")
      return null
    }
  }
  catch(e) {
    logerr?($"error in saving data {e}")
    return null
  }
}

function read_text_directly_from_fs_file(file_path){
  let file = io.file(file_path, "rt")
  let content = file.readblob(file.len()).as_string()
  file.close()
  return content
}

let defParamsLoad = {logger=defLogger, load_text_file = read_text_from_file}
function load(file_path, params = defParamsLoad) {
  assert(type(file_path)=="string", "file_path should be string")
  let logger = params?.logger ?? defParamsLoad.logger
  let load_text_file = params?.load_text_file ?? defParamsLoad.load_text_file
  assert(isCallable(load_text_file), "load_text_file should be Callable")
  assert(isCallable(logger) || logger==null, @() $"logger should be Callable or null, got {type(logger)}")
  try {
    let jsontext = load_text_file(file_path)
    return parse_json(jsontext)
  }
  catch(e) {
    logger?($"error in loading data {e}")
    return null
  }
}
return {
  saveJson = save
  loadJson = load
  jsonToString = object_to_json_string
  parseJson = parse_json
  read_text_directly_from_fs_file
  object_to_json_string
  parse_json
}