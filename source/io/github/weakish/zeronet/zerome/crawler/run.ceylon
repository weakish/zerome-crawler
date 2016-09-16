import ceylon.collection {
    ArrayList,
    HashSet
}
import ceylon.file {
    Path,
    parsePath,
    current,
    File,
    Directory,
    Link,
    Nil
}
import ceylon.json {
    JsonObject=Object,
    JsonArray=Array,
    parseJson=parse
}
import ceylon.logging {
    Logger,
    addLogWriter,
    writeSimpleLog,
    // defaultPriority,
    logger
}
import ceylon.test {
    test,
    assertEquals
}

import java.io {
    FileNotFoundException
}
import java.lang {
    UnsupportedOperationException
}

"Command line usage error, e.g. missing argument for option."
shared class UsageError(String message) extends Exception(message) {
    "`ex_usage` i.e. command line usage error (sysexits.h)"
    shared Integer exit_code = 64;
}

"Read the file whole."
throws(`class FileNotFoundException`)
shared String read_file(Path path) {
    String hub_content;
    if (is File file = path.resource) {
        try (reader = file.Reader()) {
            ArrayList<String> lines = ArrayList<String>();
            while (exists line = reader.readLine()) {
                lines.add(line);
            }
            hub_content = "\n".join(lines);
        }
        return hub_content;
    } else {
        throw FileNotFoundException(path.string);
    }
}

"Returns null if parsed result of file is not JsonObject."
shared JsonObject? load_json_object(Path path) {
    String hub_content = read_file(path);
    if (is JsonObject json = parseJson(hub_content)) {
        return json;
    } else {
        return null;
    }
}

"Wraps [[load_json_object]]."
throws(`class LoadJsonFail`, "if parsed result of file is not JsonObject")
shared JsonObject load_json_object_or_throw(Path path) {
    if (exists json = load_json_object(path)) {
        return json;
    } else {
        throw LoadJsonFail(path);
    }
}
"When failed to parse a string as json object."
shared class LoadJsonFail(Path data) extends Exception(data.string) {
    "`ex_dataerr` i.e. data format error (sysexits.h)"
    shared Integer exit_code = 65;
}

"Given a json object and a key, returns object[key] iff object[key] is a string.
 Returns null when key not found or object[key] is not a string."
shared String? get_json_string(JsonObject json, String key) {
    String? string;
    if (is String target = json[key]) {
        string = target;
    } else {
        string = null;
    }
    return string;
}
test void get_version_from_redHub() {
    String red_hub_content_json =
            """
               {
                "address":"1RedkCkVaXuVXrqCMpoXQS29bwaqsuFdL",
                "background-color":"white",
                "cloneable":true,
                "description":"Welcome to ZeroMe! Runner: Nofish",
                "files":{
                    "data-default\/users\/content.json-default":{
                        "sha512":"4e37699bd5336b9c33ce86a3eb73b82e87460535793401874a653afeddefee59","size":735
                    },
                    "index.html":{
                        "sha512":"087c6ae46aacc5661f7da99ce10dacc0428dbd48aa7bbdc1df9c2da6e81b1d93",
                        "size":466
                    }
                },
                "ignore":"((js|css)\/(?!all.(js|css))|data\/.*db|data\/users\/.*\/.*)",
                "includes":{
                    "data\/users\/content.json":{
                        "signers":[],
                        "signers_required":1
                    }
                },
                "inner_path":"content.json",
                "merged_type":"ZeroMe",
                "modified":1.472166728009E9,
                "postmessage_nonce_security":true,
                "sign":[138703383221221873,-842290774616658768],
                "signers_sign":"HCRqtyEaSd7F1iWncBv+kw2894UURARTkDvDCQhpMAWLoNzc8KqeiitnzIbT08pu25JKax1t6CLq26Ka5Y4VIFA=",
                "signs":{
                    "1RedkCkVaXuVXrqCMpoXQS29bwaqsuFdL":"G4c4X9GZMV7Iecv\/3uzGnsSZy8mlUIondf\/HVZ856wHcHFdrLkj6zekizkDHbFIzuEB4C1J4J2ShQCXYFyU9l40="
                },
                "signs_required":1,
                "title":"RedHub",
                "zeronet_version":"0.4.0"
               }
            """;
    assert (is JsonObject json = parseJson(red_hub_content_json));
    assertEquals(get_json_string(json, "zeronet_version"), "0.4.0");
}

"Parse content.json of a hub for meta data."
see(`alias HubMeta`)
shared HubMeta meta(JsonObject content_json) {
    String? title = get_json_string(content_json, "title");
    String? description = get_json_string(content_json, "description");
    String? zeronet_version = get_json_string(content_json, "zeronet_version");
    return map {
            "title"->title,
            "description"->description,
            "zeronet_version"->zeronet_version
    };
}

"A set of hub IDs."
shared alias HubLinks => HashSet<String>;
"title, description, zeronet_version"
shared alias HubMeta => Map<String, String?>;
"hub_id -> [HubMeta, HubLinks]"
shared alias Hub => Entry<String, [HubMeta, HubLinks]>;
"A set of [[Hub]]s."
shared alias Hubs => Set<Hub>;

"exit_codo 70 a.k.a internal software error (sysexits.h)"
shared class NotImplementedYet(String message) extends UnsupportedOperationException(message) {
    "`ex_software` i.e. internal software error (sysexits.h)"
    shared Integer exit_code = 70;
}

throws(`class FileNotFoundException`, "`hub_id_path` does not contains `data/users`")
Directory get_users_dir(Path hub_id_path) {
    switch (users_dir = hub_id_path.childPath("data").childPath("users").resource)
    case (is Directory) {
        return users_dir;
    }
    case (is File|Link|Nil){
        throw FileNotFoundException("``hub_id_path``/data/users");
    }
}

"Returns {hub_id/data/users/user_id ...}"
{Path*} get_user_dirs(Directory users_dir) {
    return users_dir.childPaths().filter((path) => path.resource is Directory);
}
"Given a **hub** site path, returns all hub IDs whose users are followed by the given **hub**."
see(`alias HubLinks`)
shared HubLinks crawl_links(Path hub_id_path) {
    HubLinks links = HashSet<String>();
    for (user_dir in get_user_dirs(get_users_dir(hub_id_path))) {
        try {
            if (is JsonObject user_data = load_json_object(user_dir.childPath("data.json"))) {
                if (is JsonArray follow = user_data["follow"], !follow.empty) {
                    for (following in follow) {
                        if (is JsonObject following) {
                            if (exists hub_id = get_json_string(following, "hub")) {
                                links.add(hub_id);
                            } else {
                                String name;
                                if (exists user_name = get_json_string(following, "user_name")) {
                                    name = user_name;
                                } else {
                                    name = "null";
                                }
                                log.error(() => "``user_dir`` followed ``name`` without hub!
                                                 Something is wrong with the data dir.");
                            }
                        } else {
                            log.info(() => "``user_dir`` is not following any one.");
                        }
                    }
                } else {
                    log.info(() => "``user_dir`` is not following any one.");
                }
            } else {
                log.error(() => "Failed to parse `data.json` file in ``user_dir``.");
                log.warn(() => "There is no `data.json` file in ``user_dir``.");
            }
        } catch(FileNotFoundException e) {
            // Some `user_dir` dose not have `data_json` file.
            // Probably not synced yet.
            log.warn(() => "There is no `data.json` file in ``user_dir``.");
        }
    }
    return links;
}

"Gluing code or the real entry point.
 Returns Null when `hub` is not seeded or fail to parse content.json of `hub`."
shared Hub|Hubs|Null crawl(String hub_id, Path data_dir, Boolean recursive) {
    Path hub_id_path = data_dir.childPath(hub_id);
    Path hub_content_json = hub_id_path.childPath("content.json");
    try {
        if (is JsonObject content_json = load_json_object(hub_content_json)) {
            HubMeta hubMeta = meta(content_json);
            HubLinks hubLinks = crawl_links(hub_id_path);
            if (recursive) {
                return set {
                        for (link in hubLinks)
                        if (is Hub hub = crawl(link, data_dir, false))
                        hub };
            } else {
                return hub_id->[hubMeta, hubLinks];
            }
        } else {
            log.error("Failed to parse `content.json` of ``hub_id``");
            return null;
        }
    } catch (FileNotFoundException e) {
        log.warn("You are not seeding ``hub_id``. Skip it.");
        return null;
    }
}

Logger log = logger(`module io.github.weakish.zeronet.zerome.crawler`);

"Returns JsonObject for [[Hub]] and JsonArray of JsonObject for [[Hubs]]."
shared JsonArray|JsonObject jsonify(Hubs|Hub|Null hub) {
    switch (hub)
    case (is Hub) {
        return JsonObject {
                "address" -> hub.key,
                "title" -> hub.item[0]["title"],
                "description" -> hub.item[0]["description"],
                "zeronet_version" -> hub.item[0]["zeronet_version"],
                "links" -> JsonArray(hub.item[1])
        };
    }
    case (is Hubs) {
        return JsonArray([for (_hub in hub) jsonify(_hub)]);
    }
    case (is Null) {
        return JsonObject {};
    }
}

"The entrypoint for command line."
throws(`class UsageError`, "when option speciefd without an argument value`")
void main() {
    addLogWriter(writeSimpleLog);
    // DEBUG
    // defaultPriority = debug;

    Path data_dir;
    String hub_id;

    if (process.namedArgumentPresent("h") == true) {
        print("""Usage: java -jar zerome-crawler.jar [-h] [-r] [--data_dir PATH] [--hub ID]""");
    } else {
        // --data_dir
        if (process.namedArgumentPresent("data_dir") == true) {
            if (exists data_dir_argument = process.namedArgumentValue("data_dir")) {
                data_dir = parsePath(data_dir_argument);
            } else {
                throw UsageError("`--data_dir` specified without a value.");
            }
        } else {
            data_dir = current;
        }
        // --hub
        if (process.namedArgumentPresent("hub") == true) {
            if (exists hub_argument = process.namedArgumentValue("hub")) {
                hub_id = hub_argument;
            } else {
                throw UsageError("`--hub` specified without a value.");
            }
        } else {
            String redhub = "1RedkCkVaXuVXrqCMpoXQS29bwaqsuFdL";
            hub_id = redhub;
        }
        // -r
        Boolean recursive = process.namedArgumentPresent("r");

        // output in json
        print(jsonify(crawl(hub_id, data_dir, recursive)));
    }
}

"The utimate exception handler."
shared void run() {
    try {
        main();
    } catch (UsageError|NotImplementedYet e) {
        process.writeErrorLine(e.message);
        switch (e)
        case (is UsageError) {
            process.exit(e.exit_code);
        }
        case (is NotImplementedYet) {
            process.exit(e.exit_code);
        }
    } catch (LoadJsonFail e) {
        process.writeErrorLine(e.message);
        e.printStackTrace();
        process.exit(e.exit_code);
    }
}