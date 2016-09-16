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
//    debug,
//    defaultPriority,
    logger
}
import ceylon.test {
    test,
    assertEquals
}

import java.io {
    FileNotFoundException
}


String data_json = "data.json";
String content_json = "content.json";

"Command line usage error, e.g. missing argument for option."
shared class UsageError(String message) extends Exception(message) {
    "`ex_usage` i.e. command line usage error (sysexits.h)"
    shared Integer exit_code = 64;
}

"Read the file whole."
shared String read_file(File file) {
    String hub_content;
    try (reader = file.Reader()) {
        ArrayList<String> lines = ArrayList<String>();
        while (exists line = reader.readLine()) {
            lines.add(line);
        }
        hub_content = "\n".join(lines);
    }
    return hub_content;
}

"Returns null if parsed result of file is not JsonObject."
shared JsonObject? load_json_object(File file) {
    String hub_content = read_file(file);
    if (is JsonObject json = parseJson(hub_content)) {
        return json;
    } else {
        return null;
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

"Resolve a link to direcotry."
see(`function resolve_file`)
shared Directory? resolve_directory(Link link) {
    switch (resolved_link = link.linkedResource)
    case (is Directory) {
        return resolved_link;
    }
    case (is File|Nil) {
        return null;
    }
}
"Resolve a link to direcotry."
see(`function resolve_directory`)
see(`function resolve_path_to_file`)
shared File? resolve_file(Link link) {
    switch (resolved_link = link.linkedResource)
    case (is File) {
        return resolved_link;
    }
    case (is Directory|Nil) {
        return null;
    }
}
"Resolve a path to a flie."
see(`function resolve_file`)
see(`function resolve_path_to_directory`)
shared File? resolve_path_to_file(Path path) {
    switch (location = path.resource)
    case (is File) {
        return location;
    }
    case (is Link) {
        if (exists file = resolve_file(location)) {
            return file;
        } else {
            return null;
        }
    }
    case (is Directory|Nil) {
        return null;
    }
}
"Resolve a path to a direcotry."
see(`function resolve_directory`)
see(`function resolve_path_to_file`)
shared Directory? resolve_path_to_directory(Path path) {
    switch (location = path.resource)
    case (is Directory) {
        return location;
    }
    case (is Link) {
        if (exists directory = resolve_directory(location)) {
            return directory;
        } else {
            return null;
        }
    }
    case (is File|Nil) {
        return null;
    }
}


throws(`class FileNotFoundException`, "`hub_id_path` does not contains `data/users`")
Directory get_users_dir(Path hub_id_path) {
    switch (users_dir = hub_id_path.childPath("data").childPath("users").resource)
    case (is Directory) {
        return users_dir;
    }
    case (is Link) {
        if (exists resolved_link = resolve_directory(users_dir)) {
            return resolved_link;
        } else {
            throw FileNotFoundException(
                "``hub_id_path`` is a link,
                 either the link is broken, or there is no `/data/users/` under its target.
                "
            );
        }
    }
    case (is File|Nil){
        throw FileNotFoundException("``hub_id_path``/data/users/");
    }
}

"Returns {.../user_id/, ...}"
{Path*} get_user_dirs(Directory users_dir) {
    return users_dir.childPaths().filter((path) => path.resource is Directory);
}

"Returns non empty follow array."
shared JsonArray? get_follow(JsonObject user) {
    if (is JsonArray follow = user["follow"], !follow.empty) {
        return follow;
    } else {
        return null;
    }
}

class FollowingHubless(shared String name) extends Exception(name) {}

"Returns null if user is not following any one."
throws(`class FollowingHubless`, "when user follows someone without a hub")
HubLinks? process_follow(JsonObject user) {
    HubLinks hubLinks = HashSet<String>();
    if (is JsonArray follow = get_follow(user)) {
        for (following in follow) {
            if (is JsonObject following) {
                if (exists hub_id = get_json_string(following, "hub")) {
                    hubLinks.add(hub_id);
                } else {
                    String name;
                    if (exists user_name = get_json_string(following, "user_name")) {
                        name = user_name;
                    } else {
                        name = "null";
                    }
                    throw FollowingHubless(name);
                }
            } else {
                return null;
            }
        }
        return hubLinks;
    } else {
        return null;
    }
}

"Given a **hub** site path, returns all hub IDs whose users are followed by the given **hub**."
see(`alias HubLinks`)
shared HubLinks crawl_links(Path hub_id_path) {
    HubLinks links = HashSet<String>();
    for (user_dir in get_user_dirs(get_users_dir(hub_id_path))) {
        if (exists file = resolve_path_to_file(user_dir.childPath(data_json))) {
            if (is JsonObject user_data = load_json_object(file)) {
                try {
                    if (exists hubLinks = process_follow(user_data)) {
                        links.addAll(hubLinks);
                    } else {
                        log.debug(() => "``user_dir`` is not following any one.");
                    }
                } catch (FollowingHubless e) {
                    log.error(() => "``user_dir`` follows ``e.name`` without `hub`!
                                     Something is wrong with the data dir.");
                }
            } else {
                log.error(() => "Failed to parse `data.json` file in ``user_dir``.");
            }
        } else {
            // Some `user_dir` dose not have `data_json` file.
            // Probably not synced yet.
            log.warn(() => "There is no `data.json` file in ``user_dir``.");
        }
    }
    return links;
}

"Gluing code or the real entry point.
 Returns Null when `hub` is not seeded or fail to parse content.json of `hub`."
shared Hub|Hubs|Null crawl(String hub_id, Directory data_dir, Boolean recursive = false) {
    Path hub_id_path = data_dir.path.childPath(hub_id);
    Path hub_content_json_path = hub_id_path.childPath(content_json);
    if (exists content_json_file = resolve_path_to_file(hub_content_json_path)) {
        if (is JsonObject content_json = load_json_object(content_json_file)) {
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
    } else {
        log.warn("You are not seeding ``hub_id``. Skip it.");
        return null;
    }
}

Logger log = logger(`module io.github.weakish.zeronet.zerome.crawler`);

"Returns JsonObject for [[Hub]] and JsonArray of JsonObject for [[Hubs]]."
shared JsonArray|JsonObject jsonify(Hubs|Hub|HubLinks|Null hub) {
    // Nest switch in if-else
    // because `HubLinks`(interface based) and `Hubs` (class based) are not disjoint.
    if (is HubLinks hub) {
        JsonArray json = JsonArray();
        json.addAll(hub);
        return json;
    } else {
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
}

"Returns `data/REGISTRY_ID/data/userdb/`."
throws(`class FileNotFoundException`, "if directory not found")
shared Directory get_userdb_dir(Directory data_dir, String user_registry) {
    Path user_registry_path = data_dir.path.childPath(user_registry);
    Path user_db_path = user_registry_path.childPath("data").childPath("userdb");
    if (exists directory = resolve_path_to_directory(user_db_path)) {
        return directory;
    } else {
        throw FileNotFoundException("``data_dir.path.string``/``user_registry``/data/userdb/");
    }
}

"Returns
     - [[HubLinks]] when `list_only` is true;
     - {[[Hub]]*} when `list_only` is false."
shared HubLinks|Hubs crawl_all(Directory data_dir, String user_registry, Boolean list_only) {
    HubLinks hubLinks = crawl_all_hubs(data_dir, user_registry);
    switch (list_only)
    case (true) {
        return hubLinks;
    }
    case (false) {
        {Hub*} hubs = {
            for (link in hubLinks)
                if (is Hub hub = crawl(link, data_dir, false))
                    hub
        };
        return set(hubs);
    }
}

"Returns null under following conditions:
     - no `user` array,
     - `user` is empty,
     - `user` has more than one users,
     - failed to parse `user[0]` as Json Object."
String? get_hub_from_user(JsonObject user_data) {
    if (is JsonArray user = user_data["user"],
        !user.empty,
        user.size == 1, // I guess currently ZeroMe does not support multiple users account.
        is JsonObject first_user = user.first) {
        return get_json_string(first_user, "hub");
    } else {
        return null;
    }
}

"Crawl zerome user register for hubs."
shared HubLinks crawl_all_hubs(Directory data_dir, String user_registry) {
    HubLinks hubLinks = HashSet<String>();
    for (user in get_user_dirs(get_userdb_dir(data_dir, user_registry))) {
        if (exists file = resolve_path_to_file(user.childPath(content_json))) {
            if (is JsonObject user_data = load_json_object(file)) {
                if (exists hub = get_hub_from_user(user_data)) {
                    hubLinks.add(hub);
                } else {
                    log.warn("Failed to get hub from ``user``
                              This may be caused by broken manual migration.");
                }
            } else {
                log.error(() => "Failed to parse `data.json` file in ``user``.");
            }
        } else {
            log.warn(() => "There is no `content.json` file in ``user``.
                            Probably it has not been synced yet.");
        }
    }
    return hubLinks;
}

"The entrypoint for command line."
throws(`class UsageError`, "when option speciefd without an argument value`")
void main() {
    addLogWriter(writeSimpleLog);
    // DEBUG
//    defaultPriority = debug;

    Path data_dir_path;
    String hub_id;
    String user_registry;

    // -h/--help
    Boolean help_option = process.namedArgumentPresent("help");
    Boolean help_option_short = process.namedArgumentPresent("h");
    if (help_option == true || help_option_short == true) {
        print("""Usage:
                 java -jar zerome-crawler.jar -h|--help
                                              --all [--list-only] [-1 [--seeding]] [--data_dir PATH] [--user_registry ID]
                                              [-r] [--hub ID] [--data_dir PATH]""");
    } else {
        // --data_dir
        if (process.namedArgumentPresent("data_dir") == true) {
            if (exists data_dir_argument = process.namedArgumentValue("data_dir")) {
                data_dir_path = parsePath(data_dir_argument);
            } else {
                throw UsageError("`--data_dir` specified without a value.");
            }
        } else {
            data_dir_path = current;
        }
        // -r
        Boolean recursive = process.namedArgumentPresent("r");
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
        // --all
        Boolean all = process.namedArgumentPresent("all");
        // --list-only
        Boolean list_only = process.namedArgumentPresent("list-only");
        // -1
        Boolean one_pre_line = process.namedArgumentPresent("1");
        // --seeding
        Boolean seeding = process.namedArgumentPresent("seeding");
        // --user_registry
        String zerome_user_registry = "1UDbADib99KE9d3qZ87NqJF2QLTHmMkoV";
        if (process.namedArgumentPresent("user_registry") == true) {
            if (exists registry_argument = process.namedArgumentValue("user_registry")) {
                user_registry = registry_argument;
            } else {
                user_registry = zerome_user_registry;
            }
        } else {
            user_registry = zerome_user_registry;
        }
        Directory data_dir;
        if (exists directory = resolve_path_to_directory(data_dir_path)) {
            data_dir = directory;
        } else {
            throw FileNotFoundException("data_dir ``data_dir_path`` not found.");
        }
        // output
        switch (all)
        case (true) {
            switch (one_pre_line)
            case (true) {
                for (hub_link in crawl_all(data_dir, user_registry, true)) {
                    assert (is String hub_link);
                    switch(seeding)
                    case(true) {
                        Path hub_path = data_dir.path.childPath(hub_link);
                        if (exists directory = resolve_path_to_directory(hub_path)) {
                            print(hub_link);
                        }
                    }
                    case (false) {
                        print(hub_link);
                    }
                }
            }
            case (false) {
                print(jsonify(crawl_all(data_dir, user_registry, list_only)));
            }
        }
        case (false) {
            print(jsonify(crawl(hub_id, data_dir, recursive)));
        }
    }
}

"The ultimate exception handler."
suppressWarnings("expressionTypeNothing")
shared void run() {
    try {
        main();
    } catch (UsageError e) {
        process.writeErrorLine(e.message);
        process.exit(e.exit_code);
    } catch (LoadJsonFail e) {
        process.writeErrorLine(e.message);
        e.printStackTrace();
        process.exit(e.exit_code);
    }
}